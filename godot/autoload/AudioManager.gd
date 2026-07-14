extends Node
## 音频系统（框架占位）。表现层（白噪音 / 雨声）属待推迟的内容，
## 本占位只保留 ensure_started() 接缝，便于后续接入真实素材而不动引擎调用点。
## 接入方式：放 res://audio/rain.ogg 后在此实现循环播放；当前无素材，安静回退。

func ensure_started() -> void:
	# 框架接缝：进入场景时调用。当前无音频素材，静默。
	pass
