# Changelog

## 0.2.0 — 2026-08-08

**Minecraft 26.x support, and a wider Fabric range.** No content changes —
the tag payload is byte-identical across all three files.

- **New: Fabric jar for Minecraft 26.x** (`-fabric-mc26`), verified live on
  26.1.2 (Farmer's Delight Refabricated 3.6.15 + Croptopia 4.3.1, including
  a cross-mod craft) and on 26.2 (FD Refabricated). 26.x kept the
  `data/c/tags/item` layout and both mods kept their tag dialects, so the
  bridges port unchanged.
- **Fabric 1.21.x range widened to 1.21.1–1.21.11**, verified live on
  1.21.10 (FD Refabricated + Croptopia Refabricated) and 1.21.11 (FD
  Refabricated). The in-jar range is now explicit (`>=1.21.1 <1.22`).
- NeoForge stays 1.21.1-only: Farmer's Delight, Pam's HarvestCraft 2, and
  Croptopia's NeoForge builds have nothing newer to bridge yet.

## 0.1.0 — 2026-07-20

Initial release. NeoForge 1.21.1 (21.1.241+) and Fabric 1.21.1.

- Identity layer: extends the official `c:foods/*` convention (cheese,
  butter, dough merges, cooked_rice, raw/cooked meat parent joins) and
  bridges Croptopia's and Pam's HarvestCraft 2's tag dialects into it.
- Role layer: `pantrywork:food_component/{protein,starch,dairy,garnish,liquid_base,sweetener}`
  as tags-of-tags over the identity layer.
- Reverse bridges (generated): 24 dialect tags gain other mods' equivalent
  items, so Croptopia/Pam's own recipes accept foreign ingredients.
- Compat modules: Farmer's Delight, Croptopia, Pam's HC2 Food Core,
  Ocean's Delight (full identity module), End's Delight (parent joins),
  Origins (carnivore/vegetarian diet tag).
- `PantryworkTagKeys` API class for downstream mods (NeoForge jar).
- Ships for **both NeoForge and Fabric** on 1.21.1 — the Fabric jar is
  data-only (no code, no Fabric API dependency), verified live against
  Farmer's Delight Refabricated + Croptopia Fabric.
- All data entries for other mods are optional — any subset of supported
  mods works.
