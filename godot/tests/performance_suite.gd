extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node = load("res://scenes/Mossbound.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.qa["capture"] = "performance"
	Session.new_journey("Performance test", "Mossbound reference seed", "normal", "easycore", true)
	Session.state.id = "test_performance"
	Session.active = false
	var results: Array = []
	for region in range(5):
		Session.state.player.health = 100000
		Session.set_player_position(
			Vector2(Session.world_model.landmarks[region] * 32) + Vector2(90, 90)
		)
		var started := Time.get_ticks_usec()
		main._build_world()
		main.ui.show_hud()
		var load_ms := float(Time.get_ticks_usec() - started) / 1000.0
		for index in range(24):
			var position_ := (
				Session.player_position() + Vector2.from_angle(index * TAU / 24.0) * 150
			)
			position_ = Session.world_model.safe_position(position_, Session.state)
			var creature_id := str(Content.mobs.keys()[region * 3 + index % 3])
			main.world_view.spawn_creature(creature_id, position_, "perf_%d_%d" % [region, index])
		await get_tree().create_timer(1.2).timeout
		var samples: Array = []
		var frame_samples: Array = []
		for frame in range(120):
			var before := Time.get_ticks_usec()
			await get_tree().process_frame
			samples.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000)
			frame_samples.append(float(Time.get_ticks_usec() - before) / 1000)
		samples.sort()
		frame_samples.sort()
		var streaming: Array = []
		for step in range(3):
			var next_boundary: float = (
				(floorf(main.world_view.player.position.x / 1024) + 1) * 1024 + 32
			)
			main.world_view.player.position.x = next_boundary
			Session.set_player_position(main.world_view.player.position)
			var before := Time.get_ticks_usec()
			main.world_view.refresh()
			var first_slice := float(Time.get_ticks_usec() - before) / 1000.0
			var peak_frame := 0.0
			while main.world_view.streaming_pending:
				var frame_start := Time.get_ticks_usec()
				await get_tree().process_frame
				peak_frame = maxf(peak_frame, float(Time.get_ticks_usec() - frame_start) / 1000.0)
			streaming.append(
				{
					"initial_slice_ms": first_slice,
					"total_ms": float(Time.get_ticks_usec() - before) / 1000.0,
					"peak_frame_interval_ms": peak_frame
				}
			)
		results.append(
			{
				"region": Content.regions[region].id,
				"creatures": main.world_view.actors.size(),
				"visible_props": main.world_view.props.size(),
				"initial_load_ms": load_ms,
				"cpu_frame_median_ms": samples[60],
				"cpu_frame_p95_ms": samples[114],
				"frame_interval_median_ms": frame_samples[60],
				"frame_interval_p95_ms": frame_samples[114],
				"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				"chunk_stream_ms": streaming
			}
		)
	var report := {
		"renderer": RenderingServer.get_video_adapter_name(),
		"godot": Engine.get_version_info().string,
		"resolution": [1280, 720],
		"world_resolution": [640, 360],
		"samples_per_region": 120,
		"results": results
	}
	var path := ProjectSettings.globalize_path("res://../verification/performance.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("PERFORMANCE_SUITE ", JSON.stringify(report))
	main.quit_game(false)
