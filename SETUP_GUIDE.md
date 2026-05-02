# 🎮 PASSING THROUGH — РУКОВОДСТВО ПО ЗАПУСКУ

## ✅ ЧТО УЖЕ СОЗДАНО

### Скрипты (scripts/)
```
scripts/global/
├── game_state.gd      # Глобальное состояние (треки, архетипы, фото)
└── game_manager.gd    # Главный контроллер (утро→путь→событие→вечер→ночь)

scripts/systems/
├── event_manager.gd   # Загрузка событий из JSON, эхо-система
├── memory_system.gd   # Фото-система, выбор памяти
└── minigame_manager.gd # Мини-игры (Lockpick, Rhythm, Focus)

scripts/entities/
└── player_controller.gd  # Движение игрока, ускорение, параллакс

scripts/ui/
└── ui_controller.gd   # HUD, диалоги, выбор фото

scripts/utils/
└── parallax_background.gd  # Параллакс-фон для путешествий
```

### Данные (data/)
```
data/events/
└── sample_events.json    # 5 примеров событий с выборами

data/archetypes/
└── archetypes_config.json # 7 архетипов (euphoric, cynic, и т.д.)
```

### Сцены (scenes/)
```
scenes/main.tscn          # Главная сцена игры
scenes/main/main.gd       # Скрипт точки входа
```

### Конфигурация
```
project.godot             # Настройки проекта + Autoload
icon.svg                  # Иконка проекта
```

---

## 🚀 КАК ЗАПУСТИТЬ В GODOT 4.6.2

### Шаг 1: Откройте проект
1. Запустите **Godot 4.6.2**
2. Нажмите **"Import"** (или "Импортировать")
3. Выберите файл `/workspace/project.godot`
4. Нажмите **"Import & Edit"**

### Шаг 2: Проверьте Autoload
Autoload уже настроен в `project.godot`! Проверьте:
1. **Project** → **Project Settings** (Ctrl+,)
2. Перейдите на вкладку **Application** → **Autoload**
3. Убедитесь, что там есть:
   - `GameState` → `res://scripts/global/game_state.gd`
   - `GameManager` → `res://scripts/global/game_manager.gd`
   - `EventManager` → `res://scripts/systems/event_manager.gd`
   - `MemorySystem` → `res://scripts/systems/memory_system.gd`
   - `MinigameManager` → `res://scripts/systems/minigame_manager.gd`

✅ Если всё есть — переходите к шагу 3.  
❌ Если пусто — закройте редактор, файл `project.godot` обновится автоматически при следующем открытии.

### Шаг 3: Добавьте плейсхолдеры (ОБЯЗАТЕЛЬНО!)
В папке `assets/sprites/` уже созданы пустые файлы. Вам нужно заменить их на реальные изображения:

**Минимальные требования:**
1. `player_placeholder.png` — синий прямоугольник 50x80 пикселей
2. `bg_far_placeholder.png` — серый фон 1920x540 (дальний план)
3. `bg_mid_placeholder.png` — серый фон 1920x540 (средний план)
4. `bg_near_placeholder.png` — серый фон 1920x540 (ближний план)

**Как сделать быстро (в любом графическом редакторе):**
- Создайте цветные прямоугольники нужного размера
- Сохраните как PNG
- Положите в `assets/sprites/` с указанными именами

**Или используйте Godot:**
1. Откройте Godot
2. Правой кнопкой на `assets/sprites/` → **New Resource** → **Image**
3. Создайте цветные прямоугольники через **File** → **Export As**

### Шаг 4: Запустите игру
1. В Godot выберите сцену `scenes/main.tscn` (дважды кликните)
2. Нажмите **F5** или кнопку ▶️ (Play)
3. Игра запустится!

---

## 🎯 КАК ЭТО РАБОТАЕТ

### Игровой цикл
```
MENU → MORNING (выбор направления) 
     → TRAVEL (параллакс-движение) 
     → EVENT (событие с выбором) 
     → EVENING (выбор фото) 
     → NIGHT (рефлексия + эхо)
     → повторять 15 дней → FINAL
```

### Ключевые механики
1. **Треки** (action/observe/connect) — что игрок делает
2. **Архетипы** (7 типов) — как игрок интерпретирует мир
3. **Состояние** (-2 до +2) — влияет на доступные выборы
4. **Фото** — 2-3 кадра за день → 1 остаётся в памяти
5. **Эхо** — пропущенные события возвращаются позже

---

## 📝 КАК РАСШИРЯТЬ

### Добавить новое событие
Откройте `data/events/sample_events.json` и добавьте:
```json
{
  "id": "new_event_1",
  "title": "Название события",
  "description": "Описание...",
  "choices": [
    {
      "text": "Вариант 1",
      "track": "action",
      "state_change": 1,
      "archetype_shift": {"euphoric": 0.5}
    }
  ],
  "min_day": 1,
  "max_day": 15
}
```

### Добавить новый архетип
1. Откройте `data/archetypes/archetypes_config.json`
2. Добавьте запись в объект `archetypes`
3. Обновите `game_state.gd` (строка 46-54)

### Создать мини-игру
1. Создайте сцену мини-игры в `scenes/minigames/`
2. Добавьте скрипт с методами `setup()`, `cleanup()`
3. В `MinigameManager` укажите ссылку на сцену

---

## 🛠 ОТЛАДКА

### Ошибки при запуске
- **"Script not found"** — проверьте пути в scene-файлах
- **"Autoload not available"** — убедитесь, что Autoload включён
- **"Texture is empty"** — добавьте плейсхолдеры в `assets/sprites/`

### Логи
Все системы выводят логи в консоль Godot:
```
[GameState] Initialized
[GameManager] Starting new game
[EventManager] Loaded 5 events
...
```

---

## 📁 СТРУКТУРА ПРОЕКТА

```
/workspace/
├── project.godot           # ⭐ Главный файл проекта
├── icon.svg
├── README.md               # Это руководство
│
├── scenes/
│   ├── main.tscn           # ⭐ Главная сцена
│   ├── main/
│   │   └── main.gd         # Точка входа
│   ├── gameplay/           # Сцены геймплея
│   ├── minigames/          # Мини-игры
│   └── ui/                 # UI сцены
│
├── scripts/
│   ├── global/             # Синглтоны (autoload)
│   ├── systems/            # Системы игры
│   ├── entities/           # Игрок, NPC
│   ├── ui/                 # UI контроллеры
│   └── utils/              # Утилиты
│
├── data/
│   ├── events/             # JSON события
│   └── archetypes/         # JSON архетипы
│
└── assets/
    └── sprites/            # ⭐ Плейсхолдеры (добавить!)
```

---

## 🎨 СЛЕДУЮЩИЕ ШАГИ

1. **Добавьте плейсхолдеры** в `assets/sprites/`
2. **Запустите проект** в Godot
3. **Протестируйте** полный цикл дня
4. **Добавьте события** через JSON
5. **Настройте баланс** (треки, архетипы, состояние)

---

## 💡 СОВЕТЫ

- Все скрипты имеют **подробные комментарии на русском**
- Архитектура **модульная** — легко добавлять новое
- Используйте **сигналы** для связи между системами
- **JSON данные** можно менять без перекомпиляции

**Удачи в разработке! 🚀**
