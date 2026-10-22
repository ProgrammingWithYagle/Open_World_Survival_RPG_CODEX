extends Node2D
class_name MossProjectile

var direction := Vector2.RIGHT
var damage := 10.0
var friendly := true
var magic := false
var world_view: MossWorldView
var lifetime := 2.0


func _physics_process(delta: float) -> void:
	if Session.paused:
		return
	lifetime -= delta
	var next := position + direction * (230.0 if friendly else 135.0) * delta
	if lifetime <= 0 or not Session.world_model.passable(Vector2i(next / 32.0), Session.state):
		queue_free()
		return
	position = next
	if friendly:
		for actor in world_view.actors.values():
			if (
				is_instance_valid(actor)
				and not actor.dying
				and actor.position.distance_to(position) < actor.radius + 7
			):
				actor.take_hit(damage, direction)
				queue_free()
				return
	else:
		if world_view.player.position.distance_to(position) < 13:
			world_view.player.take_hit(damage, position - direction * 10)
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	if magic:
		draw_circle(Vector2.ZERO, 3, Color(.74, .87, .61) if friendly else Color(.96, .55, .31))
		draw_circle(-direction * 4, 1.5, Color(.92, .85, .59, .5))
	else:
		draw_line(-direction * 7, direction * 3, Color(.89, .81, .63), 1.5)
		draw_line(direction * 3, direction * 6, Color(.53, .68, .66), 2)
