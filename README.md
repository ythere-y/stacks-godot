# Stacklands Clone - Godot 4 Framework

This project is a technical implementation of the core Stacklands card mechanics in Godot 4. It provides a robust foundation for building card-based survival or management games.

## 🎯 Project Goal

To provide a high-quality, bug-free implementation of complex card interactions (stacking, splitting, dragging, z-sorting) that developers can use as a starting point.

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


## 🛠 Next Steps (Implementation Ideas)

- **Stacking Logic (`card.gd`)**: Currently, it detects overlap. You need to implement the "Timer" logic. When a specific combination stacks (e.g., Villager + Berry Bush), start a timer on the top card.
- **Recipes**: Create a `RecipeData` resource that defines Inputs (Villager + Berry Bush) -> Outputs (Berry + Villager).
- **Grid/Chaos**: Decide if you want cards to snap to a grid or be free-floating (current implementation is free-floating).

---

## 🛤️ Development Roadmap

This document tracks implemented features and planned improvements for the *Stacklands*-inspired card game loop.

### ✅ Completed Features
- [x] **Core Architecture**
  - [x] Linked List Data Structure (`card_below` / `card_above`) for handling stacks.
  - [x] Resource-based Card Definitions (`CardLibrary`).
  - [x] Recursive scene tree reordering (ensures Z-Index and Input priority match visuals).
- [x] **Interaction**
  - [x] **Smart Drag & Drop**: recursive "Snake" trail effect for child cards.
  - [x] **Robust Hover**: Global `hover_candidates` list to solve Z-fighting/overlap selection issues.
  - [x] **Sorting**: Double-click a stack to auto-sort by Card ID.
  - [x] **Splitting**: Right-click drag to extract a single card from the middle of a stack.
- [x] **Visuals & Polish**
  - [x] **Poker Style Design**: Rectangular cards with Title Bar, Icon, and Label.
  - [x] **UI Styling**: `StyleBoxFlat` with rounded corners (12px) and drop shadows.
  - [x] **Physics Inertia**: Cards have momentum and friction when thrown/released.
  - [x] **Screen Bounds**: Simple containment with bounce effect to keep cards on screen.

### 🚀 Planned Features (Future Ideas)

#### 1. Physics & Board Feel (Juiciness)
> *Refining how the cards feel to move and interact.*

- [ ] **Soft Collision / Separation (互斥力场)**
  - **Goal**: Prevent non-stacked cards from overlapping messily on top of each other.
  - **Implementation**: Add a small repulsion force (Steering Behavior) between cards that are *not* connected in a stack. If you drop a card near another, they should gently slide apart to sit side-by-side.

- [ ] **Dynamic Tilt (拖拽倾斜)**
  - **Goal**: Make cards feel like physical objects with air resistance.
  - **Implementation**: Rotate the card container slightly based on `velocity.x` during dragging. (e.g., dragging left tilts the card right).

- [ ] **Snap-to-Grid (网格吸附)**
  - **Goal**: Allow for tidy board organization.
  - **Implementation**: When dropping a card on valid "Ground" (not on another stack), snap its final `target_position` to the nearest 50px or 100px grid point.

#### 2. Camera & Board Management
> *Expanding the play area.*

- [ ] **Infinite Canvas (Camera2D)**
  - **Goal**: The game currently relies on window size. Real gameplay needs a larger space.
  - **Implementation**: Add a `Camera2D` node.
	- **Pan**: Middle Mouse Button to move camera.
	- **Zoom**: Mouse Wheel to zoom in/out.
	- **Bounds**: Draw a simple background grid that extends infinitely in all directions.
  	- draw a rectangle boundary (e.g., 2000x2000) to indicate the "playable area".
  	- Cards can be moved anywhere within this area, but not outside of it.

#### 3. Gameplay Mechanics (The "Game" Part)
- [ ] **Production Logic (Timer System)**
  - **Goal**: The core mechanic of Stacklands.
  - **Implementation**: If valid Combo (e.g. `Villager` on `Berry Bush`), start a generic Timer on the `Villager`. When finished, spawn `Berry` card nearby.
    - Use a `RecipeData` resource to define valid combinations and their outputs.
    - Add `Villager` `Berry Bush` `Berry` card definitions to `CardLibrary`.
    - Add a state machine or status system to cards to track "Idle", "Producing", "Ready" states.

- [ ] **Consumption / Feeding**
  - **Goal**: Survival pressure.
  - **Implementation**: End-of-day timer that requires consuming Food cards.

- [ ] **Card Spawning Animations**
  - **Goal**: Visual feedback for rewards.
  - **Implementation**: Cards should "pop" out of booster packs or production outputs with a juicy scale/bounce animation.

---
