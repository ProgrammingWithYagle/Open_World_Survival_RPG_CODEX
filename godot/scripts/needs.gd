extends Node
class_name Needs

## Handles survival stats like hunger, thirst, and temperature.

signal needs_changed

var hunger := 100.0
var thirst := 100.0
var temperature := 20.0
var health := 100.0
var max_health := 100.0
var stamina := 100.0
var max_stamina := 100.0

var hunger_decay := 0.6
var thirst_decay := 0.9
var temperature_drift := 0.15
var health_decay_rate := 1.5
var extreme_temperature_threshold := 12.0
## Stamina tuning: idle drain always applies, resting offsets drain, movement adds extra drain.
var stamina_idle_drain := 0.25
var stamina_rest_regen := 0.7
var stamina_move_drain := 0.8
var stamina_sprint_drain := 1.6
var stamina_action_cost := 6.0
var is_resting := true
var enabled := true

var base_hunger_decay := 0.0
var base_thirst_decay := 0.0
var base_temperature_drift := 0.0
var base_health_decay_rate := 0.0

func _ready() -> void:
	_cache_base_decay_rates()

func tick(delta: float) -> void:
	if not enabled:
		return
	hunger = clampf(hunger - hunger_decay * delta, 0.0, 100.0)
	thirst = clampf(thirst - thirst_decay * delta, 0.0, 100.0)
	temperature = clampf(temperature + temperature_drift * delta, -10.0, 45.0)
	_update_stamina(delta)
	_apply_survival_penalties(delta)
	emit_signal("needs_changed")

func get_readout() -> String:
	return "Health: %d\nHunger: %d\nThirst: %d\nStamina: %d\nTemp: %d°C" % [
		int(health),
		int(hunger),
		int(thirst),
		int(stamina),
		int(temperature)
	]

func apply_item_effects(effects: Dictionary) -> void:
	if effects.is_empty():
		return
	hunger = clampf(hunger + float(effects.get("hunger", 0.0)), 0.0, 100.0)
	thirst = clampf(thirst + float(effects.get("thirst", 0.0)), 0.0, 100.0)
	temperature = clampf(temperature + float(effects.get("temperature", 0.0)), -10.0, 45.0)
	health = clampf(health + float(effects.get("health", 0.0)), 0.0, max_health)
	stamina = clampf(stamina + float(effects.get("stamina", 0.0)), 0.0, max_stamina)
	emit_signal("needs_changed")

func apply_stamina_drain(amount: float) -> void:
	if amount <= 0.0:
		return
	stamina = clampf(stamina - amount, 0.0, max_stamina)

func apply_action_stamina_cost(multiplier: float = 1.0) -> void:
	if multiplier <= 0.0:
		return
	stamina = clampf(stamina - stamina_action_cost * multiplier, 0.0, max_stamina)
	emit_signal("needs_changed")

func apply_difficulty_settings(settings: WorldSettings) -> void:
	## Centralized difficulty tuning for hunger/thirst decay.
	_reset_decay_rates()
	if settings == null:
		return
	hunger_decay = base_hunger_decay * settings.get_hunger_decay_multiplier()
	thirst_decay = base_thirst_decay * settings.get_thirst_decay_multiplier()

func reset_stats() -> void:
	hunger = 100.0
	thirst = 100.0
	temperature = 20.0
	health = max_health
	stamina = max_stamina
	emit_signal("needs_changed")

func _cache_base_decay_rates() -> void:
	base_hunger_decay = hunger_decay
	base_thirst_decay = thirst_decay
	base_temperature_drift = temperature_drift
	base_health_decay_rate = health_decay_rate

func _reset_decay_rates() -> void:
	hunger_decay = base_hunger_decay
	thirst_decay = base_thirst_decay
	temperature_drift = base_temperature_drift
	health_decay_rate = base_health_decay_rate

func _update_stamina(delta: float) -> void:
	var stamina_change := -stamina_idle_drain * delta
	if is_resting:
		stamina_change += stamina_rest_regen * delta
	stamina = clampf(stamina + stamina_change, 0.0, max_stamina)

func _apply_survival_penalties(delta: float) -> void:
	var penalty_multiplier := 0.0
	if hunger <= 0.0:
		penalty_multiplier += 1.0
	if thirst <= 0.0:
		penalty_multiplier += 1.0
	if abs(temperature - 22.0) > extreme_temperature_threshold:
		penalty_multiplier += 0.5
	if penalty_multiplier <= 0.0:
		return
	health = clampf(health - health_decay_rate * penalty_multiplier * delta, 0.0, max_health)
