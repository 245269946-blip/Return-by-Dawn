extends Node
## 音频系统（表现层接入层，已落地）。
## 程序化合成素材见 godot/audio/*.wav（白噪音底 + 4 态雨 + 室内底噪 + 4 个交互音效）。
## 设计：常驻 amb_noise（空气底）+ room_tone（室内低频），雨声按区域切换并做交叉淡入淡出。
## 缺失素材时 load() 返回 null，全程静默回退，绝不阻断游戏逻辑。

const AUDIO_DIR := "res://audio/"

var _started := false
var bed_player: AudioStreamPlayer
var room_player: AudioStreamPlayer
var rain_players: Array[AudioStreamPlayer] = []
var rain_idx := 0
var sfx_player: AudioStreamPlayer
var pad_player: AudioStreamPlayer
var current_rain: String = ""
var current_pad_file: String = ""

# 区域 -> 雨态映射（同时接受直接传雨态字符串）。void_room 永不开启，对应 "none"（结构性静默）。
var _rain_for_region := {
	"entry_porch": "heavy",
	"reading_room": "indoor",
	"stacks_deep": "heavy",
	"service_desk": "fine",
	"study_zone": "fine",
	"utility_zone": "indoor",
	"lounge_stairs": "eaves",
	"archive_lamp": "fine",
	"void_room": "none",
}

func _ready() -> void:
	bed_player = _new_player("amb_noise.wav", -16.0, true)
	room_player = _new_player("room_tone.wav", -20.0, true)
	rain_players = [_new_player("", -10.0, true), _new_player("", -10.0, true)]
	sfx_player = _new_player("", 0.0, false)
	pad_player = _new_player("", -18.0, true)

func _new_player(fname: String, vol_db: float, loop: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = &"Master"
	p.volume_db = vol_db
	add_child(p)  # 必须先进树，否则 play() 报 "node not inside scene tree"
	if fname != "":
		var s = _load_stream(fname, loop)
		if s != null:
			p.stream = s
			p.play()
	return p

func _load_stream(fname: String, loop: bool) -> AudioStream:
	var res = load(AUDIO_DIR + fname)
	if res == null:
		return null
	if loop and res.has_method("set_loop"):
		res.loop = true
	return res

func ensure_started() -> void:
	if _started:
		return
	_started = true
	set_mood("fine")

## 切换雨声/环境 mood。
## 入参可以是区域 id（自动映射）或直接雨态（fine/heavy/indoor/eaves/none）。
func set_mood(rain_state: String, _night_id: String = "") -> void:
	if not _started:
		ensure_started()
	if _rain_for_region.has(rain_state):
		rain_state = _rain_for_region[rain_state]
	if rain_state == current_rain:
		return
	current_rain = rain_state
	if rain_state == "none" or rain_state == "":
		_fade_out_rain()
		return
	var s = _load_stream("rain_%s.wav" % rain_state, true)
	if s == null:
		s = _load_stream("rain_fine.wav", true)
		if s == null:
			return
	_crossfade_rain(s)

func _fade_out_rain() -> void:
	var p = rain_players[rain_idx]
	var tw = get_tree().create_tween()
	tw.tween_property(p, "volume_db", -60.0, 0.6)

func _crossfade_rain(new_stream: AudioStream) -> void:
	var incoming = rain_players[rain_idx ^ 1]
	var outgoing = rain_players[rain_idx]
	incoming.stream = new_stream
	incoming.volume_db = -60.0
	incoming.play(0.0)
	var tw = get_tree().create_tween()
	tw.parallel().tween_property(incoming, "volume_db", -10.0, 0.8)
	tw.parallel().tween_property(outgoing, "volume_db", -60.0, 0.8)
	rain_idx ^= 1

## 交互音效：page / slot / click / lamp / drawer / door / water / breath / notice_chime / curtain / companion
func play_sfx(id: String) -> void:
	if not _started:
		ensure_started()
	var fname = {
		"page": "sfx_page.wav",
		"slot": "sfx_slot.wav",
		"click": "sfx_click.wav",
		"lamp": "sfx_lamp.wav",
		"drawer": "sfx_drawer.wav",
		"door": "sfx_door.wav",
		"water": "sfx_water.wav",
		"breath": "sfx_breath.wav",
		"notice_chime": "sfx_notice_chime.wav",
		"curtain": "sfx_curtain.wav",
		"companion": "sfx_companion.wav",
	}.get(id, "")
	if fname == "":
		return
	var s = _load_stream(fname, false)
	if s == null:
		return
	sfx_player.stream = s
	sfx_player.play(0.0)

## 章节色调 Pad：每段夜一段无旋律情绪底噪（循环）。缺失自动静默回退。
func set_chapter(night_id: String) -> void:
	if not _started:
		ensure_started()
	var fmap := {
		"prologue": "pad_prologue.wav",
		"night_a": "pad_nightA.wav",
		"night_b": "pad_nightB.wav",
		"night_c": "pad_nightC.wav",
		"night_d": "pad_nightD.wav",
		"night_e": "pad_nightE.wav",
		"night_f": "pad_nightF.wav",
		"night_g": "pad_nightG.wav",
		"night_h": "pad_nightH.wav",
		"night_i": "pad_nightI.wav",
		"night_z": "pad_nightZ.wav",
	}
	var fn = fmap.get(night_id, "")
	if fn == "" or fn == current_pad_file:
		return
	current_pad_file = fn
	var s = _load_stream(fn, true)
	if s == null:
		return
	pad_player.stream = s
	pad_player.volume_db = -60.0
	pad_player.play(0.0)
	var tw := get_tree().create_tween()
	tw.tween_property(pad_player, "volume_db", -16.0, 1.2)

## 叙事转场 Sting：notice / enter / reveal / exit / curtain
func play_sting(kind: String) -> void:
	if not _started:
		ensure_started()
	var fn = {
		"notice": "sting_notice.wav",
		"enter": "sting_enter.wav",
		"reveal": "sting_reveal.wav",
		"exit": "sting_exit.wav",
		"curtain": "sting_curtain.wav",
	}.get(kind, "")
	if fn == "":
		return
	var s = _load_stream(fn, false)
	if s == null:
		return
	sfx_player.stream = s
	sfx_player.play(0.0)

## 主音量 / 静音（设置页用，控制 Master 总线）
func set_master_volume(v: float) -> void:
	var vol: float = clamp(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(max(vol, 0.0001)))

func set_muted(m: bool) -> void:
	AudioServer.set_bus_mute(0, m)
