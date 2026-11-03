@tool
## 3x3 Chalkboard Game UIFlowPage featuring the hand-drawn grid (`board.png`), animated X/O chalk placement with dust bursts, winning line chalk strike, and Result Overlay modal (`win_frame.png` + `trophy_laurel.png`).
class_name GameView
extends UIFlowPage

const TEX_MARK_X := "res://app/resources/textures/mark_x_yellow.png"
const TEX_MARK_O := "res://app/resources/textures/mark_o.png"

const AI_THINK_DELAY := 0.32
const RESULT_OVERLAY_DELAY := 0.45

@onready var _btn_menu: ChalkButton = $SafeMargin/MainColumn/TopBar/BtnMenu
@onready var _btn_reset: ChalkButton = $SafeMargin/MainColumn/TopBar/BtnReset
@onready var _p1_title_label: Label = $SafeMargin/MainColumn/ScoreRow/P1Col/P1TitleLabel
@onready var _p1_score_label: Label = $SafeMargin/MainColumn/ScoreRow/P1Col/P1ScoreLabel
@onready var _draws_title_label: Label = $SafeMargin/MainColumn/ScoreRow/DrawsCol/DrawsTitleLabel
@onready var _draws_score_label: Label = $SafeMargin/MainColumn/ScoreRow/DrawsCol/DrawsScoreLabel
@onready var _p2_title_label: Label = $SafeMargin/MainColumn/ScoreRow/P2Col/P2TitleLabel
@onready var _p2_score_label: Label = $SafeMargin/MainColumn/ScoreRow/P2Col/P2ScoreLabel
@onready var _turn_banner: ChalkBanner = $SafeMargin/MainColumn/TurnBanner
@onready var _board_area: Control = $SafeMargin/MainColumn/BoardCenter/BoardArea
@onready var _winning_line_layer: Control = $SafeMargin/MainColumn/BoardCenter/BoardArea/WinningLineLayer
@onready var _hint_label: Label = $SafeMargin/MainColumn/HintLabel

@onready var _result_overlay: Control = $ResultOverlay
@onready var _result_title_label: Label = $ResultOverlay/Center/Card/CardMargin/CardVBox/ResultTitleLabel
@onready var _result_points_label: Label = $ResultOverlay/Center/Card/CardMargin/CardVBox/ResultPointsLabel
@onready var _btn_play_again: ChalkButton = $ResultOverlay/Center/Card/CardMargin/CardVBox/BtnPlayAgain
@onready var _btn_result_menu: ChalkButton = $ResultOverlay/Center/Card/CardMargin/CardVBox/BtnResultMenu

var _view_model: GameViewModel
var _cell_buttons: Array[Control] = []
var _cell_mark_rects: Array[TextureRect] = []
var _win_line_progress: float = 0.0
var _active_winning_line: Array = []
var _ai_timer_pending: bool = false

## Flag to enable or disable tween animations and AI think delays (set to false in synchronous unit tests).
var animations_enabled: bool = true


func _ready() -> void:
	_init_nodes()
	if _view_model != null:
		_view_model.start_new_round(false)
		refresh_ui()
		_check_schedule_ai_turn()


## Binds the GameViewModel to this view, connects signals, and initializes the board round.
func setup(view_model: GameViewModel) -> void:
	_view_model = view_model
	if not _view_model.state_changed.is_connected(_on_vm_state_changed):
		_view_model.state_changed.connect(_on_vm_state_changed)
	if not _view_model.cell_marked.is_connected(_on_vm_cell_marked):
		_view_model.cell_marked.connect(_on_vm_cell_marked)
	if not _view_model.board_wiped.is_connected(_on_vm_board_wiped):
		_view_model.board_wiped.connect(_on_vm_board_wiped)
	if not _view_model.match_finished.is_connected(_on_vm_match_finished):
		_view_model.match_finished.connect(_on_vm_match_finished)

	if is_node_ready():
		var audio := _view_model.get_audio_service()
		for btn in [_btn_menu, _btn_reset, _btn_play_again, _btn_result_menu]:
			if btn != null:
				btn.set_audio_service(audio)
		_view_model.start_new_round(false)
		refresh_ui()
		_check_schedule_ai_turn()


## UIFlowPage lifecycle hook called when the page becomes visible again.
func _on_shown() -> void:
	on_view_will_appear()


## Refreshes localized labels when the Game screen appears.
func on_view_will_appear() -> void:
	refresh_ui()


