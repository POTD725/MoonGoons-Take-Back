extends SceneTree
## Verifies the imported-art catalog and that both playable scenes carry skin overlays.

var failures: int = 0

func _init() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var skin_script: Script = load("res://scripts/moongoons_skin_bank.gd") as Script
	_expect(skin_script != null, "MoonGoons skin bank script loads")
	if skin_script != null:
		var skin_node: Node = skin_script.new() as Node
		root.add_child(skin_node)
		await process_frame
		var catalog_value: Variant = skin_node.get("SKINS")
		_expect(catalog_value is Dictionary, "Skin bank exposes a dictionary catalog")
		if catalog_value is Dictionary:
			_expect((catalog_value as Dictionary).size() == 14, "Skin catalog contains all 14 established PNG assets")
		skin_node.queue_free()

	var precinct_scene: PackedScene = load("res://scenes/PrecinctVerticalSlice.tscn") as PackedScene
	_expect(precinct_scene != null, "Skinned precinct scene parses")
	if precinct_scene != null:
		var precinct: Node = precinct_scene.instantiate()
		_expect(precinct.has_node("MoonGoonsSkinOverlay"), "Precinct scene includes its imported-art overlay")
		precinct.queue_free()

	var battle_scene: PackedScene = load("res://scenes/PrecinctBattle.tscn") as PackedScene
	_expect(battle_scene != null, "Skinned patrol battle scene parses")
	if battle_scene != null:
		var battle: Node = battle_scene.instantiate()
		_expect(battle.has_node("MoonGoonsBattleSkinOverlay"), "Patrol scene includes its imported-art overlay")
		battle.queue_free()

	_expect(FileAccess.file_exists("res://tools/fetch_moongoons_skins.sh"), "Linux skin-sync helper exists")
	_expect(FileAccess.file_exists("res://tools/fetch_moongoons_skins.ps1"), "Windows skin-sync helper exists")

	await process_frame
	if failures == 0:
		print("SUCCESS: MoonGoons skin overlay smoke tests passed.")
	else:
		push_error("FAILED: %d skin overlay smoke test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
