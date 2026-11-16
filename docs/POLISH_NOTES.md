# Vitruvian Shadow: polish notes

What needs to change for this to look, feel and read like a well-made indie game. The audit was done at commit `4005b21`. The design system that goes with these notes, with tokens, components and the redesigned Combat and Chronicle screens, is here: https://claude.ai/artifact/PrEq8RuDYEPP1EiKBsvsdd

Items are ordered by impact within each section. **[bug]** means the game currently does something wrong.

---

## 1. Fix first: things that are broken or lie to the player

1. **[bug] Skill damage shown ≠ damage dealt.** The skills drawer prints `minDamage–maxDamage` (`combat_screen.dart` ~L966), but `calculateCombatHit` (`combat_state.dart:381`) never reads those fields. Either use them in the formula or show the computed range for the selected target.
2. **[bug] Status effects are detected by string matching.** `skill.effectDescription.toLowerCase().contains('bleed')` (`combat_state.dart:439`). "+4 Bleed" applies 2. "Burn Effect" (Hermetic Firebolt) does nothing because burn doesn't exist. Give `CombatSkill` a typed `List<StatusApplication>` (kind, stacks, duration) and drive everything from it.
3. **[bug] Settings do nothing.** Nothing reads `screenShake`, `masterVolume` or `textSpeed`. The combat shake always fires. `cloudSync` is a fake toggle, and `wipeSaveData` only resets settings. Wire each setting up or hide it.
4. **[bug] No save system.** Closing the app loses everything. Add `shared_preferences` or `hive` and serialise `PlayerState`, `InventoryState`, `StoryEngine.visitedNodeIds`/`claimedLootNodeIds` and `NavigationState` unlocks. Autosave on every node change and after combat.
5. **[bug] Wrong art.** `enemy_werewolf_silver.png` is byte-identical to `class_warrior.jpg`, so the Alpha Werewolf and the Iron Golem ally render as a Spartan. `enemy_werewolf_orange.png` is a black wolf. `app_icon.png` and the silver wolf are JPEGs with `.png` names.
6. **[bug] The turn loop can race.** Turns chain through `Future.delayed` with no cancellation (`endPlayerTurn`, `rollInitiativeAndStartRound`, `executeEnemyTurnSequence`). If you flee mid-sequence or start a new combat, old futures keep running and mutate state. Replace them with a single turn-queue coroutine that owns a cancel token (or a `CombatPhase` state machine) and await each action.
7. **[bug] Victory and defeat show twice.** `checkVictoryOrDefeat` shows a `Get.snackbar` *and* the screen shows its overlay. It can also fire repeatedly because it runs after every action. Make the result a single transition into a `CombatPhase.result` state.
8. **[bug] Defeat leaves you at 1 HP with no consequence**, and victory always gives a flat 50 XP. Make defeat cost something (lose sanity, drop unequipped loot, respawn at the last shrine) and scale XP by encounter.
9. **Generated-text errors on `world_map.jpg`.** "Isle of Skulls" appears twice, once as "Isle of Skuils"; there's also "Lerical Indian" and "Kingdoms" ×4. Players will screenshot this. Retouch the labels or redraw the map.
10. **Name drift.** The repo/package is `ouroboros`, the app title is "Vitruvian Shadow RPG", and the README is the Flutter template. Pick one name and update `pubspec.yaml` `description`, the README, and the Android/iOS display names.

## 2. Code structure: what "well coded" means here

- **Tokens, not literals.** There are about 300 `Color(0x…)` literals (combat_screen alone has 95), 12 font sizes, and `0xFFC89B5D` (the real accent, used 50×) isn't in `colors.dart`. Port the design system's `tokens.json` into a `ThemeExtension<VsTokens>` (colors, spacing, durations) and ban raw `Color(0x…)` in `lib/ui` with a custom lint or a grep in CI.
- **Split `combat_screen.dart` (1,605 lines) and `combat_state.dart` (1,192 lines).** Suggested layout:
  - `combat/engine/`: pure Dart, no GetX: `CombatEngine`, `DamageCalculator`, `StatusSystem`, `AiPlanner`, `TurnQueue`. Returns `List<CombatEvent>`.
  - `combat/controller.dart`: GetX controller that feeds engine events to the UI with timing.
  - `combat/widgets/`: `CombatantCard`, `VitalBar`, `ApPips`, `SkillHand`, `TurnBanner`, `DamageNumberLayer`.
