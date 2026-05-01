# README: Структура проекта Passing Through

## 📁 СТРУКТУРА ПАПOK

```
/workspace
├── scripts/
│   ├── global/              # Синглтоны (автозагрузка)
│   │   ├── game_state.gd    # Глобальное состояние игры
│   │   └── game_manager.gd  # Главный контроллер потока игры
│   │
│   ├── systems/             # Игровые системы
│   │   ├── event_manager.gd # Управление событиями и нарративом
│   │   ├── memory_system.gd # Система памяти и фото
│   │   └── minigame_manager.gd # Мини-игры
│   │
│   ├── entities/            # Игровые объекты
│   │   └── player_controller.gd # Контроллер игрока
│   │
│   ├── ui/                  # Интерфейс
│   │   └── ui_controller.gd # Управление UI
│   │
│   └── utils/               # Утилиты
│       └── parallax_background.gd # Параллакс-фон
│
├── data/
│   ├── events/              # JSON с событиями
│   │   └── sample_events.json
│   │
│   └── archetypes/          # Конфигурация архетипов
│       └── archetypes_config.json
│
├── scenes/
│   ├── main/                # Основные сцены (Main.tscn)
│   ├── gameplay/            # Сцены геймплея
│   ├── ui/                  # UI сцены
│   └── minigames/           # Сцены мини-игр
│
└── assets/
    └── sprites/             # Спрайты (плейсхолдеры)
```

---

## 🔧 НАСТРОЙКА В GODOT

### 1. Добавьте синглтоны (Autoload)

В **Project Settings → Autoload** добавьте:

| Path | Name |
|------|------|
| `res://scripts/global/game_state.gd` | GameState |
| `res://scripts/global/game_manager.gd` | GameManager |
| `res://scripts/systems/event_manager.gd` | EventManager |
| `res://scripts/systems/memory_system.gd` | MemorySystem |
| `res://scripts/systems/minigame_manager.gd` | MinigameManager |

### 2. Создайте основную сцену

1. Создайте новую сцену `scenes/main/Main.tscn`
2. Добавьте узел `Node2D` как корневой
3. Добавьте подузлы:
   - `Player` (CharacterBody2D) → прикрепите `player_controller.gd`
   - `ParallaxBackground` (Node2D) → прикрепите `parallax_background.gd`
   - `UI` (CanvasLayer) → прикрепите `ui_controller.gd`

### 3. Настройте входные действия

В **Project Settings → Input Map** добавьте:

- `move_left` ← A / Left Arrow
- `move_right` ← D / Right Arrow
- `boost` ← Shift / Space
- `interact` ← E / Enter
- `photo` ← P / Click

---

## 🎮 ОСНОВНЫЕ МЕХАНИКИ

### 🔄 Игровой цикл

```
MENU → MORNING → TRAVEL → EVENT → EVENING → NIGHT → (repeat 15 days) → FINAL
```

### 📊 GameState

Хранит всё прогресс-данные:
- `current_day` (1-15)
- `player_state` (-2 до +2)
- `tracks` {action, observe, connect}
- `archetypes` {euphoric, obsessive, cynic, fleeing, healer, nihilist, selfharm}
- `memory` (выбранные фото)
- `echo_events` (пропущенные события)

### 📸 Фото-система

1. В событии игрок получает 2-3 варианта "кадра восприятия"
2. За день можно сделать максимум 3 фото
3. Вечером выбирается 1 фото для долговременной памяти
4. Фото влияет на финал и эхо-события

### 🔁 Эхо-система

Если игрок пропускает событие с `risk: true`:
1. Оно добавляется в `echo_events`
2. Через 2-4 дня возвращается с последствиями
3. Текст изменён ("Эхо: ...")

### 🎭 Архетипы

Не классы, а стиль интерпретации:
- Влияют на текст событий
- Меняют визуальные фильтры
- Определяют финальную рефлексию

---

## 📝 КАК ДОБАВИТЬ СОБЫТИЕ

Создайте JSON в `data/events/`:

```json
{
  "events": [
    {
      "id": "unique_id_001",
      "title": "Название события",
      "description": "Описание ситуации",
      "location": "bus_stop",
      "type": "narrative",
      "min_day": 1,
      "max_day": 5,
      "risk": false,
      "choices": [
        {
          "text": "Текст выбора",
          "track": "connect",
          "state_change": 1,
          "archetype_shift": {"healer": 1.0},
          "photo_variant": {
            "perception_type": "PEOPLE",
            "flavor_text": "Подпись к фото"
          }
        }
      ]
    }
  ]
}
```

---

## 🎯 РАСШИРЕНИЕ

### Добавить мини-игру

1. Создайте сцену в `scenes/minigames/`
2. Добавьте скрипт с методами:
   - `setup(context, difficulty)`
   - `cleanup()`
3. Зарегистрируйте в `MinigameManager`

### Добавить архетип

1. Добавьте запись в `data/archetypes/archetypes_config.json`
2. Обновите `GameState.archetypes`
3. Добавьте тексты для нового архетипа

### Добавить локацию

1. Создайте фон в `assets/sprites/locations/`
2. Настройте `ParallaxBackground` для новой локации
3. Укажите `location` в событиях

---

## 💡 ЛУЧШИЕ ПРАКТИКИ

1. **Все данные в JSON** — легко балансировать без перекомпиляции
2. **Сигналы для связи** — системы не зависят друг от друга напрямую
3. **Комментарии в коде** — каждый метод описан
4. **Плейсхолдеры** — замените спрайты на свои в `assets/`
5. **Расширяемость** — новые события/архетипы добавляются через данные

---

## 🚀 СЛЕДУЮЩИЕ ШАГИ

1. ✅ Создать основную сцену `Main.tscn`
2. ✅ Настроить Autoload в Project Settings
3. ✅ Добавить плейсхолдер-спрайты
4. ✅ Протестировать полный цикл дня
5. ✅ Добавить 20+ событий
6. ✅ Создать мини-игры (Lockpick, Rhythm, Focus)
7. ✅ Добавить аудио и визуальные эффекты

---

## 📞 ПОДДЕРЖКА

Все скрипты имеют подробные комментарии на русском языке.
Для вопросов смотрите документацию в начале каждого файла `.gd`.
