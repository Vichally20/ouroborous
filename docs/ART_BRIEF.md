# Art brief and prompt sheet

Generated from `tools/art/manifest.json`. Edit the manifest, not this file.

## Keep

- **assets/images/vitruvian.jpg**: The style reference for everything else. Feed it to the generator as a style image.
- **assets/images/skull.jpg**: Second style reference: shows how bronze is allowed as a spot colour.
- **assets/images/app_icon.png**: Already on-style. Only fix: it is a JPEG named .png; re-export it as a real PNG and rerun flutter_launcher_icons.

## Delete

- **assets/images/hero_warrior.jpg**: not referenced anywhere in `lib/`.
- **enemy_werewolf_black.png, enemy_werewolf_orange.png, enemy_werewolf_silver.png, class_*.jpg, world_map.jpg, bowerstone_map.jpg**: once their replacements below are in and wired up.

Everything else is regenerated or new, because the existing pieces mix three styles (cel-shaded comic, glowing-outline digital, coloured fantasy map) and several are wrong or duplicated.

## House style

One look for every character, creature and place: **a hand-coloured antique engraving**, fine black-ink cross-hatching with watercolour washes, like a tinted plate from an old atlas or bestiary. Characters, creatures and items are cut out and set on void black so they sit on the UI ground; backgrounds keep their full colour, darkened to a candlelit key with the top and bottom fading to black for text. The pigment set:

| Wash | Use |
|---|---|
| Crimson | blood, cult robes, ritual light, the heart vessel |
| Ochre / gold | brass, bronze, armour, relics, torchlight |
| Verdigris | water, decay, fungi, poison |
| Lapis blue | magic, shadow, night sky, allies |
| Bone / umber | skin, stone, parchment, linework |

Maps are hand-coloured atlas engravings on cream paper, with no text: Flutter draws the labels. The monochrome bone-on-black look is still available with `--palette ink`.

### Generating with Amazon Bedrock (what works)

`tools/art/generate_bedrock.py` reads this manifest and writes finished files into `assets/`:

```bash
pip install boto3 pillow
python tools/art/generate_bedrock.py --priority P0 --dry-run
python tools/art/generate_bedrock.py --ids flesh_construct --candidates 3 --force
```

Tested on 2026-11-12 in us-west-2:

- **Colour (default, `--palette colour`)**: prompt for a *hand-coloured antique engraving* with the subject first and a short style tail; a long colour preamble makes the model ignore the subject (an Alpha Werewolf came out as a lizard). Figures go through Bedrock's remove-background model and are composited on `#050505`; scenes are darkened to 55% and faded at the top and bottom.
- **Monochrome (`--palette ink`)**: prompting for white-on-black engraving fails. Every model paints or photographs it instead. What works is asking for a classic **black-ink engraving on white paper** (style words first) and letting the script invert and tint it to bone `#D4CFC7` on void `#050505`.
- In `--palette ink`, backgrounds are not inverted: dense scene engravings turn mostly white when inverted. The script keeps them positive and tints them black ink on dim umber (`#5A4A3A` max), so bone UI text keeps about 5:1 contrast over them and characters (bone on black) stand out in front.
- The script trims an outer band of every image, because models like to add a printed-plate border with a fake caption.
- `--refinish` re-runs post-processing on saved raw images with no model calls; `--refinish --ids X --seed N` installs a different candidate.
- **Stable Image Ultra** (default) gives the best compositions. **SD3.5 Large** (`--model sd35`) is cheaper and close behind.
- **Style Guide** with `vitruvian.jpg` as a reference copies the reference's subject above fidelity ~0.3 and paints below it. Not recommended.
- In `--palette ink` the spot colours are lost in inversion; that is the main reason colour is now the default.
- Words like *museum print* or *plate* make the model add borders and fake captions; the script's negative prompt blocks them.

