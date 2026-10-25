extends Resource
class_name SaveData

## Save data for the whole game.

#region Data
## The last unix time used to calculate "grows offline"
@export var time_last_played: float

## The amount of button clicks
@export var clicks: float = 0:
    set(value): clicks = value; clicks_changed.emit(value)
signal clicks_changed(value: float)

## The amount of button clicks per second calculated from upgrades and shop items. Used for offline earnings.
@export var cps: float: # TODO: Implement
    get: return 0

#region Settings

@export var settings_master_volume: float = 1:
    set(value): settings_master_volume = value; settings_master_volume_changed.emit()
signal settings_master_volume_changed

@export var settings_music_volume: float = 1:
    set(value): settings_music_volume = value; settings_music_volume_changed.emit()
signal settings_music_volume_changed

@export var settings_sfx_volume: float = 1:
    set(value): settings_sfx_volume = value; settings_sfx_volume_changed.emit()
signal settings_sfx_volume_changed

@export var settings_ui_volume: float = 1:
    set(value): settings_ui_volume = value; settings_ui_volume_changed.emit()
signal settings_ui_volume_changed

#endregion

#endregion

## Serializes SaveData into a string for storage.
func serialize() -> String:
    time_last_played = Time.get_unix_time_from_system()
    return Marshalls.variant_to_base64(self, true)

#region Private Methods
static func _create_new() -> SaveData:
    Log.info("[SaveData] No previous save data, creating new...")
    return SaveData.new()

## Deserializes a base64 string into SaveData, null if invalid
static func from_base64(data: String) -> SaveData:
    if data.strip_edges().strip_escapes().is_empty():
        return _create_new()
    var decoded: Variant = Marshalls.base64_to_variant(data, true)
    if decoded == null:
        return _create_new()
    return decoded
#endregion