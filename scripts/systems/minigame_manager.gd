## MinigameManager - Управление мини-играми
## Переключает сцены мини-игр, обрабатывает результаты
## Поддерживает 3-4 типа мини-игр: Lockpick, Rhythm, Focus

extends Node

# ==================== СИГНАЛЫ ====================
signal minigame_started(minigame_type: String)
signal minigame_completed(success: bool, score: float)
signal minigame_failed(reason: String)

# ==================== ПЕРЕМЕННЫЕ ====================
# Ссылки на сцены мини-игр (заполнить в инспекторе)
@export var lockpick_scene: PackedScene
@export var rhythm_scene: PackedScene
@export var focus_scene: PackedScene

# Текущая активная мини-игра
var current_minigame: Node = null

# Контекст мини-игры (зачем она запущена)
var minigame_context: Dictionary = {}

# Сложность (зависит от состояния игрока)
var difficulty_modifier: float = 1.0

# ==================== ИНИЦИАЛИЗАЦИЯ ====================
func _ready() -> void:
	print("[MinigameManager] Initialized")

# ==================== ЗАПУСК МИНИ-ИГРЫ ====================
## Запускает мини-игру указанного типа
func start_minigame(minigame_type: String, context: Dictionary = {}) -> void:
	minigame_context = context
	
	# Сложность зависит от состояния игрока
	difficulty_modifier = 1.0 - (GameState.player_state * 0.1)
	
	var scene: = get_scene_for_type(minigame_type)
	if not scene:
		push_error("[MinigameManager] Scene not found for type: %s" % minigame_type)
		minigame_failed.emit("Scene not found")
		return
	
	# Очищаем текущую мини-игру
	if current_minigame:
		current_minigame.queue_free()
	
	# Создаём новую
	current_minigame = scene.instantiate()
	
	# Добавляем в дерево сцены (предполагается UI слой)
	# В реальном проекте нужно добавить в правильный слой
	get_tree().current_scene.add_child(current_minigame)
	
	# Настраиваем мини-игру
	if current_minigame.has_method("setup"):
		current_minigame.setup(minigame_context, difficulty_modifier)
	
	minigame_started.emit(minigame_type)
	print("[MinigameManager] Started minigame: %s" % minigame_type)

## Возвращает сцену для типа мини-игры
func get_scene_for_type(minigame_type: String) -> PackedScene:
	match minigame_type:
		"lockpick":
			return lockpick_scene
		"rhythm":
			return rhythm_scene
		"focus":
			return focus_scene
		_:
			push_warning("[MinigameManager] Unknown minigame type: %s" % minigame_type)
			return null

# ==================== ОБРАБОТКА РЕЗУЛЬТАТОВ ====================
## Вызывается мини-игрой при завершении
func on_minigame_completed(success: bool, score: float = 0.0) -> void:
	print("[MinigameManager] Minigame completed - Success: %s, Score: %.2f" % [success, score])
	
	# Применяем последствия
	if success:
		apply_success_effects(score)
	else:
		apply_failure_effects()
	
	# Очищаем
	if current_minigame:
		current_minigame.queue_free()
		current_minigame = null
	
	minigame_completed.emit(success, score)

## Применяет эффекты успеха
func apply_success_effects(score: float) -> void:
	# Улучшаем состояние
	var state_bonus: = 1 if score > 0.7 else 0
	GameState.change_state(state_bonus)
	
	# Добавляем трек действия
	GameState.add_track("action", 1)
	
	# Контекстные эффекты
	if minigame_context.has("on_success"):
		var effect: = minigame_context["on_success"]
		
		if effect.has("archetype_shift"):
			for archetype in effect["archetype_shift"]:
				GameState.shift_archetype(archetype, effect["archetype_shift"][archetype])

## Применяет эффекты провала
func apply_failure_effects() -> void:
	# Ухудшаем состояние
	GameState.change_state(-1)
	
	# Контекстные эффекты
	if minigame_context.has("on_fail"):
		var effect: = minigame_context["on_fail"]
		
		if effect.has("echo_event"):
			# Добавляем событие в эхо
			GameState.add_echo_event(effect["echo_event"]["id"], effect["echo_event"])

# ==================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ====================
## Проверяет, активна ли мини-игра
func is_minigame_active() -> bool:
	return current_minigame != null

## Принудительно завершает мини-игру (для отладки или таймаута)
func force_end_minigame() -> void:
	if current_minigame:
		if current_minigame.has_method("cleanup"):
			current_minigame.cleanup()
		
		current_minigame.queue_free()
		current_minigame = null
	
	minigame_failed.emit("Forced end")
