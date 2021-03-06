extends "../Character.gd"

export (int) var max_movement_speed = 800
export (int) var acceleration = 2000

export (float) var health_regen_per_second = 0.5
export (float) var flying_impulse_velocity = 4500
export (float) var flying_attack_min_velocity = 500
export (float) var flying_attack_cooldown = 1.5

signal fuel_change(new_fuel, max_fuel)
signal health_change(new_hp, max_hp)
signal shoot_bullet(bullet)
signal num_bullet_change(new_clip, new_outside)

var seconds_since_last_flying_attack = 999

onready var movement_component = preload('res://prototype/Character/Player/Movement.gd').new(self)
onready var sword = preload('res://prototype/Sword.tscn').instance()
onready var jetpack = $Jetpack
onready var gun = $Gun

func pickup_bullets(bullets_to_pickup):
	gun.pickup_bullets(bullets_to_pickup)
	
func _free():
	$ui/DeathLabel.visible = true
	visible = false

func _ready():
	sword.connect('finish_swing', self, '_on_sword_finish_swing')
	jetpack.set_floor_raycast($FloorRaycast)

	register_damaging_group('enemies')
	register_damaging_group('enemybullet')
	register_damaging_group('traps')

	if health_regen_per_second == 0:
		$HealthRegenTimer.autostart = false
	else:
		$HealthRegenTimer.wait_time = 1/health_regen_per_second


func _process(delta):
	if is_dead:
		return

	seconds_since_last_flying_attack += delta
	
	if global.config.enable_sword == true and Input.is_action_just_pressed('attack'):
		add_child(sword)
		var starting_angle = get_angle_to(get_global_mouse_position())
		var target_angle = starting_angle + PI
		sword.rotation = starting_angle
		sword.swing_to(target_angle)
		
		if (global.config.flying_attacks == true 
			and jetpack.is_using_jetpack 
			and linear_velocity.length() > flying_attack_min_velocity 
			and (Input.is_action_pressed('boost') or global.config.enable_boost == false)
			and seconds_since_last_flying_attack > flying_attack_cooldown):
				seconds_since_last_flying_attack = 0
				self.apply_impulse(
					Vector2(0, 0), 
					Vector2(flying_impulse_velocity, 0).rotated(linear_velocity.angle())
				)


func _on_sword_finish_swing():
	remove_child(sword)


func _integrate_forces(state):
	if is_dead:
		return
	
	movement_component._integrate_forces(state)
	jetpack._integrate_forces(state)
	sword.update_damage(state.get_linear_velocity())
	
	emit_signal('fuel_change', jetpack.fuel, jetpack.max_jetpack_fuel)
	emit_signal('health_change', health, max_health)

func _unhandled_input(event):
	# ignore motion and mousedowns
	if (event is InputEventMouseMotion 
		or (event is InputEventMouseButton 
			and event.pressed
			)):
		return
	if is_dead:
		if event is InputEventKey and event.scancode == KEY_ESCAPE:
			get_tree().change_scene('res://prototype/MainMenu.tscn')
		else:
			get_tree().change_scene(get_parent().filename)

	
func _on_body_entered(body):
	._on_body_entered(body)
	
	if jetpack.is_using_jetpack and body.is_in_group("floor"):
		jetpack._disable_jetpack()

func _on_health_regen():
	if is_dead:
		return
	
	if health < max_health:
		health += 1

func _on_Gun_shoot_bullet(bullet):
	emit_signal('shoot_bullet', bullet)

func _on_Gun_num_bullet_change(new_clip, new_outside):
	emit_signal("num_bullet_change", new_clip, new_outside)

func change_gun(new_gun):
	remove_child(gun)
	gun = new_gun
	gun.connect('num_bullet_change', self, "_on_Gun_num_bullet_change")
	gun.connect('shoot_bullet', self, "_on_Gun_shoot_bullet")
	add_child(gun)