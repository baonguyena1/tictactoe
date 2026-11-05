@tool
## 3x3 Chalkboard Game UIFlowPage featuring the hand-drawn grid (`board.png`), animated X/O chalk placement with dust bursts, winning line chalk strike, and Result Overlay modal (`win_frame.png` + `trophy_laurel.png`).
class_name GameView
extends UIFlowPage

const TEX_MARK_X := "res://resources/textures/mark_x.png"
const TEX_MARK_O := "res://resources/textures/mark_o.png"
const SHADER_STROKE_REVEAL := preload("res://scenes/shared/stroke_reveal.gdshader")

const AI_THINK_DELAY := 0.48
const RESULT_OVERLAY_DELAY := 0.45

@onready var _btn_menu: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/TopBar/BtnMenu
@onready var _btn_reset: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/TopBar/BtnReset
@onready var _p1_title_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P1Col/P1TitleLabel
@onready var _p1_score_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P1Col/P1ScoreLabel
@onready var _draws_title_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/DrawsCol/DrawsTitleLabel
@onready var _draws_score_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/DrawsCol/DrawsScoreLabel
@onready var _p2_title_label: Label = (
	get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P2Col/P2Header/P2TitleLabel") as Label
	if has_node("GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P2Col/P2Header/P2TitleLabel")
	else get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P2Col/P2TitleLabel") as Label
)
@onready var _p2_score_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P2Col/P2ScoreLabel
@onready var _turn_banner: ChalkBanner = $GodotxSafeArea/ContentMargin/MainColumn/TurnBanner
@onready var _board_area: Control = $GodotxSafeArea/ContentMargin/MainColumn/BoardCenter/BoardArea
@onready var _winning_line_layer: Control = $GodotxSafeArea/ContentMargin/MainColumn/BoardCenter/BoardArea/WinningLineLayer
@onready var _shadow_strike_line: Line2D = get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/BoardCenter/BoardArea/WinningLineLayer/ShadowStrikeLine") as Line2D
@onready var _chalk_strike_line: Line2D = get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/BoardCenter/BoardArea/WinningLineLayer/ChalkStrikeLine") as Line2D
@onready var _ai_avatar_rect: TextureRect = (
	get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P2Col/P2Header/AiAvatarRect") as TextureRect
	if has_node("GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P2Col/P2Header/AiAvatarRect")
	else get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/ScoreRow/P2Col/AiAvatarRect") as TextureRect
)
@onready var _streak_badge: HBoxContainer = get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/StreakBadge") as HBoxContainer
@onready var _streak_label: Label = get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/StreakBadge/StreakLabel") as Label

@onready var _result_overlay: Control = $ResultOverlay
@onready var _result_card: Control = $ResultOverlay/Center/Card
@onready var _result_title_label: Label = $ResultOverlay/Center/Card/CardMargin/CardVBox/ResultTitleLabel
@onready var _result_points_label: Label = $ResultOverlay/Center/Card/CardMargin/CardVBox/ResultPointsLabel
@onready var _btn_play_again: ChalkButton = (
	get_node_or_null("ResultOverlay/Center/Card/CardMargin/CardVBox/ButtonsRow/BtnPlayAgain") as ChalkButton
	if has_node("ResultOverlay/Center/Card/CardMargin/CardVBox/ButtonsRow/BtnPlayAgain")
	else get_node_or_null("ResultOverlay/Center/Card/CardMargin/CardVBox/BtnPlayAgain") as ChalkButton
)
@onready var _btn_result_menu: ChalkButton = (
	get_node_or_null("ResultOverlay/Center/Card/CardMargin/CardVBox/ButtonsRow/BtnResultMenu") as ChalkButton
	if has_node("ResultOverlay/Center/Card/CardMargin/CardVBox/ButtonsRow/BtnResultMenu")
	else get_node_or_null("ResultOverlay/Center/Card/CardMargin/CardVBox/BtnResultMenu") as ChalkButton
)

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

	_p1_title_label.label_settings = ChalkTheme.make_label_settings(28, ChalkTheme.CHALK_WHITE, true)
	_p1_score_label.label_settings = ChalkTheme.make_label_settings(44, ChalkTheme.CHALK_RED, true)
	_draws_title_label.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_DIM, true)
	_draws_score_label.label_settings = ChalkTheme.make_label_settings(40, ChalkTheme.CHALK_DIM, true)
	_p2_title_label.label_settings = ChalkTheme.make_label_settings(28, ChalkTheme.CHALK_WHITE, true)
	_p2_score_label.label_settings = ChalkTheme.make_label_settings(44, ChalkTheme.CHALK_BLUE, true)

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

	if _ai_avatar_rect != null:
		_ai_avatar_rect.visible = not _view_model.get_config().is_two_player
	_update_streak_badge()

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


