class_name BadgeView
extends RefCounted
## Builds the round medal for a badge (profile screen and the results screen use it).

const ICONS: Dictionary = {
	BadgeData.Art.MOUNTAIN: UiIcon.Kind.MOUNTAIN, BadgeData.Art.STAR: UiIcon.Kind.STAR,
	BadgeData.Art.CAMERA: UiIcon.Kind.CAMERA, BadgeData.Art.BOOTS: UiIcon.Kind.BOOTS,
	BadgeData.Art.HEADLAMP: UiIcon.Kind.HEADLAMP, BadgeData.Art.GEAR: UiIcon.Kind.SHELL,
	BadgeData.Art.CLOCK: UiIcon.Kind.CLOCK,
}
const LOCKED: Color = Color("#C9C3B6")
const CREAM: Color = Color("#FFF6E5")


static func medal(badge: BadgeData, earned: bool, px: float) -> ShadedBadge:
	return icon_badge(ICONS.get(badge.art, UiIcon.Kind.STAR), badge.color if earned else LOCKED, CREAM, px)


## A shaded round badge with a UiIcon in the middle.
static func icon_badge(kind: UiIcon.Kind, back: Color, ink: Color, px: float) -> ShadedBadge:
	var badge: ShadedBadge = ShadedBadge.new()
	badge.custom_minimum_size = Vector2(px, px)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.base_color = back
	badge.shadow_size = 4.0
	var icon: UiIcon = UiIcon.new()
	icon.kind = kind
	icon.color = ink
	icon.cutout = back
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset: float = px * 0.22
	icon.offset_left = inset
	icon.offset_top = inset
	icon.offset_right = -inset
	icon.offset_bottom = -inset
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(icon)
	return badge
