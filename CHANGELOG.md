# Changelog

## 0.1.0 — unreleased (built 2026-07-19)

Initial version. NeoForge 1.21.1 (21.1.241+).

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