- **Event-driven presentation.** Right now the engine mutates `RxInt`s and the UI guesses what happened (`attackEventId++`, `lastHitEnemyId`). Make the engine emit typed events (`Moved`, `Attacked{hit,crit,glance}`, `StatusTicked`, `Died`, `TurnStarted`), and have the UI play them one at a time. This is the single biggest step toward good game feel: animation, sound and log text all hang off the same event.
- **One `Combatant` model.** Player, ally and enemy all have bleed/poison/HP/AP logic, copy-pasted three times. The player is a pile of loose `playerX.obs` fields. Make the player an `ActiveCombatant` too, with `team: Team.player|ally|enemy`.
- **Typed enums instead of strings:** `Lane.front/back`, not `'front'`/`'back'`; consumables keyed by `ItemEffect` instead of `if (item.id == 'c1')`.
- **Data out of widgets.** The talent tree lives inside `talents_screen.dart` `initState`; heroes are hard-coded in the `PlayerState` constructor. Move both to `assets/data/*.json` next to the bestiary, and validate all JSON at startup in debug builds (missing `bestiary_id`, broken `nextNodeId`).
- **Seeded RNG.** Inject `Random` into the engine (seed per combat). This gives reproducible bug reports, replays, and testable crits/glances.
- **Dead code.** `CityGame` and every Flame component are never mounted, and they call `Get.find` inside `update`/`render` every frame. Either delete Flame and drop the dependency, or use it for the battlefield (see §4). `TalentNode` model is unused. The `isDead` branch in `_buildLaneRow` is unreachable.
- **Tests.** You have damage-math tests, which is good. Add engine tests for turn order, status ticking, AI choice under seed, and a golden test per key widget.
- **Asset hygiene.** Images are 240–930 KB each at 1024px. Export at 2× display size as WebP, keep source PSDs out of the bundle, and add `precacheImage` for the encounter's portraits before combat starts.

## 3. Look: from "Flutter app in dark mode" to "manuscript"

- **Replace Material Icons everywhere** (`Icons.flash_on`, `Icons.ads_click`, `Icons.dangerous`, `Icons.heart_broken`…). They're the strongest "this is an app" tell. Commission or draw one engraved sigil set (about 40 glyphs: actions, statuses, slots, nav) and ship it as an icon font or SVGs via `flutter_svg`.
- **Kill the leftover Material defaults:** `LinearProgressIndicator` → `VitalBar`, `BottomNavigationBar` → a custom ink tab bar, `CircularProgressIndicator` → an ink-blot or ouroboros loader, `Get.snackbar` → in-world parchment slips or overlays, `Colors.red/white24/cyanAccent/grey` → tokens.
- **Texture.** Add a very subtle paper-grain/noise overlay (5–8% opacity, one tiled PNG) on `ground` and a vignette at the screen edges. It costs almost nothing and the void stops looking like `#050505`.
- **Plate marks and rules.** Use a dotted rule (`DottedHairline` already exists) between ledger rows, and add engraver's corner ticks on the one hero panel per screen.
- **Typography.** Bundle the fonts as assets instead of fetching them with `google_fonts` at runtime: no network on first launch, no font pop-in. Raise every 8–9px text to 10–11px minimum. Use tabular figures for numbers.
- **Combat takes over the screen.** Hide the bottom nav during a fight; Flee lives behind an icon with a confirm.
- **Name the tabs after the fiction:** You / Chronicle / Ledger instead of You / Game / Settings.
- **Sanity should be visible.** The PRD describes sanity glitches; right now sanity is a number on the stats screen. Below 40: ink-bleed vignette, occasional letters in prose swapping or smearing, whispers in the log. Below 20: UI hairlines wobble and choices sometimes show a false option.

## 4. Feel: animation and juice

Order of operations for every attack (all timings from the `duration` tokens):

