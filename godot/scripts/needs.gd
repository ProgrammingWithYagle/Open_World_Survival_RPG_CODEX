extends Node
class_name Needs

## Handles survival stats like hunger, thirst, and temperature.

signal needs_changed

var hunger := 100.0
var thirst := 100.0
var temperature := 20.0

var hunger_decay := 0.6
var thirst_decay := 0.9
var temperature_drift := 0.15

func tick(delta: float) -> void:
    hunger = clampf(hunger - hunger_decay * delta, 0.0, 100.0)
    thirst = clampf(thirst - thirst_decay * delta, 0.0, 100.0)
    temperature = clampf(temperature + temperature_drift * delta, -10.0, 45.0)
    emit_signal("needs_changed")

func get_readout() -> String:
    return "Hunger: %d\nThirst: %d\nTemp: %d°C" % [int(hunger), int(thirst), int(temperature)]
