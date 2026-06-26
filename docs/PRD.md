# Project Vitruvian Shadow: Product Requirements Document

## 1. Product Overview
**Vitruvian Shadow** is a high-fidelity, choice-based mobile RPG that blends Renaissance-era anatomical science with grimdark fantasy. The interface is designed to be a diegetic artifact—a "living manuscript"—where player progression, inventory management, and world exploration are experienced through the lens of a clinical scribe or ancient anatomist.

**Target Audience:** 
- Narrative RPG enthusiasts (Inkle’s *Sorcery!*, *Eldrum*).
- Players who value "Hard RPG" mechanics and data-dense, atmospheric interfaces.
- Fans of grimdark aesthetics (*Darkest Dungeon*, *Elden Ring*).

---

## 2. Design Vision & Aesthetic
The visual language is defined by the **Vitruvian Shadow** design system, characterized by:
- **Palette:** Void Black (`#050505`), Aged Bone/Vellum (`#D4CFC7`), and Sepia/Burnt Umber (`#8B7355`) for active states. Rust/Dried Blood (`#662222`) is used for danger and critical feedback.
- **Typography:** Authoritative and scholarly serifs (e.g., *IM Fell English*, *EB Garamond*) paired with technical monospace fonts (*Fira Code*) for numeric data.
- **Visual Style:** 1px "etched" hairlines, razor-sharp 0px corner radiuses, and anatomical line art inspired by Leonardo da Vinci’s journals.

---

## 3. Core Gameplay Pillars

### A. The Anatomical Loadout (Persona)
Character progression is anchored by the **Vitruvian Diagram**. Unlike traditional inventories, gear is mapped directly to a highlighted anatomical schematic. 
- **Equipped View:** Centralized body-map with slots for Head, Chest, Leg, Main Hand, and Secondary Hand.
- **Personality Classes:** Initial classes include **Warrior**, **Sorcerer**, and **Assassin**, which influence starting stats and talent growth.
- **Progression Tracking:** Clinical ledger tracks Level and XP Progression.

### B. Branching Narrative (The Chronicle)
- Immersive, text-driven events where choices are gated by attributes (e.g., `[STR 12]`) or previous narrative outcomes.
- High-contrast typography with "ink-bleed" transitions between story beats.

### C. The Dual-Map Navigation System
1. **The Overworld (Bird's Eye):** A comprehensive, historical parchment map of the "Known World" for long-distance travel and territory identification.
2. **Game Navigation (Tactical):** A high-contrast, local topographical view showing "Current Presence" and highlighted traversal lines for immediate movement between nodes.

---

## 4. Screen Specifications

### 4.1. [You - Persona] (Equipped)
- **Purpose:** Visual gear management and class identification.
- **Key Elements:** High-contrast Vitruvian schematic (Head, Chest, Leg, Main Hand, Secondary Hand), status bars for Physical Integrity, Encumbrance tracking, and XP Progression.

### 4.2. [You - Stats]
- **Purpose:** Clinical ledger of the player's numeric capabilities.
- **Key Elements:** Vitals (HP, Mana, Stamina, Sanity), Core Attributes (STR, DEX, INT, CON), XP Tracker, and detailed Resistances.

### 4.3. [You - Inventory]
- **Purpose:** A dense, scrollable ledger of artifacts.
- **Key Elements:** Categorized tabs (Weapons, Apparel, Consumables), weight-based capacity limits, and rarity indicators.

### 4.4. [You - Talents]
- **Purpose:** Mutation and skill growth mapping.
- **Key Elements:** A "Growth Chart" styled as a clinical or celestial constellation map, where nodes represent bodily/mental enhancements.

### 4.5. [Game - Navigation Map]
- **Purpose:** Tactical local traversal.
- **Key Elements:** Lighter vellum background, highlighted "link-lines" for valid moves, and "Territory Intel" panel.

---

## 5. Technical Requirements (Frontend)
- **Stack:** HTML5, Tailwind CSS v3 (Utility-first for precise etched borders). *(Adapted to Flutter + Flame for native mobile RPG architecture).*
- **Interactions:** 
  - CSS transforms / Flutter animations for "pulsing" location markers.
  - Backdrop-blur effects for manuscript overlays.
  - Custom SVG/canvas line-art for anatomical and cartographic assets.
- **Responsive:** Mobile-first portrait orientation (fixed bottom navigation).

---

## 6. Future Roadmap
- **Combat Terminal:** A dedicated tactical interface for turn-based anatomical targeting.
- **Alchemy Lab:** A crafting screen for mixing "Essences" using botanical field-guide aesthetics.
- **Dynamic Sanity Effects:** Visual "glitches" and ink-splatters that appear on the UI as the player's Sanity stat depletes.