1. **Anticipation**: the attacker card leans 6–10px toward the target (120ms, ease-in).
2. **Impact**: hit-stop of 60–80ms (freeze both cards), `wound` flash over the target art, damage number pops with an overshoot scale.
3. **Reaction**: target knocked back 3–6px with a small rotation; screen shake only on crits and only if enabled (2–4px, 120ms, decaying, never horizontal-only like the current one).
4. **Settle**: HP fill drops instantly, then a pale **lag bar** drains after it over 600ms.

More juice, in order of value:

- **Turn pacing.** The 2-second default `attackDelay` is the main reason combat feels slow. Use ~450ms between enemy actions, let tapping skip to the end of the sequence, and add a 2× speed toggle.
- **Damage numbers** stack and drift (one per hit, offset), not one-per-target in a `Map` that overwrites (`damagePopups`). Crits are bigger and `parchment`; glancing blows are small and grey with "GRAZE".
- **Deaths.** Enemies dissolve into ink particles (shader or simple particle burst) and their card collapses out of the lane. Don't leave a blank slot.
- **Lane moves** slide the card between rows (`dur-move`, ease-snap) instead of re-rendering in place.
- **Skill cast**: the card lifts from the hand, flies to the target, and a short glyph flare plays. Replace the text banner.
- **Status ticks** pulse the sigil and float a small coloured number at turn start.
- **Chronicle**: paragraphs ink in line by line (respecting Text Speed; tap to complete). Page-turn or ink-wipe transition between nodes. The choice you tap flashes brass before the transition.
- **Loot**: the seal turns, the item flies to the You tab, and the tab gets a gold badge.
- **Haptics**: `HapticFeedback.lightImpact` on select, `mediumImpact` on hit taken, `heavyImpact` on crit and death. Gate it behind a setting.
- **Audio**: there is none, and nothing reads `masterVolume`. Add `flame_audio` or `just_audio` with an ambient bed per location, 3–4 hit variants with pitch randomisation, UI quill scratches for choices, and a heartbeat under 25% HP. Sound is about half of what makes a hit feel like a hit.
- **Reduced motion**: respect `MediaQuery.disableAnimations` and the Screen Shake setting. Keep flashes and numbers, drop shake and knockback.

## 5. Mechanics: depth for the systems you already have