Raw outputs and seeds are kept in `tools/art/out/` (git-ignored) so a good result can be regenerated.

### Using another generator

The prompts below are written for any tool. For consistency across about 65 images:

1. **Use the style references.** Give `vitruvian.jpg` and `skull.jpg` to the generator as style images (Midjourney `--sref`, Firefly *Style reference*, SDXL IP-Adapter, Leonardo *Style Reference*). This does more than any wording.
2. **Paste the style sentence unchanged** at the start of every prompt (it's already included in each prompt below).
3. **Generate by batch, in priority order**, in one session with one seed per batch, and throw away anything that drifts toward colour or cartoon.
4. **No text in images, ever.** Generators misspell. Names on maps and signs are drawn by Flutter on top of the art.
5. **Post-process every file**: crush the background to `#050505` with Levels, desaturate everything except the bronze and crimson spot colours, and for portraits, mask the background to alpha (or keep pure black; the cards vignette into black anyway).
6. **Export**: WebP quality 82 for scenes and maps, PNG with alpha for portraits and items. Keep the 1024-wide masters outside `assets/`.

### Animation frames

P0 enemies list `hurt` and `attack` variants. Make them with image-to-image from the approved idle (strength ~0.45) so the creature stays the same. Three frames per enemy (idle, attack, hurt) is the cheapest upgrade to combat feel.

### Negative prompt (all assets)

```
full colour, saturated colours, cel shading, cartoon, anime, comic book, glowing outline, rim glow, neon, 3d render, photograph, smooth airbrushed digital painting, gradient sky, lens flare, text, letters, words, runes, labels, captions, numbers, watermark, signature, frame, border, multiple views, character sheet, cropped feet, blurry
```

## P0: ships in chapters 1–2 today

### Characters

#### `class_warrior` → `assets/images/portraits/class_warrior.png` (1024x1536, regenerate)

_Current art is cel-shaded comic style and also doubles as the Alpha Werewolf by mistake._

Used by: intro_screen.dart, persona_screen.dart, combat_screen.dart

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the Anatomical Warrior: a towering soldier of hypertrophic musculature, the armour on his left side cut away to reveal flayed muscle drawn like an écorché study, tarnished bronze half-plate and pauldron on the right, a massive blackiron two-handed claymore resting point-down, scarred shaved head, calm brutal stare. Framing: full-length figure standing in a three-quarter view, the whole body in frame with feet visible, head in the top fifth, isolated on a pure black background with generous black margin around the figure.
```

#### `class_sorcerer` → `assets/images/portraits/class_sorcerer.png` (1024x1536, regenerate)

_Current art is a cel-shaded paladin with a halo; it contradicts 'fragile skeletal frame'._

Used by: intro_screen.dart, persona_screen.dart, combat_screen.dart

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the Hermetic Sorcerer: a gaunt, frail elderly scholar-mage with a thin bearded face and sunken eyes, a bronze surgical calliper frame strapped around his head, tattered academic robes in lapis blue and ochre, thin fingers holding a bronze astrolabe, a ritual dagger at the belt, faint alchemical symbols inked on his bare forearms. Framing: full-length figure standing in a three-quarter view, the whole body in frame with feet visible, head in the top fifth, isolated on a pure black background with generous black margin around the figure.
```

#### `class_assassin` → `assets/images/portraits/class_assassin.png` (1024x1536, regenerate)

Used by: intro_screen.dart, persona_screen.dart, combat_screen.dart

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the Clinical Assassin: a lean hooded figure in a surgeon's leather apron, face wrapped in linen with two round bronze lenses over the eyes, arms bare and marked with precise ink diagrams of the veins, a long wide-bladed cinquedea held low, poised mid-step. Framing: full-length figure standing in a three-quarter view, the whole body in frame with feet visible, head in the top fifth, isolated on a pure black background with generous black margin around the figure.
```

#### `cultist_acolyte` → `assets/images/enemies/cultist_acolyte.png` (1024x1536, new)

_Currently reuses the black werewolf._

Used by: bestiary.json cultist_acolyte, combat_cultists_01, cistern_approach

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: one hooded cult priest filling the frame from head to feet: heavy monk robes dyed deep blood crimson, deep hood hiding the face except a thin chanting mouth, a coiled serpent emblem embroidered in gold on the chest, a curved knife in one hand and a shallow brass offering bowl in the other, the robe hem wet and dripping. Framing: full-length figure standing in a three-quarter view, the whole body in frame with feet visible, head in the top fifth, isolated on a pure black background with generous black margin around the figure.
```

- Variant hurt: same creature recoiling from a blow, head snapped back, one limb raised defensively, crimson spatter (generate image-to-image from the idle)
- Variant attack: same creature lunging forward toward the viewer (image-to-image from the idle)

#### `cultist_hierophant` → `assets/images/enemies/cultist_hierophant.png` (1024x1536, new)

_New character. Gives the cistern ritual a leader and a boss for a harder variant of combat_cultists_01._

Used by: new bestiary entry, cistern_approach (leader at the plinth)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the Ouroboros Hierophant, high priest of the cistern rite: taller than the acolytes, crimson robes layered with bronze-ringed vestments, a tall mitre shaped as a serpent swallowing its own tail, a veil of fine chain over the face, raising a glass vessel in which a human heart glows crimson, the other hand open in benediction. Framing: full-length figure standing in a three-quarter view, the whole body in frame with feet visible, head in the top fifth, isolated on a pure black background with generous black margin around the figure.
```

- Variant hurt: same creature recoiling from a blow, head snapped back, one limb raised defensively, crimson spatter (generate image-to-image from the idle)
- Variant attack: same creature lunging forward toward the viewer (image-to-image from the idle)

### Creatures

#### `werewolf_feral` → `assets/images/enemies/werewolf_feral.png` (1024x1536, regenerate)

_Current file 'enemy_werewolf_orange.png' is actually a black wolf._

Used by: bestiary.json werewolf_feral, combat_crypt_werewolves

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a werewolf, a monstrous half-man half-wolf standing hunched on two bent legs, a wolf head with snarling jaws, a muscular human torso covered in matted fur, long arms ending in huge clawed hands, ribs showing, blood on the muzzle. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

- Variant hurt: same creature recoiling from a blow, head snapped back, one limb raised defensively, crimson spatter (generate image-to-image from the idle)
- Variant attack: same creature lunging forward toward the viewer (image-to-image from the idle)

#### `werewolf_shadow` → `assets/images/enemies/werewolf_shadow.png` (1024x1536, regenerate)

Used by: bestiary.json werewolf_shadow, combat_crypt_werewolves

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Shadow Werewolf: tall, emaciated and elongated, its lower body and one arm dissolving into drifting black smoke drawn in fine stipple, long thin claws, eyes as two pin-points of bone-white light. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

- Variant hurt: same creature recoiling from a blow, head snapped back, one limb raised defensively, crimson spatter (generate image-to-image from the idle)
- Variant attack: same creature lunging forward toward the viewer (image-to-image from the idle)

#### `werewolf_alpha` → `assets/images/enemies/werewolf_alpha.png` (1024x1536, regenerate)

_Current file 'enemy_werewolf_silver.png' is a copy of class_warrior.jpg._

Used by: bestiary.json werewolf_alpha, combat_crypt_werewolves, post_combat_werewolves (medallion)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: an Alpha Werewolf: upright and massive, broad scarred chest, a streak of bone-white silver fur running from brow down the spine, leather harness straps, a tarnished silver medallion hanging at its throat, one claw dragging a broken chain. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

- Variant hurt: same creature recoiling from a blow, head snapped back, one limb raised defensively, crimson spatter (generate image-to-image from the idle)
- Variant attack: same creature lunging forward toward the viewer (image-to-image from the idle)

#### `flesh_construct` → `assets/images/enemies/flesh_construct.png` (1024x1536, new)

_Currently reuses the Spartan warrior._

Used by: bestiary.json flesh_construct, combat_flesh_construct, ritual_completion

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a huge monster made of many human corpses stitched together, rising waist-deep out of dark water, thick surgical stitches and metal staples across its torso, three mismatched arms, several human heads fused at its shoulders, water pouring off its body, scraps of torn robes caught in the stitches. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

- Variant hurt: same creature recoiling from a blow, head snapped back, one limb raised defensively, crimson spatter (generate image-to-image from the idle)
- Variant attack: same creature lunging forward toward the viewer (image-to-image from the idle)

### Backgrounds

#### `loc_undercroft` → `assets/images/locations/undercroft.webp` (1024x1792, new)

Used by: crypt_entrance, nav undercroft, combat_crypt_werewolves backdrop

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the Undercroft: a vaulted crypt chamber of old masonry, a monolithic altar of black stone stained with old blood at the centre, pale shafts of light falling through a fractured iron grating high in the ceiling, dust motes, bones in wall niches. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_alcove_recess` → `assets/images/locations/alcove_recess.webp` (1024x1792, new)

Used by: alcove_recess

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a narrow alcove in damp crypt masonry seen from inside, a corridor beyond where a long gouge has been scraped along the stone at shoulder height, the faint edge of a huge jointed shadow on the far wall. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_western_descent` → `assets/images/locations/western_descent.webp` (1024x1792, new)

Used by: western_passage

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a corridor sloping steeply downward where hewn stone gives way to a natural cave slick with condensation, clusters of bioluminescent fungi on the ceiling drawn as pale glowing stipple with a faint verdigris tint (the only place this tint is allowed). Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_cistern` → `assets/images/locations/cistern.webp` (1024x1792, new)

Used by: cistern_approach, vessel_theft, combat_cultists_01 backdrop

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a vast underground cistern with stone columns rising from stagnant black water, a ring of small hooded crimson-robed figures standing knee-deep around a stone plinth, on the plinth a glass vessel holding a glowing crimson heart, torches reflected in the water, seen from far across the water. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_cistern_awakened` → `assets/images/locations/cistern_awakened.webp` (1024x1792, new)

Used by: ritual_completion, combat_flesh_construct backdrop

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a flooded underground hall with stone columns, a broken glass jar on a stone pedestal in the middle of the water with a bright beam of light shooting straight up from it into the vaulted ceiling, robed bodies floating face-down around the pedestal, ripples spreading across the water. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

### Items

#### `item_heart_vessel` → `assets/images/items/heart_vessel.png` (512x512, new)

Used by: vessel_theft (The Stolen Heart)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a tall glass jar with a cork stopper, containing a human heart suspended in liquid, a serpent biting its tail engraved on the glass. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_silver_medallion` → `assets/images/items/silver_medallion.png` (512x512, new)

Used by: post_combat_werewolves

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a tarnished silver medallion on a broken chain, embossed with a wolf skull. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_rusted_falchion` → `assets/images/items/rusted_falchion.png` (512x512, new)

Used by: crypt_entrance loot

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a rusted single-edged falchion with a notched blade and a cracked leather grip. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

## P1: city, maps, and scenes for unwritten beats

### Creatures

#### `jointed_stalker` → `assets/images/enemies/jointed_stalker.png` (1024x1536, new)

_New. The story already describes it; give it a bestiary entry and a later encounter._

Used by: alcove_recess (seen, not fought yet)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the Jointed Stalker, the monstrosity from the alcove: a towering, gaunt anatomical horror whose arms and legs have far too many joints, bending in impossible directions, a malformed elongated skull tilted as if tasting the air, one arm ending in a long scythe-like claw that drags along the ground. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

### Backgrounds

#### `loc_sacrificial_archive` → `assets/images/locations/sacrificial_archive.webp` (1024x1792, new)

Used by: sacrificial_archive, letter_contents

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: close view of the black stone altar with a hidden drawer slid open, stacks of vellum pages with anatomical diagrams, a letter sealed with crimson wax pressed with an ouroboros. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_cistern_still` → `assets/images/locations/cistern_still.webp` (1024x1792, new)

Used by: post_combat_cultists, post_combat_flesh_construct

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the underground cistern after battle: water still again, a vast stitched corpse half-sunk in the shallows, the empty plinth, one guttering torch. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_scriptorium` → `assets/images/locations/scriptorium.webp` (1024x1792, new)

Used by: nav n1

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: the Vichally Amphitheater Scriptorium: a steep wooden anatomical theatre of tiered oval galleries descending to a single dissection table lit by candles, hanging anatomical charts, night. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_scriptorium_courtyard` → `assets/images/locations/scriptorium_courtyard.webp` (1024x1792, new)

Used by: northern_escape

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a cloistered stone courtyard at night under a sky of fine engraved stars, a rusted iron grate forced open in the flagstones, the dome of an anatomical theatre beyond. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_scribe_cobblestones` → `assets/images/locations/scribe_cobblestones.webp` (1024x1792, new)

Used by: nav n2

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: rain-slicked narrow cobbled alleys winding between leaning timber houses, hanging apothecary signs shaped like mortar and pestle (no lettering), lanterns reflected in puddles, dusk. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_cartography_vault` → `assets/images/locations/cartography_vault.webp` (1024x1792, new)

Used by: nav n3

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a subterranean archive vault of brick arches, shelves of rolled parchment maps, a large bronze armillary sphere and a da Vinci style map-drawing machine at the centre, candlelight. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_shambles` → `assets/images/locations/shambles.webp` (1024x1792, new)

Used by: nav slums

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a crowded slum of crooked wooden hovels against a towering city wall, muddy paths, hanging laundry, a scavenger's cart, smoke. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_bazaar` → `assets/images/locations/bazaar.webp` (1024x1792, new)

Used by: nav market

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a bustling high-street bazaar of cloth awnings and armourers' stalls, racks of blades and shields, hanging lamps, crowds rendered as small silhouettes. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_docks` → `assets/images/locations/docks.webp` (1024x1792, new)

Used by: nav docks

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: misty riverfront piers at night, smuggler boats moored beside a waterfront tavern with a hanging anchor sign (no lettering), crates and coiled rope, river mist. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

#### `loc_keep` → `assets/images/locations/keep.webp` (1024x1792, new)

Used by: nav keep

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a heavily fortified stone citadel on a rise above the city, high curtain walls, banners, a gatehouse with portcullis, storm clouds in fine hatching. Framing: vertical establishing view of the environment, deep perspective, one strong focal point in the middle third, the top and bottom fifths fall off into near-black so interface text can sit over them, no people unless described.
```

### Maps

#### `map_world` → `assets/images/maps/world_aethelgard.webp` (1792x1024, regenerate)

_Current map has generated-text typos baked in (Isle of Skuils, Lerical Indian). Generate without any text; draw labels in Flutter on top so names can change and unlock._

Used by: navigation_screen.dart overworld

```
hand-coloured antique atlas map engraving: fine black ink linework and hatching for mountains and coasts, rich watercolour washes of verdigris green, ochre, lapis blue seas and crimson accents on aged cream paper, sea monsters and ships as decoration, Renaissance cartography, absolutely no text, no labels, no lettering. Subject: a sea chart of the imaginary kingdom of Aethelgard: one large island shaped like a crouching dragon with a spine of snowy mountains, its head to the north-west and tail curling south, forests and rivers across its body, a desert peninsula with a crimson-washed city on its eastern claw, a ring of small rocky islets around it, a great whirlpool in the southern sea, sea serpents and a galleon in the surrounding ocean. Framing: top-down map view, entire landmass in frame, clean areas left for labels, absolutely no text or lettering anywhere.
```

#### `map_bowerstone` → `assets/images/maps/bowerstone.webp` (1792x1024, regenerate)

_Same problem: garbled street names. Generate without text and overlay labels._

Used by: navigation_screen.dart city map

```
hand-coloured antique atlas map engraving: fine black ink linework and hatching for mountains and coasts, rich watercolour washes of verdigris green, ochre, lapis blue seas and crimson accents on aged cream paper, sea monsters and ships as decoration, Renaissance cartography, absolutely no text, no labels, no lettering. Subject: a walled medieval city seen from above: an irregular ring of walls with gates on four sides, a cluster of keeps and a citadel to the north, a central plaza with radiating streets, a temple to the east, dense slums to the south-east, a river with docks along the southern wall, forest to the west, mountains to the north-east. Framing: top-down map view, entire landmass in frame, clean areas left for labels, absolutely no text or lettering anywhere.
```

## P2: bestiary entries with missing files, allies, items

### Characters

#### `ally_mercenary_scout` → `assets/images/allies/mercenary_scout.png` (1024x1536, new)

Used by: allies.json mercenary_scout (file 'player.png' missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Mercenary Scout: a weathered ranger in a hooded travel cloak and leather jerkin, a weathered shortbow in hand, a satchel of maps, alert and half-turned as if listening. Framing: full-length figure standing in a three-quarter view, the whole body in frame with feet visible, head in the top fifth, isolated on a pure black background with generous black margin around the figure.
```

### Creatures

#### `skeleton_brute` → `assets/images/enemies/skeleton_brute.png` (1024x1536, new)

Used by: bestiary.json skeleton_brute (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Skeleton Brute: a huge skeleton with thickened, fused bones, carrying a stone-headed maul, scraps of corroded bronze armour on the shoulders. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `skeleton_archer` → `assets/images/enemies/skeleton_archer.png` (1024x1536, new)

Used by: bestiary.json skeleton_archer (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Skeleton Archer: a lean skeleton drawing a warped longbow, a quiver of black-fletched arrows across the ribs, a torn hood. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `skeleton_captain` → `assets/images/enemies/skeleton_captain.png` (1024x1536, new)

Used by: bestiary.json skeleton_captain (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Skeleton Captain: a skeleton in a battered bronze cuirass and crested helm, a notched falchion raised, a torn crimson sash of rank. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `skeleton_mage` → `assets/images/enemies/skeleton_mage.png` (1024x1536, new)

Used by: bestiary.json skeleton_mage (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Skeleton Mage: a robed skeleton with an anatomical diagram etched across its skull, a crimson flame cupped above one bony hand, a staff of fused vertebrae. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `gargoyle` → `assets/images/enemies/gargoyle.png` (1024x1536, new)

Used by: bestiary.json gargoyle (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Stone Gargoyle: a crouching winged grotesque of cracked granite, bat wings with stone membranes, a lion-like snarling face, moss in the cracks drawn in stipple. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `zombie_common` → `assets/images/enemies/zombie_common.png` (1024x1536, new)

Used by: bestiary.json zombie_common (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Common Zombie: a shambling corpse in a burial shroud, jaw hanging loose, autopsy Y-incision stitched shut on the chest. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `zombie_rotted` → `assets/images/enemies/zombie_rotted.png` (1024x1536, new)

Used by: bestiary.json zombie_rotted (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Rotted Zombie: a bloated, half-liquefied corpse, ribs exposed through rotten flesh, toxic drool falling from its mouth. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `wraith` → `assets/images/enemies/wraith.png` (1024x1536, new)

Used by: bestiary.json wraith (file missing)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Wraith: a floating hooded spectre with no legs, its tattered shroud trailing into smoke, long skeletal fingers reaching forward, an empty black face with two pale lights. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `ally_shadow_hound` → `assets/images/allies/shadow_hound.png` (1024x1536, new)

Used by: allies.json shadow_hound (reuses werewolf art)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a Shadow Hound: a lean, loyal hunting hound whose hindquarters dissolve into stippled smoke, a bronze collar with a small ouroboros tag. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

#### `ally_iron_golem` → `assets/images/allies/iron_golem.png` (1024x1536, new)

Used by: allies.json iron_golem (reuses the Spartan)

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: an Iron Golem: a riveted iron automaton built like a da Vinci war machine, its chest plate open to show bronze gears arranged like a ribcage and heart, heavy fists, a single round lens for an eye. Framing: full-length creature filling most of the frame, entire silhouette visible, readable as a silhouette at small size, isolated on a pure black background with black margin around it.
```

### Items

#### `item_blackiron_claymore` → `assets/images/items/blackiron_claymore.png` (512x512, new)

Used by: inventory w1

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a massive two-handed claymore forged from dark meteoric iron. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_ceremonial_athame` → `assets/images/items/ceremonial_athame.png` (512x512, new)

Used by: inventory

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a double-edged ritual dagger with a bronze serpent hilt. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_cinquedea` → `assets/images/items/cinquedea.png` (512x512, new)

Used by: inventory

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a cinquedea: a short Italian dagger with a very broad triangular blade, as wide as a hand at the hilt and tapering to a point, fluted channels down the blade, a simple bronze crossguard. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_shortbow` → `assets/images/items/weathered_shortbow.png` (512x512, new)

Used by: inventory

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a short curved wooden hunting bow, the whole bow visible with its taut bowstring, grip wrapped in leather cord, one arrow lying beside it. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_essence_clarity` → `assets/images/items/essence_of_clarity.png` (512x512, new)

Used by: inventory c1

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a small alchemist's phial of pale vapour. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_mandrake_root` → `assets/images/items/mandrake_root.png` (512x512, new)

Used by: inventory c3

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a dried mandrake root shaped like a tiny screaming human figure. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_soul_gem` → `assets/images/items/corrupted_soul_gem.png` (512x512, new)

Used by: inventory c4

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a cracked faceted gem with a crimson flaw writhing inside. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_vault_key` → `assets/images/items/rusty_vault_key.png` (512x512, new)

Used by: inventory

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a long rusted iron key with an ouroboros bow. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_astrolabe` → `assets/images/items/hermetic_astrolabe.png` (512x512, new)

Used by: inventory

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a bronze hermetic astrolabe with anatomical figures on its rete. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

#### `item_crowns` → `assets/images/items/ouroboros_crowns.png` (512x512, new)

Used by: inventory currency

```
scratchboard engraving in the manner of Gustave Dore and the copperplates of Vesalius's Fabrica: fine white cross-hatched and stippled lines scratched out of solid black, monochrome bone-white on black, Renaissance anatomist's notebook, clinical and grim, hard chiaroscuro from a single high light at upper left, the only colour is a sparing touch of tarnished bronze on metal and dried-blood crimson where described. Subject: a small stack of worn bronze coins stamped with an ouroboros. Framing: a single object presented as a specimen plate, centred, three-quarter view, isolated on a pure black background, no hands.
```

## After the art lands

1. Drop files at the paths above. `pubspec.yaml` lists `assets/images/` only, so add each new subfolder (`portraits/`, `enemies/`, `allies/`, `locations/`, `maps/`, `items/`).
2. Point the data at them: `imageAsset` in `bestiary.json` and `allies.json`, `backgroundImage` per location in `navigation_state.dart` (all eight currently use `world_map.jpg`), and a new optional `sceneImage` on story nodes for the Chronicle header plate.
3. Run `dart tools/art/check_assets.dart`. It fails if any referenced image is missing, so a broken path never ships again.
