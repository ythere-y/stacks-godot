# Stacklands Clone - Godot 4 Framework

This project is a technical implementation of the core Stacklands card mechanics in Godot 4. It provides a robust foundation for building card-based survival or management games.

## 🎯 Project Goal

To provide a high-quality, bug-free implementation of complex card interactions (stacking, splitting, dragging, z-sorting) that developers can use as a starting point.

## 📂 Project Structure

- **`addons/`**: Custom editor plugins (if needed).
- **`assets/`**: Sprites, fonts, sounds.
- **`configs/`**: Gamesettings here
- **`core/`**: Core systems and utilities.
  - **`data_type/`**: Custom Resource definitions (e.g., `CardData`, `RecipeData`).
- **`data/`**: JSON or CSV files for card definitions, recipes, etc.
- **`resources/`**: translations.
- **`scenes/`**: Scenes.
  - **`board/`**: The main game board.
  - **`card/`**: Card scenes and scripts.
  - **`stack/`**: Card stack scene and script.
    - **`components/`**: Modular components for layout, dragging, etc. 
  - **`ui/`**: User interface elements (HUD, Menus).

- **`scripts/`**: python scripts for better prompting AI.


---

## 🛤️ Development Roadmap

This document tracks implemented features and planned improvements for the *Stacklands*-inspired card game loop.

### ✅ Completed Features

- [x] **Core Architecture**
  - [x] Resource-based Card Definitions (`CardLibrary`).
  - [x] Build framework for `Board`, `Stack`, and `Card` three level hierarchy.
  - [x] **Modular Components**: Use four components in stack for better and flexible arrangement.
  - [x] **Event System**: Custom signals for card/stack events (e.g., `stack_changed`, `card_dragged`).
  - [ ] **Global Game time**
  - [ ] **Daily Cycle**
  - [ ] **Auto Feed and Starve System**: Cards that aren't fed by the end of the day will die.
- [ ] **Basic Card**
  - [x] **Card highlight**: Cards visually highlight when hovered.
  - [x] **Card die**: Cards can die
  - [ ] **Animations**:
    - [ ] **Die**
    - [ ] **Take damage**
- [ ] **Basic Stack**
  - [x] **Stack Highlight**: Stacks highlight when a card is dragged over them.
  - [x] **Stack Collision**
  - [x] **Stack Sorting**
- [ ] **Production Logic**
  - [x] **Basic production**: Timer-based production when valid card combinations are stacked.
  - [ ] **producted card auto-snap**: Produced cards should automatically snap to the closest same-type stack or create a new stack if none nearby.
  - [ ] **Spawn Animations**: Cards should "pop" out of booster packs or production outputs with a juicy scale/bounce animation.
  - [ ] **Recipe System**: Data-driven recipes for valid card combinations and their outputs.
- [x] **Interaction**
  - [ ] **Hover**
    - [x] **Robust Hover**: Use physics processing to detect hover.
    - [ ] **Showing-Details-on-Hover**: Show card details in a tooltip or side panel when hovering.
  - [ ] **Drag & Drop**
    - [x] **Splitting**: Right-click drag to extract a single card from the middle of a stack.
    - [x] Left click to drag a stack, and right click to drag a single card from the stack.
    - [ ] Smart recursive "Snake" trail effect for child cards.
    - [ ] **Dynamic Tilt**: Cards tilt slightly based on drag direction for a more physical feel.
  - [x] **Sorting**: Double-click a stack to auto-sort by Card ID.
  - [ ] **Physics**:
    - [x] **Soft Collision**: Based on Stack components.
    - [ ] **Inertia & Friction**: Cards have momentum when thrown and slow down over time. 
- [x] **Visuals & Polish**
  - [ ] **Poker Style Design**: Rectangular cards with Title Bar, Icon, and Label.
  - [ ] **UI Styling**: `StyleBoxFlat` with rounded corners (12px) and drop shadows.
  - [ ] **Physics Inertia**: Cards have momentum and friction when thrown/released.
  - [ ] **Screen Bounds**: Simple containment with bounce effect to keep cards on screen.
  - [ ] **Snap-to-Grid**: Cards snap to a 50px grid when dropped on the board.
- [ ] **Camera**
  - [x] **Basic Camera**: Based on phantom camera node.
  - [x] **Zoom**
  - [ ] **Panning**: Click and drag on empty space to pan the camera around the board.
  - [ ] **Move by keyboard**: WASD or arrow keys to nudge the camera.
  
### 🚀 Planned Features (Future Ideas)


---
