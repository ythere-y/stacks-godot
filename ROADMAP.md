# Stacks Godot - Development Roadmap

This document tracks implemented features and planned improvements for the *Stacklands*-inspired card game loop.

## ✅ Completed Features
- **Core Architecture**
	- Linked List Data Structure (`card_below` / `card_above`) for handling stacks.
	- Resource-based Card Definitions (`CardLibrary`).
	- Recursive scene tree reordering (ensures Z-Index and Input priority match visuals).
- **Interaction**
	- **Smart Drag & Drop**: recursive "Snake" trail effect for child cards.
	- **Robust Hover**: Global `hover_candidates` list to solve Z-fighting/overlap selection issues.
	- **Sorting**: Double-click a stack to auto-sort by Card ID.
	- **Splitting**: Right-click drag to extract a single card from the middle of a stack.
- **Visuals & Polish**
	- **Poker Style Design**: Rectangular cards with Title Bar, Icon, and Label.
	- **UI Styling**: `StyleBoxFlat` with rounded corners (12px) and drop shadows.
	- **Physics Inertia**: Cards have momentum and friction when thrown/released.

---

## 🚀 Planned Features (Future Ideas)

### 1. Physics & Board Feel (Juiciness)
> *Refining how the cards feel to move and interact.*

- **Soft Collision / Separation (互斥力场)**
	- **Goal**: Prevent non-stacked cards from overlapping messily on top of each other.
	- **Implementation**: Add a small repulsion force (Steering Behavior) between cards that are *not* connected in a stack. If you drop a card near another, they should gently slide apart to sit side-by-side.

- **Dynamic Tilt (拖拽倾斜)**
	- **Goal**: Make cards feel like physical objects with air resistance.
	- **Implementation**: Rotate the card container slightly based on `velocity.x` during dragging. (e.g., dragging left tilts the card right).

- **Snap-to-Grid (网格吸附)**
	- **Goal**: Allow for tidy board organization.
	- **Implementation**: When dropping a card on valid "Ground" (not on another stack), snap its final `target_position` to the nearest 50px or 100px grid point.

### 2. Camera & Board Management
> *Expanding the play area.*

- **Infinite Canvas (Camera2D)**
	- **Goal**: The game currently relies on window size. Real gameplay needs a larger space.
	- **Implementation**: Add a `Camera2D` node.
		- **Pan**: Middle Mouse Button or Right Mouse Drag to move camera.
		- **Zoom**: Mouse Wheel to zoom in/out.

- **Screen Bounds / Edge Bounce**
	- **Goal**: Prevent cards from being thrown off-screen effectively.
	- **Implementation**: Currently implemented simply. Could be visualized with a "wall" bounce effect or infinite wrapping.

### 3. Gameplay Mechanics (The "Game" Part)
- **Production Logic (Timer System)**
	- **Goal**: The core mechanic of Stacklands.
	- **Implementation**: If valid Combo (e.g. `Villager` on `Berry Bush`), start a generic Timer on the `Villager`. When finished, spawn `Berry` card nearby.

- **Consumption / Feeding**
	- **Goal**: Survival pressure.
	- **Implementation**: End-of-day timer that requires consuming Food cards.

- **Card Spawning Animations**
	- **Goal**: Visual feedback for rewards.
	- **Implementation**: Cards should "pop" out of booster packs or production outputs with a juicy scale/bounce animation.

---
*Last Updated: 2026-02-09*
