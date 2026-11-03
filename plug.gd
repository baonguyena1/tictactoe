## Dependency manifest for gd-plug (Godot Package Manager, equivalent to Package.swift / package.json).
## Usage: /Applications/Godot.app/Contents/MacOS/Godot --headless -s plug.gd install
extends "res://addons/gd-plug/plug.gd"


## Declares external third-party Godot plugins to install into `res://addons/`.
func _plugging() -> void:
	# UIFlow: Stack-based UI navigation & workflow framework (UIFlow.push, UIFlow.pop, transitions, modals)
	plug("indieshade/uiflow", {"include": ["addons/ui_flow"]})
	# GUT (Godot Unit Test): XCTest-style unit testing framework with bottom panel runner in Godot Editor
	plug("bitwes/Gut", {"include": ["addons/gut"]})
	# Godot AI: MCP server and AI tools for Godot Editor live integration
	plug("hi-godot/godot-ai", {"include": ["plugin/addons/godot_ai"]})
