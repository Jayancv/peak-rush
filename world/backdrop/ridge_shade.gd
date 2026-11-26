class_name RidgeShade
extends RefCounted
## The shaded faces of a ridged RidgeLayer. Light comes from the left, so each peak's
## right-hand face is in shadow, from the skyline down to a crease running from the
## summit to the foot of the mountain. A cool tint that fades towards the foot, so snow
## in shadow turns blue-grey and the haze at the base is kept.

const SHADE: Color = Color(0.1, 0.13, 0.3)
## Bumps smaller than this (px from peak to valley) get no shaded face.
const MIN_FACE: float = 30.0


static func faces(layer: RidgeLayer) -> TreeArt.Batch:
	var out: TreeArt.Batch = TreeArt.Batch.new()
	var top: Color = Color(SHADE, layer.shade_amount)
	var foot: Color = Color(SHADE, 0.0)
	var bottom: float = layer.base_y + 60.0
	# Faces start on peaks inside one tile but may run on past its end: the skyline
	# repeats, and the next copy has no face of its own there.
	var sky: PackedVector2Array = PackedVector2Array()
	var x: float = -RidgeLayer.STEP
	while x <= layer.width * 1.35:
		sky.append(Vector2(x, layer.height_at(x)))
		x += RidgeLayer.STEP
	var i: int = 1
	while i < sky.size() - 1 and sky[i].x < layer.width:
		if sky[i].y < sky[i - 1].y and sky[i].y <= sky[i + 1].y:
			var j: int = i
			while j < sky.size() - 1 and sky[j + 1].y > sky[j].y:
				j += 1
			if sky[j].y - sky[i].y >= MIN_FACE:
				var peak: Vector2 = sky[i]
				var crease: Vector2 = Vector2(peak.x + (sky[j].x - peak.x) * 0.14, bottom)
				var shape: PackedVector2Array = sky.slice(i, j + 1)
				shape.append_array([Vector2(sky[j].x, bottom), crease,
					peak.lerp(crease, 0.55) + Vector2(5, 0), peak.lerp(crease, 0.25) - Vector2(3, 0)])
				var idx: PackedInt32Array = PackedInt32Array()
				for p: Vector2 in shape:
					idx.append(out.pts.size())
					out.pts.append(p)
					out.cols.append(top.lerp(foot, clampf((p.y - peak.y) / (bottom - peak.y), 0.0, 1.0)))
					out.uvs.append(Vector2.ZERO)
				out.polys.append(idx)
			i = j
		i += 1
	return out