## Updates the turn banner, scoreboard counters, and hint label from the ViewModel.
func refresh_ui() -> void:
	if not is_node_ready() or _btn_menu == null:
		return

	_btn_menu.refresh_content()
	_btn_reset.refresh_content()
	_btn_play_again.refresh_content()
	_btn_result_menu.refresh_content()
	_hint_label.text = tr("GAME_TAP_HINT_CHALK")

	if _view_model == null:
		_turn_banner.set_banner_text("GAME_YOUR_TURN", ChalkTheme.CHALK_YELLOW, false)
		_p1_title_label.text = tr("GAME_PLAYER_X")
		_p2_title_label.text = tr("GAME_PLAYER_O")
		_draws_title_label.text = tr("GAME_DRAWS")
		return

	var cfg := _view_model.get_config()
	if cfg.is_two_player:
		_p1_title_label.text = tr("GAME_PLAYER_X")
		_p2_title_label.text = tr("GAME_PLAYER_O")
	else:
		var human_m := "X" if cfg.human_mark == Domain.Mark.X else "O"
		var ai_m := "O" if cfg.human_mark == Domain.Mark.X else "X"
		_p1_title_label.text = tr("GAME_YOU_X").replace("{m}", human_m)
		_p2_title_label.text = tr("GAME_AI_O").replace("{m}", ai_m)

	_draws_title_label.text = tr("GAME_DRAWS")
	_p1_score_label.text = str(_view_model.player_1_wins)
	_draws_score_label.text = str(_view_model.draws)
	_p2_score_label.text = str(_view_model.player_2_wins)

	var banner_color := ChalkTheme.CHALK_YELLOW
	if _view_model.is_ai_thinking():
		banner_color = ChalkTheme.CHALK_WHITE
	elif _view_model.is_game_over():
		banner_color = ChalkTheme.CHALK_GREEN
	_turn_banner.set_banner_text(_view_model.get_turn_banner_text(), banner_color, false)


## Programmatically taps a board cell (`0..8`) for gameplay and unit tests.
func tap_cell(cell_index: int) -> bool:
	if _view_model == null:
		return false
	var moved := _view_model.on_cell_tapped(cell_index)
	if moved:
		_check_schedule_ai_turn()
	return moved


## Returns true if the Result Overlay modal is currently visible.
func is_result_overlay_visible() -> bool:
	return _result_overlay.visible if _result_overlay != null else false


## Returns the Play Again ChalkButton inside the Result Overlay for testing.
func get_play_again_button() -> ChalkButton:
	return _btn_play_again


## Returns the Menu ChalkButton in the top header for testing.
func get_menu_button() -> ChalkButton:
	return _btn_menu


## Returns the Reset ChalkButton in the top header for testing.
func get_reset_button() -> ChalkButton:
	return _btn_reset


## Callback invoked when the ViewModel emits `state_changed`.
func _on_vm_state_changed() -> void:
	refresh_ui()


