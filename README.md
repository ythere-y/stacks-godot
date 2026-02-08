# Stacklands Clone - Godot Project Setup

This project is a starting point for a game like *Stacklands*, created with Godot 4 structure in mind.

## 📂 Project Structure

- **`cards/`**: Core card logic.
  - `card.gd`: The script handling drag-and-drop, stacking, and interaction.
  - `card_data.gd`: A custom Resource Definition for creating different card types (Villagers, Berry Bushes, etc.).
- **`board/`**: The game board.
  - `board.gd`: Manages the main game loop and spawning cards.
- **`global/`**: Autoloads.
  - `game_manager.gd`: Handles global state like Days, Gold, etc.
- **`ui/`**: User interface elements (HUD, Menus).
- **`assets/`**: Place your sprites, fonts, and sounds here.

## 🚀 Getting Started (Editor Setup)

Since script files are created but Scene (`.tscn`) files are binary/complex, follow these quick steps to link them in the Godot Editor:

### 1. Create the Card Scene
1.  Create a new **2D Scene**.
2.  Change the root node type to **Area2D** and name it `Card`.
3.  Attach the script `res://cards/card.gd` to the root node.
4.  Add a **Sprite2D** child node (use `icon.svg` as a placeholder texture).
5.  Add a **CollisionShape2D** child node. Give it a **RectangleShape2D** and size it to cover the sprite (approx 64x64 or similar).
6.  Add a **Label** child node (for the card name).
7.  **IMPORTANT:** Drag your `Sprite2D`, `CollisionShape2D`, and `Label` nodes into the script variables in the Inspector (under the "Card" script properties) or ensure the node names match the `@onready` paths in the code.
8.  Save this scene as `res://cards/card.tscn`.

### 2. Create Card Data
1.  In the FileSystem dock, right-click `cards/` -> **New Resource**.
2.  Search for **CardData**.
3.  Create a few resources (e.g., `villager.tres`, `berry.tres`) and fill in their names and icons.

### 3. Create the Game Board
1.  Create a new **2D Scene**.
2.  Name the root node `GameBoard`.
3.  Attach the script `res://board/board.gd`.
4.  Add a **Node2D** child and name it `CardsContainer`.
5.  In the Inspector for `GameBoard`, assign your `card.tscn` to the **Card Scene** property.
6.  Save as `res://board/game_board.tscn`.
7.  Run the scene (F6)!

## 🛠 Next Steps (Implementation Ideas)

- **Stacking Logic (`card.gd`)**: Currently, it detects overlap. You need to implement the "Timer" logic. When a specific combination stacks (e.g., Villager + Berry Bush), start a timer on the top card.
- **Recipes**: Create a `RecipeData` resource that defines Inputs (Villager + Berry Bush) -> Outputs (Berry + Villager).
- **Grid/Chaos**: Decide if you want cards to snap to a grid or be free-floating (current implementation is free-floating).
