extends Node
## Loads game content: the balance numbers now, and in M3 the explicit content
## index (seasons -> trails) with lookups and the validator.
## Never scan folders with DirAccess here: exported builds remap resources,
## so the index file is the only reliable list of content on phones.

const INDEX_PATH: String = "res://content/content_index.tres"
const BALANCE_PATH: String = "res://content/balance.tres"

var balance: Balance


func _ready() -> void:
	balance = load(BALANCE_PATH) as Balance
	if balance == null:
		push_error("ContentDB: could not load %s, using design defaults" % BALANCE_PATH)
		balance = Balance.new()


func has_index() -> bool:
	return ResourceLoader.exists(INDEX_PATH)
