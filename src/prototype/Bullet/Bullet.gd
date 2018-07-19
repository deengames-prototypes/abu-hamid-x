extends KinematicBody2D

### ABSTRACT CLASS. DO NOT INSTANTIATE.

export (float) var bullet_speed = 1500
export (int) var damage_to_deal = 1

var velocity
var collider_group

func _process(delta):
	collide(move_and_collide(velocity * delta))

func collide(info):
	if info == null:
		return
	if info.collider.is_in_group(self.collider_group):
		# bullets are a pain.
		# for giants, we have to choose between two:
			# damaging giants even outside hitspots
			# not damaging giants even in hitspots
		# I chose the former and called it a feature >:]
		info.collider._on_body_entered(self)
	queue_free()

func init(collider_group, x, y, angle):
	self.collider_group = collider_group
	position.x = x
	position.y = y
	velocity = Vector2(-bullet_speed, 0).rotated(angle)