- **Telegraph enemy intent.** Show each enemy's planned action and damage for its next turn (the AI already scores actions; plan at turn start and display it). This turns the lane system from guessing into decisions.
- **Show the initiative order** (speed already drives it) as a ribbon of portraits in the turn banner.
- **Make lanes matter more.** Today front = more melee damage and back = 0.8× when hitting the front. Add: front line *protects* back line from melee (enemies must kill or push through the front); back line gets +evasion against ranged; a "push/pull" skill family that moves enemies between lanes.
- **AP + stamina overlap.** Both gate the same actions. Make AP the tempo (how many things per turn) and stamina the intensity (heavy versions of skills cost more stamina and do more). Defend/Brace converts AP into stamina; that gives players a real choice.
- **Statuses from features.md**, implemented as data: bleed (ticks, stacks decay), poison (ticks, doesn't decay, reduces healing), burn (big tick, spreads to the same lane), stun (lose next AP), frost (−speed, shatter bonus on crit), guard. Each needs a sigil, a tooltip and a counterplay item.
- **Sanity as a combat resource.** Some powerful skills cost sanity; low sanity unlocks "madness" skills but makes choices in the Chronicle unreliable. This ties the narrative and combat halves together, which is the hook the PRD sets up.
- **Attribute gates should be visible before you tap**, showing pass or fail, and some should be *rolls* (STR 12 vs d20 + STR mod) with a shown chance, so they create tension.
- **Encounter rewards**: give each encounter a loot table in JSON. Make XP scale with enemy level, and give a bonus for no damage taken or for finishing within N turns.
- **Talents** should be per class and read from data, with real stat effects applied to `CombatEngine`. Right now they're display-only.
- **Two heroes are in the roster but only one fights.** Either let the ally slot be your second hero (party of 2 with real control), or remove the roster switcher.

## 6. Widgets to build (Flutter)

Each one maps to a component in the design system:

| Widget | Replaces | Notes |
|---|---|---|
| `EtchedPanel` | `EtchedContainer` | add `plate: true` corner ticks variant |
| `VitalBar` | `LinearProgressIndicator` ×6 | fill + lag layer (`TweenAnimationBuilder` with delayed second tween), 10% ruled ticks |
| `ApPips` | AP boxes | diamond pips, `preview` count pulses |
| `CombatantCard` | 3 copies of card code in combat_screen | one widget for player/ally/enemy; intent badge, sigil column, selected/hit/out-of-range/dead states |
| `StatusSigil` | text popups "+2 BLEED" | glyph + stack count, long-press tooltip |
| `SkillHand` / `SkillCard` | bottom-sheet skill list | always-visible 4-card hand, hold to preview, drag or tap target to cast |
| `TurnBanner` | `_buildHeader` | includes initiative ribbon |
| `DamageNumberLayer` | `damagePopups` map | overlay that queues and offsets numbers per event |
| `ChoiceButton` | `_ChoiceButton` | numeral, gate chip with pass/fail, combat variant |
| `LootCallout` | `_LootCalloutWidget` | claim ceremony |
| `InkText` | plain `Text` in Chronicle | line-by-line reveal at Text Speed |
| `ResultPage` | snackbars + overlays | single victory/defeat page with XP tally animation and loot list |

## 7. Card art and assets

**House style (done):** hand-coloured antique engraving, fine ink hatching with watercolour washes. All world art was regenerated in this style; figures are cut out onto black and backgrounds are darkened for text. `vitruvian.jpg` and `skull.jpg` stay monochrome as the anatomy plates. Details and prompts: `docs/ART_BRIEF.md`.

**Card anatomy** (combatant and skill cards share it):

- **Frame**: 1px hairline with corner plate ticks; the colour of the frame says the team (sepia = you, lapis = ally, rust = enemy). Use the frame, not a background tint.
- **Art window**: head-and-shoulders crop, consistent eye line at ~30% from the top, light coming from top-left on every piece, and a transparent background so the vignette works.
- **Name strip** in the display face; **data strip** in mono.
- **Corners**: top-left statuses, top-right intent, bottom pointer when selected.

**Production specs:**

- Portraits: 512×640 source, PNG with alpha, exported as WebP at 2×. One layer for figure, one for a rim light (lets you animate a subtle idle "breathing" scale of 1.0–1.015 on the figure only).
- Each enemy needs 3 frames minimum: idle, attack lean, hurt. The hurt frame alone makes hits feel far better than a red overlay.
- Skill card art: 1:1 engraved glyph plates (256×256), one per skill, in the same line weight as the sigils.
- Item art: 128×128 engraved objects on transparent, for the inventory ledger and the Vitruvian equipment slots.
- Location plates: 1080×360 engraved scenes for Chronicle headers. Reuse one per area rather than per node.
- Maps: retouch `world_map.jpg` labels; render the tactical map in the Vellum theme with hand-drawn routes (`_WorldRoutePainter` already exists; give it a dashed, slightly wobbly ink stroke).
- Animated details that are cheap and high-value: a flickering candle in the chronicle header corner, drifting dust motes on the battlefield (Flame particles, or a `CustomPainter` with 20 points), and ink blots that spread on crits.
- UI sounds and music: quill scratch, page turn, dull bone thud, metallic ring for crits, low choir drone for ambience. These are cheap from asset packs; hand-tune the volume levels.

**Bestiary art direction**: give each enemy family one silhouette idea that reads at 64px (Feral: hunched, all claws; Shadow: thin, half dissolved into smoke; Alpha: upright, scarred, one silver streak). Today all three wolves share a pose, so they're hard to tell apart at card size.

## 8. Suggested order of work

1. §1 bugs 1–7 (correct numbers, typed statuses, settings, saving, art fixes, turn queue).
2. Port tokens to a `ThemeExtension`, then build `CombatantCard`, `VitalBar`, `ApPips` and `SkillHand` and rebuild the combat screen from them.
3. Event-driven combat presentation plus the four-beat hit, lag bars, damage number layer and faster pacing.
4. Audio and haptics.
5. Enemy intent, initiative ribbon, statuses from data.
6. Art pass: one style, enemy hurt frames, sigil icon set.
7. Chronicle: ink-in text, plates, gate rolls, sanity effects.
