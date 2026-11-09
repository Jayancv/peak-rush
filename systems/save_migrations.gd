class_name SaveMigrations
extends RefCounted
## One step per save format change. step(n, data) turns a version-n save into n + 1.
## Never edit an old step once it has shipped: players' files depend on it.


static func step(from_version: int, data: Dictionary) -> Dictionary:
	match from_version:
		0:
			return _v0_to_v1(data)
	push_error("SaveMigrations: no step from version %d" % from_version)
	return data


## v0 is the pre-release prototype shape (no save_version, stars stored as a count
## per trail under "stars", TP under "points"). No v0 file shipped to players;
## this first link exists so the chain is exercised by tests from day one.
static func _v0_to_v1(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if out.has("points") and not out.has("tp"):
		out["tp"] = out["points"]
	out.erase("points")
	var trails: Dictionary = out.get("trails", {}) if out.get("trails", {}) is Dictionary else {}
	var old_stars: Variant = out.get("stars", {})
	if old_stars is Dictionary:
		for id: Variant in old_stars:
			# A star count n becomes the lowest n bits (★1 summit first).
			var n: int = clampi(int(old_stars[id]), 0, 3)
			var rec: Dictionary = trails.get(id, {})
			rec["stars"] = (1 << n) - 1
			trails[id] = rec
	out.erase("stars")
	out["trails"] = trails
	return out
