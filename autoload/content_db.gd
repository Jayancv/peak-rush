extends Node
## Loads all game content from the explicit index (seasons -> trails) plus the balance
## numbers, and answers lookups. Never scan folders with DirAccess here: exported
## builds remap resources, so the index file is the only reliable list on phones.

const INDEX_PATH: String = "res://content/content_index.tres"
const BALANCE_PATH: String = "res://content/balance.tres"

var balance: Balance
var index: ContentIndex

var _seasons: Dictionary = {}
var _trails: Dictionary = {}
var _gear: Dictionary = {}
var _cosmetics: Dictionary = {}


func _ready() -> void:
	balance = load(BALANCE_PATH) as Balance
	if balance == null:
		push_error("ContentDB: could not load %s, using design defaults" % BALANCE_PATH)
		balance = Balance.new()
	var loaded: ContentIndex = load(INDEX_PATH) as ContentIndex
	if loaded == null:
		push_error("ContentDB: could not load %s" % INDEX_PATH)
		loaded = ContentIndex.new()
	use_index(loaded)


## Swaps in a content index (tests use this with hand-built content).
func use_index(new_index: ContentIndex) -> void:
	index = new_index
	_seasons.clear()
	_trails.clear()
	_gear.clear()
	_cosmetics.clear()
	if index.cosmetics != null:
		for c: CosmeticData in index.cosmetics.items:
			if c != null:
				_cosmetics[c.id] = c
	for g: GearData in index.gear:
		if g != null:
			_gear[g.id] = g
	for season: SeasonData in index.seasons:
		if season == null:
			continue
		_seasons[season.id] = season
		for trail: TrailData in season.trails:
			if trail != null:
				_trails[trail.id] = trail


func seasons() -> Array[SeasonData]:
	var out: Array[SeasonData] = []
	for s: SeasonData in index.seasons:
		if s != null:
			out.append(s)
	return out


func get_season(id: StringName) -> SeasonData:
	return _seasons.get(id) as SeasonData


func get_trail(id: StringName) -> TrailData:
	return _trails.get(id) as TrailData


func has_trail(id: StringName) -> bool:
	return _trails.has(id)


func gear_list() -> Array[GearData]:
	var out: Array[GearData] = []
	for g: GearData in index.gear:
		if g != null:
			out.append(g)
	return out


func get_gear(id: StringName) -> GearData:
	return _gear.get(id) as GearData


# --- Profile content ---

## Outfit colours for one slot, in catalog order (free ones first by convention).
func cosmetics(slot: CosmeticData.Slot) -> Array[CosmeticData]:
	var out: Array[CosmeticData] = []
	if index.cosmetics != null:
		for c: CosmeticData in index.cosmetics.items:
			if c != null and c.slot == slot:
				out.append(c)
	return out


func get_cosmetic(id: StringName) -> CosmeticData:
	return _cosmetics.get(id) as CosmeticData


## The first free item of a slot: what a new hiker wears.
func default_cosmetic(slot: CosmeticData.Slot) -> CosmeticData:
	for c: CosmeticData in cosmetics(slot):
		if c.stars_required <= 0:
			return c
	return null


func journeys() -> Array[JourneyData]:
	return index.journeys if index != null else [] as Array[JourneyData]


func events() -> Array[EventData]:
	return index.events if index != null else [] as Array[EventData]


func badge_list() -> Array[BadgeData]:
	var out: Array[BadgeData] = []
	if index.badges != null:
		for b: BadgeData in index.badges.badges:
			if b != null:
				out.append(b)
	return out


## The first unlocked trail not finished yet, newest season first (what "Continue"
## should open). Null when everything open has been finished.
## Where "Continue" goes: keep going in a season the player has started (newest of those
## first); otherwise start the earliest season with something left, so a new player
## begins with Season 1's tutorial even when later seasons are already open.
func next_unfinished_trail(is_unlocked: Callable, is_completed: Callable) -> TrailData:
	var started: Array[SeasonData] = []
	var fresh: Array[SeasonData] = []
	for s: SeasonData in seasons():
		var any_done: bool = s.trails.any(func(t: TrailData) -> bool: return is_completed.call(t.id))
		if any_done:
			started.push_front(s)
		else:
			fresh.append(s)
	for s: SeasonData in started + fresh:
		for t: TrailData in s.ordered_trails():
			if is_unlocked.call(t) and not is_completed.call(t.id):
				return t
	return null


func first_trail() -> TrailData:
	for s: SeasonData in seasons():
		var list: Array[TrailData] = s.ordered_trails()
		if not list.is_empty():
			return list[0]
	return null


## The trail before this one in its season's unlock order, or null if it's the first.
func previous_trail(id: StringName) -> TrailData:
	var list: Array[TrailData] = _season_list_for(id)
	var i: int = _index_in(list, id)
	return list[i - 1] if i > 0 else null


## The trail after this one in its season, or null if it's the last.
func next_trail(id: StringName) -> TrailData:
	var list: Array[TrailData] = _season_list_for(id)
	var i: int = _index_in(list, id)
	return list[i + 1] if i >= 0 and i + 1 < list.size() else null


func _season_list_for(id: StringName) -> Array[TrailData]:
	var trail: TrailData = get_trail(id)
	if trail == null:
		return []
	var season: SeasonData = get_season(trail.season_id)
	return season.ordered_trails() if season != null else []


func _index_in(list: Array[TrailData], id: StringName) -> int:
	for i: int in list.size():
		if list[i].id == id:
			return i
	return -1


# --- Validation (run by a test, so broken content can never ship) ---

## Returns human-readable problems; an empty list means the content is good.
func validate() -> Array[String]:
	return ContentValidator.validate_index(index)
