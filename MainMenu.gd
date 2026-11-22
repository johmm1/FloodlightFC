extends Control

var pulse_time := 0.0
var info_label: Label
var play_button: Button
var hero_ball: Label

func _ready() -> void:
	_build_menu()

func _process(delta: float) -> void:
	pulse_time += delta
	if hero_ball:
		hero_ball.rotation = sin(pulse_time * 0.7) * 0.08
		hero_ball.scale = Vector2.ONE * (1.0 + sin(pulse_time * 1.8) * 0.035)

func _build_menu() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.018, 0.045, 0.075)
	add_child(bg)

	var glow := ColorRect.new()
	glow.position = Vector2(0, 0)
	glow.anchor_right = 1.0
	glow.anchor_bottom = 0.56
	glow.color = Color(0.025, 0.22, 0.19, 0.72)
	add_child(glow)

	var stripe := ColorRect.new()
	stripe.anchor_left = 0.0
	stripe.anchor_top = 0.53
	stripe.anchor_right = 1.0
	stripe.anchor_bottom = 0.57
	stripe.color = Color(0.12, 0.9, 0.55)
	add_child(stripe)

	var content := VBoxContainer.new()
	content.anchor_left = 0.06
	content.anchor_top = 0.055
	content.anchor_right = 0.94
	content.anchor_bottom = 0.95
	content.add_theme_constant_override("separation", 12)
	add_child(content)

	var top := HBoxContainer.new()
	content.add_child(top)
	var brand := Label.new()
	brand.text = "FLOODLIGHT"
	brand.add_theme_font_size_override("font_size", 27)
	brand.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	top.add_child(brand)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var edition := Label.new()
	edition.text = "FC  •  SEASON 01"
	edition.add_theme_font_size_override("font_size", 13)
	edition.add_theme_color_override("font_color", Color(0.35, 1.0, 0.68))
	top.add_child(edition)

	var hero := CenterContainer.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(hero)
	var hero_stack := VBoxContainer.new()
	hero_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_stack.add_theme_constant_override("separation", 2)
	hero.add_child(hero_stack)

	hero_ball = Label.new()
	hero_ball.text = "⚽"
	hero_ball.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_ball.add_theme_font_size_override("font_size", 100)
	hero_stack.add_child(hero_ball)

	var title := Label.new()
	title.text = "OWN THE\nPITCH."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	hero_stack.add_child(title)

	var tagline := Label.new()
	tagline.text = "REAL FOOTBALL. YOUR MOMENT."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 15)
	tagline.add_theme_color_override("font_color", Color(0.34, 1.0, 0.68))
	hero_stack.add_child(tagline)

	var mode_title := Label.new()
	mode_title.text = "CHOOSE YOUR EXPERIENCE"
	mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_title.add_theme_font_size_override("font_size", 13)
	mode_title.add_theme_color_override("font_color", Color(0.72, 0.8, 0.87))
	content.add_child(mode_title)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 10)
	buttons.add_theme_constant_override("v_separation", 8)
	content.add_child(buttons)

	play_button = _make_button("▶   KICK OFF", Color(0.05, 0.72, 0.42))
	buttons.add_child(play_button)
	play_button.pressed.connect(_on_play_button_pressed)
	var training := _make_button("TRAINING GROUND", Color(0.12, 0.28, 0.43))
	buttons.add_child(training)
	training.pressed.connect(func(): _show_info("TRAINING GROUND\nPractice movement, passing and shooting. Full training mode is coming next."))
	var gym := _make_button("PLAYER GYM", Color(0.12, 0.28, 0.43))
	buttons.add_child(gym)
	gym.pressed.connect(func(): _show_info("PLAYER GYM\nFitness and player development hub — coming in the next update."))
	var controls := _make_button("HOW TO PLAY", Color(0.12, 0.28, 0.43))
	buttons.add_child(controls)
	controls.pressed.connect(func(): _show_info("MOVE: left joystick   •   PASS: PASS button\nSHOOT: SHOOT button   •   SPRINT: hold SPRINT"))

	info_label = Label.new()
	info_label.text = "11 VS 11  •  MOBILE MATCHDAY"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size.y = 38
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.82, 0.87))
	content.add_child(info_label)

	var footer := Label.new()
	footer.text = "FLOODLIGHT FC  |  BUILT FOR THE LOVE OF THE GAME"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color(0.43, 0.56, 0.63))
	content.add_child(footer)

func _make_button(caption: String, tint: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = tint.lightened(0.16)
	button.add_theme_stylebox_override("hover", hover)
	return button

func _show_info(message: String) -> void:
	if info_label:
		info_label.text = message

func _on_play_button_pressed() -> void:
	info_label.text = "PREPARING MATCHDAY..."
	play_button.disabled = true
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
