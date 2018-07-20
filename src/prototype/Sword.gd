extends Area2D

export (int) var damage = 2

onready var damage_to_deal = damage
onready var anim = $AnimationPlayer
onready var color_rect = $ColorRect
var entities_damaged = []

func swing_towards(angle_to_mouse):
	if not anim.is_playing():
		rotation = angle_to_mouse - PI/2
		anim.play("slash")

func process_slash_frame():
	for overlapper in get_overlapping_bodies() + get_overlapping_areas():
		if overlapper.is_in_group('sword_damageable') and !overlapper in entities_damaged:
			overlapper.damage_with(self, damage_to_deal)
			entities_damaged.append(overlapper)

func update_damage(velocity):
	damage_to_deal = damage + velocity.length() / 200

func _on_AnimationPlayer_animation_finished(anim_name):
	monitoring = false
	color_rect.visible = false

func _on_AnimationPlayer_animation_started(anim_name):
	monitoring = true
	color_rect.visible = true
	entities_damaged = []