## Callback invoked when a mark (`X` or `O`) is placed at `cell_index`, triggering the chalk draw animation and dust burst.
func _on_vm_cell_marked(cell_index: int, mark: Domain.Mark) -> void:
	if cell_index < 0 or cell_index >= _cell_mark_rects.size():
		return
	var mark_rect := _cell_mark_rects[cell_index]
	mark_rect.texture = load(TEX_MARK_X if mark == Domain.Mark.X else TEX_MARK_O) as Texture2D
	mark_rect.visible = true
	mark_rect.pivot_offset = mark_rect.size * 0.5

	if is_inside_tree() and animations_enabled and not Engine.is_editor_hint():
		mark_rect.scale = Vector2(0.25, 0.25)
		mark_rect.modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(mark_rect, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(mark_rect, "modulate:a", 1.0, 0.14)
		_spawn_chalk_dust_burst(_cell_buttons[cell_index].position + _cell_buttons[cell_index].size * 0.5, mark)
	else:
		mark_rect.scale = Vector2.ONE
		mark_rect.modulate.a = 1.0


## Callback invoked when the board is wiped clean for a new round.
func _on_vm_board_wiped() -> void:
	for rect in _cell_mark_rects:
		if rect != null:
			rect.visible = false
			rect.texture = null
	_active_winning_line = []
	_win_line_progress = 0.0
	if _winning_line_layer != null:
		_winning_line_layer.queue_redraw()
	if _result_overlay != null:
		_result_overlay.visible = false


## Callback invoked when a match ends, animating the winning chalk strike line and showing the Result Overlay.
func _on_vm_match_finished(outcome: Domain.Outcome, winning_line: Array, _points: int) -> void:
	_active_winning_line = winning_line
	if _result_title_label != null:
		_result_title_label.text = _view_model.get_result_title_text()
		var title_color := ChalkTheme.CHALK_YELLOW
		if outcome == Domain.Outcome.WIN:
			title_color = ChalkTheme.CHALK_GREEN
		elif outcome == Domain.Outcome.LOSS and not _view_model.get_config().is_two_player:
			title_color = ChalkTheme.CHALK_RED
		_result_title_label.label_settings = ChalkTheme.make_label_settings(44, title_color, true)

	if _result_points_label != null:
		var pts_text := _view_model.get_result_points_text()
		_result_points_label.text = pts_text
		_result_points_label.visible = not pts_text.is_empty()

	if animations_enabled and not _active_winning_line.is_empty() and is_inside_tree() and not Engine.is_editor_hint():
		_win_line_progress = 0.0
		var tween := create_tween()
		tween.tween_method(
			func(p: float) -> void:
				_win_line_progress = p
				if _winning_line_layer != null:
					_winning_line_layer.queue_redraw(),
			0.0,
			1.0,
			0.26
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_interval(RESULT_OVERLAY_DELAY)
		tween.tween_callback(_show_result_overlay)
	else:
		_win_line_progress = 1.0
		if _winning_line_layer != null:
			_winning_line_layer.queue_redraw()
		_show_result_overlay()


## Displays the Result Overlay modal with a pop-in animation.
func _show_result_overlay() -> void:
	if _result_overlay == null:
		return
	_result_overlay.visible = true
	if animations_enabled and is_inside_tree() and not Engine.is_editor_hint():
		_result_overlay.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_result_overlay, "modulate:a", 1.0, 0.18)
	else:
		_result_overlay.modulate.a = 1.0


## Schedules or executes the AI turn if the ViewModel is waiting on the AI.
func _check_schedule_ai_turn() -> void:
	if _view_model == null or not _view_model.is_ai_thinking() or _ai_timer_pending:
		return
	if animations_enabled and is_inside_tree() and not Engine.is_editor_hint():
		_ai_timer_pending = true
		var timer := get_tree().create_timer(AI_THINK_DELAY)
		timer.timeout.connect(func() -> void:
			_ai_timer_pending = false
			if is_instance_valid(self) and _view_model != null and _view_model.is_ai_thinking():
				_view_model.execute_ai_turn()
		)
	else:
		_view_model.execute_ai_turn()


## Spawns a one-shot burst of chalk dust particles at `local_pos` on the board when a mark is drawn.
func _spawn_chalk_dust_burst(local_pos: Vector2, mark: Domain.Mark) -> void:
	if _board_area == null or not is_inside_tree():
		return
	var burst := CPUParticles2D.new()
	burst.position = local_pos
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 14
	burst.lifetime = 0.45
	burst.explosiveness = 0.92
	burst.texture = load(ChalkTheme.TEX_DUST_PARTICLE) as Texture2D
	burst.direction = Vector2(0.0, -1.0)
	burst.spread = 180.0
	burst.gravity = Vector2(0.0, 120.0)
	burst.initial_velocity_min = 40.0
	burst.initial_velocity_max = 110.0
	burst.scale_amount_min = 0.18
	burst.scale_amount_max = 0.45
	burst.color = ChalkTheme.CHALK_YELLOW if mark == Domain.Mark.X else ChalkTheme.CHALK_WHITE
	_board_area.add_child(burst)
	burst.emitting = true
	var cleanup_timer := get_tree().create_timer(0.6)
	cleanup_timer.timeout.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


## Custom draw callback for `_winning_line_layer` that renders the hand-drawn chalk strike across the 3 winning cells.
func _on_draw_winning_line() -> void:
	if _winning_line_layer == null or _active_winning_line.size() < 3 or _win_line_progress <= 0.0:
		return
	var first_idx: int = _active_winning_line[0]
	var last_idx: int = _active_winning_line[2]
	if first_idx < 0 or last_idx >= _cell_buttons.size():
		return

	var start_cell := _cell_buttons[first_idx]
	var end_cell := _cell_buttons[last_idx]
	var p_start := start_cell.position + start_cell.size * 0.5
	var p_end := end_cell.position + end_cell.size * 0.5
	var dir := (p_end - p_start).normalized()
	p_start -= dir * 24.0
	p_end += dir * 24.0

	var current_end := p_start.lerp(p_end, _win_line_progress)
	_winning_line_layer.draw_line(p_start + Vector2(2.0, 4.0), current_end + Vector2(2.0, 4.0), ChalkTheme.CHALK_SHADOW, 14.0, true)
	_winning_line_layer.draw_line(p_start, current_end, ChalkTheme.CHALK_YELLOW, 11.0, true)


func _init_nodes() -> void:
	_btn_menu.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_back_to_menu_pressed()
	)
	_btn_reset.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.start_new_round(true)
			_check_schedule_ai_turn()
	)
	_btn_play_again.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.start_new_round(true)
			_check_schedule_ai_turn()
	)
	_btn_result_menu.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_back_to_menu_pressed()
	)

	if not _winning_line_layer.draw.is_connected(_on_draw_winning_line):
		_winning_line_layer.draw.connect(_on_draw_winning_line)

	_cell_buttons.clear()
	_cell_mark_rects.clear()
	for i in range(9):
		var cell: Control = _board_area.get_node("Cell_%d" % i) as Control
		var mark_rect: TextureRect = cell.get_node("Mark_%d" % i) as TextureRect
		_cell_buttons.append(cell)
		_cell_mark_rects.append(mark_rect)
		var captured_idx: int = i
		if not cell.gui_input.is_connected(_on_cell_gui_input.bind(captured_idx)):
			cell.gui_input.connect(_on_cell_gui_input.bind(captured_idx))


func _on_cell_gui_input(event: InputEvent, cell_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tap_cell(cell_index)