## Callback invoked when a mark (`X` or `O`) is placed at `cell_index`, triggering the hand-drawn stroke reveal animation and dust burst.
func _on_vm_cell_marked(cell_index: int, mark: Domain.Mark) -> void:
	if cell_index < 0 or cell_index >= _cell_mark_rects.size():
		return
	var mark_rect := _cell_mark_rects[cell_index]
	mark_rect.texture = load(TEX_MARK_X if mark == Domain.Mark.X else TEX_MARK_O) as Texture2D
	mark_rect.visible = true
	mark_rect.pivot_offset = mark_rect.size * 0.5
	mark_rect.scale = Vector2.ONE
	mark_rect.modulate = Color.WHITE

	var stroke_mat := ShaderMaterial.new()
	stroke_mat.shader = SHADER_STROKE_REVEAL
	stroke_mat.set_shader_parameter("mark_type", 1 if mark == Domain.Mark.X else 0)
	var mark_color: Color = ChalkTheme.CHALK_RED if mark == Domain.Mark.X else ChalkTheme.CHALK_BLUE
	stroke_mat.set_shader_parameter("mark_color", mark_color)
	stroke_mat.set_shader_parameter("feather", 0.05)
	mark_rect.material = stroke_mat

	if is_inside_tree() and animations_enabled and not Engine.is_editor_hint():
		stroke_mat.set_shader_parameter("progress", 0.0)
		var duration: float = 0.28 if mark == Domain.Mark.X else 0.26
		var tween := create_tween()
		tween.tween_method(
			func(val: float) -> void:
				if is_instance_valid(stroke_mat):
					stroke_mat.set_shader_parameter("progress", val),
			0.0,
			1.0,
			duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		_spawn_chalk_dust_burst(_cell_buttons[cell_index].position + _cell_buttons[cell_index].size * 0.5, mark)
		_shake_board()
		_check_ai_threat_reaction(mark)
	else:
		stroke_mat.set_shader_parameter("progress", 1.0)
		_check_ai_threat_reaction(mark)


## Callback invoked when the board is wiped clean for a new round.
func _on_vm_board_wiped() -> void:
	for rect in _cell_mark_rects:
		if rect != null:
			rect.visible = false
			rect.texture = null
			rect.material = null
	_active_winning_line = []
	_win_line_progress = 0.0
	_update_winning_strike_line(0.0)
	_update_streak_badge()
	_set_ai_emote(ChalkTheme.TEX_AI_NORMAL, false)
	if _winning_line_layer != null:
		_winning_line_layer.queue_redraw()
	if _result_overlay != null:
		_result_overlay.visible = false


## Returns interpolated strike position along the winning 3-in-a-row path.
func _get_strike_pos_at(p: float) -> Vector2:
	if _active_winning_line.size() < 3 or _cell_buttons.is_empty():
		return Vector2.ZERO
	var first_idx: int = _active_winning_line[0]
	var last_idx: int = _active_winning_line[2]
	if first_idx < 0 or last_idx >= _cell_buttons.size():
		return Vector2.ZERO
	var p_start := _cell_buttons[first_idx].position + _cell_buttons[first_idx].size * 0.5
	var p_end := _cell_buttons[last_idx].position + _cell_buttons[last_idx].size * 0.5
	return p_start.lerp(p_end, p)


## Updates the textured Line2D chalk stroke matching Mark X's exact color and rough chalk brush stroke.
func _update_winning_strike_line(p: float) -> void:
	if _active_winning_line.size() < 3 or p <= 0.0:
		if _chalk_strike_line != null:
			_chalk_strike_line.points = PackedVector2Array()
		if _shadow_strike_line != null:
			_shadow_strike_line.points = PackedVector2Array()
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
	p_start -= dir * 30.0
	p_end += dir * 30.0

	var winner_mark: Domain.Mark = _view_model.get_winner_mark() if _view_model != null else Domain.Mark.NONE
	var line_color := ChalkTheme.CHALK_YELLOW
	if winner_mark == Domain.Mark.X:
		line_color = ChalkTheme.CHALK_RED
	elif winner_mark == Domain.Mark.O:
		line_color = ChalkTheme.CHALK_BLUE

	var current_end := p_start.lerp(p_end, p)

	if _shadow_strike_line != null:
		_shadow_strike_line.points = PackedVector2Array([p_start + Vector2(2.0, 3.0), current_end + Vector2(2.0, 3.0)])
	if _chalk_strike_line != null:
		_chalk_strike_line.default_color = line_color
		_chalk_strike_line.points = PackedVector2Array([p_start, current_end])


## Callback invoked when a match ends, allowing the final mark to land, drawing winning chalk line, and smoothly presenting the Result Overlay.
func _on_vm_match_finished(outcome: Domain.Outcome, winning_line: Array, _points: int) -> void:
	_active_winning_line = winning_line
	if _result_title_label != null:
		_result_title_label.text = _view_model.get_result_title_text()
		var title_color := ChalkTheme.CHALK_YELLOW
		if outcome == Domain.Outcome.WIN:
			title_color = ChalkTheme.CHALK_GREEN
		elif outcome == Domain.Outcome.LOSS and not _view_model.get_config().is_two_player:
			title_color = ChalkTheme.CHALK_RED
		_result_title_label.label_settings = ChalkTheme.make_label_settings(54, title_color, true)

	if _result_points_label != null:
		var pts_text := _view_model.get_result_points_text()
		_result_points_label.text = pts_text
		_result_points_label.label_settings = ChalkTheme.make_label_settings(32, ChalkTheme.CHALK_DIM, true)
		_result_points_label.visible = not pts_text.is_empty()

	if not _view_model.get_config().is_two_player:
		if outcome == Domain.Outcome.WIN:
			_set_ai_emote(ChalkTheme.TEX_AI_DIZZY, true)
		elif outcome == Domain.Outcome.LOSS:
			_set_ai_emote(ChalkTheme.TEX_AI_WIN, true)
		else:
			_set_ai_emote(ChalkTheme.TEX_AI_SWEAT, false)
	_update_streak_badge()

	if animations_enabled and is_inside_tree() and not Engine.is_editor_hint():
		var tween := create_tween()
		# Step 1: Delay so the final mark finishes its placement bounce & dust
		tween.tween_interval(0.35)

		# Step 2: Draw winning chalk strike line if there is a winner
		if not _active_winning_line.is_empty():
			_win_line_progress = 0.0
			var winner_mark: Domain.Mark = _view_model.get_winner_mark() if _view_model != null else Domain.Mark.NONE
			var last_burst_step: int = -1
			tween.tween_method(
				func(p: float) -> void:
					_win_line_progress = p
					_update_winning_strike_line(p)
					if _winning_line_layer != null:
						_winning_line_layer.queue_redraw()
					var step := int(p * 3.5)
					if step != last_burst_step and step > 0:
						last_burst_step = step
						var strike_pos := _get_strike_pos_at(p)
						_spawn_chalk_dust_burst(strike_pos, winner_mark),
				0.0,
				1.0,
				0.38
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			# Step 3: Pause so the player can appreciate the winning strike
			tween.tween_interval(0.55)
		else:
			# Draw match pause
			tween.tween_interval(0.50)

		# Step 4: Smooth result card entrance animation
		tween.tween_callback(_show_result_overlay)
	else:
		_win_line_progress = 1.0
		_update_winning_strike_line(1.0)
		if _winning_line_layer != null:
			_winning_line_layer.queue_redraw()
		_show_result_overlay()


## Displays the Result Overlay modal with a soft translucent fade and elastic pop-in card animation.
func _show_result_overlay() -> void:
	if _result_overlay == null:
		return
	_result_overlay.visible = true
	if animations_enabled and is_inside_tree() and not Engine.is_editor_hint():
		_result_overlay.modulate.a = 0.0
		if _result_card != null:
			_result_card.pivot_offset = _result_card.size * 0.5
			_result_card.scale = Vector2(0.80, 0.80)
			_result_card.modulate.a = 0.0

		var tween := create_tween()
		# Smooth fade in for the overlay dimmer
		tween.tween_property(_result_overlay, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if _result_card != null:
			var card_tween := create_tween().set_parallel(true)
			card_tween.tween_property(_result_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			card_tween.tween_property(_result_card, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_result_overlay.modulate.a = 1.0
		if _result_card != null:
			_result_card.scale = Vector2.ONE
			_result_card.modulate.a = 1.0


## Smoothly fades out the Result Overlay modal ("fade out effect").
func _hide_result_overlay(on_complete: Callable = Callable()) -> void:
	if _result_overlay == null or not _result_overlay.visible:
		if on_complete.is_valid():
			on_complete.call()
		return
	if animations_enabled and is_inside_tree() and not Engine.is_editor_hint():
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_result_overlay, "modulate:a", 0.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if _result_card != null:
			tween.tween_property(_result_card, "scale", Vector2(0.85, 0.85), 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(func() -> void:
			if is_instance_valid(self) and _result_overlay != null:
				_result_overlay.visible = false
				_result_overlay.modulate.a = 1.0
				if _result_card != null:
					_result_card.scale = Vector2.ONE
			if on_complete.is_valid():
				on_complete.call()
		)
	else:
		_result_overlay.visible = false
		if on_complete.is_valid():
			on_complete.call()


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
	var p_color: Color = ChalkTheme.CHALK_RED if mark == Domain.Mark.X else ChalkTheme.CHALK_BLUE
	p_color.a = 0.6
	burst.color = p_color
	_board_area.add_child(burst)
	burst.emitting = true
	var cleanup_timer := get_tree().create_timer(0.6)
	cleanup_timer.timeout.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)


## Sets the AI reaction face emote texture and plays a subtle emote pop.
func _set_ai_emote(texture_path: String, wiggle: bool = false) -> void:
	if _ai_avatar_rect == null or not _ai_avatar_rect.visible:
		return
	var tex := load(texture_path) as Texture2D
	if tex != null:
		_ai_avatar_rect.texture = tex
	if wiggle and animations_enabled and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_ai_avatar_rect, "scale", Vector2(1.18, 1.18), 0.08)
		tween.tween_property(_ai_avatar_rect, "rotation_degrees", -8.0, 0.05)
		tween.tween_property(_ai_avatar_rect, "rotation_degrees", 8.0, 0.05)
		tween.tween_property(_ai_avatar_rect, "rotation_degrees", 0.0, 0.05)
		tween.tween_property(_ai_avatar_rect, "scale", Vector2.ONE, 0.08)


## Shakes the board area slightly upon mark placement for a tactile, punchy game feel.
func _shake_board() -> void:
	if _board_area == null or not is_inside_tree() or not animations_enabled:
		return
	var orig_pos := _board_area.position
	var tween := create_tween()
	for i in range(3):
		var offset := Vector2(randf_range(-3.5, 3.5), randf_range(-2.5, 2.5))
		tween.tween_property(_board_area, "position", orig_pos + offset, 0.025)
	tween.tween_property(_board_area, "position", orig_pos, 0.03)


## Refreshes the win streak flame badge above the board.
func _update_streak_badge() -> void:
	if _streak_badge == null or _view_model == null:
		return
	if _view_model.get_config().is_two_player:
		_streak_badge.visible = false
		return
	var streak := _view_model.get_current_streak()
	if streak >= 2:
		_streak_badge.visible = true
		if _streak_label != null:
			var mult: float = 1.0 + float(streak - 1) * 0.25
			_streak_label.text = "Chuỗi thắng: %d! (x%.1f)" % [streak, mult]
			_streak_label.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_YELLOW, true)
	else:
		_streak_badge.visible = false


## Evaluates board state after a placement and triggers appropriate AI emotional response.
func _check_ai_threat_reaction(last_placed_mark: Domain.Mark) -> void:
	if _view_model == null or _view_model.get_config().is_two_player or _view_model.is_game_over():
		return
	var board := _view_model.get_board()
	var human_mark := _view_model.get_config().human_mark
	var ai_mark := _view_model.get_config().get_ai_mark()

	if last_placed_mark == human_mark:
		if _board_has_threat(board, human_mark):
			_set_ai_emote(ChalkTheme.TEX_AI_SWEAT, true)
		else:
			_set_ai_emote(ChalkTheme.TEX_AI_NORMAL, false)
	elif last_placed_mark == ai_mark:
		if _board_has_threat(board, ai_mark):
			_set_ai_emote(ChalkTheme.TEX_AI_SMUG, true)
		else:
			_set_ai_emote(ChalkTheme.TEX_AI_NORMAL, false)


func _board_has_threat(board: Board, mark: Domain.Mark) -> bool:
	for line in Board.WIN_LINES:
		var count := 0
		var empty_count := 0
		for idx in line:
			var m := board.cell_at(idx)
			if m == mark:
				count += 1
			elif m == Domain.Mark.NONE:
				empty_count += 1
		if count == 2 and empty_count == 1:
			return true
	return false


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

	var line_color := ChalkTheme.CHALK_YELLOW
	if _view_model != null:
		if _view_model.get_winner_mark() == Domain.Mark.X:
			line_color = ChalkTheme.CHALK_RED
		elif _view_model.get_winner_mark() == Domain.Mark.O:
			line_color = ChalkTheme.CHALK_BLUE

	var current_end := p_start.lerp(p_end, _win_line_progress)
	_winning_line_layer.draw_line(p_start + Vector2(2.0, 4.0), current_end + Vector2(2.0, 4.0), ChalkTheme.CHALK_SHADOW, 14.0, true)
	_winning_line_layer.draw_line(p_start, current_end, line_color, 11.0, true)


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
		_hide_result_overlay(func() -> void:
			if _view_model != null:
				_view_model.start_new_round(true)
				_check_schedule_ai_turn()
		)
	)
	_btn_result_menu.pressed.connect(func() -> void:
		_hide_result_overlay(func() -> void:
			if _view_model != null:
				_view_model.on_back_to_menu_pressed()
		)
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
