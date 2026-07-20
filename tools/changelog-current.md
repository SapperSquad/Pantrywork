**0.1.0 - Initial release.** A shared tag vocabulary for food mods, for NeoForge and Fabric on Minecraft 1.21.1 (the Fabric jar is pure data - no code, no Fabric API requirement).

- Identity layer extending the official `c:foods/*` convention, bridging Croptopia's and Pam's HarvestCraft 2's tag dialects into it.
- Role layer: `pantrywork:food_component/{protein, starch, dairy, garnish, liquid_base, sweetener}` as tags-of-tags over the identity layer.
- Reverse bridges: 24 dialect tags gain other mods' equivalent items, so Croptopia's and Pam's own recipes accept foreign ingredients.
- Compat modules for Farmer's Delight (incl. Refabricated), Croptopia, Pam's HC2 Food Core, Ocean's Delight, End's Delight, and Origins.
- `PantryworkTagKeys` API class for downstream mods (NeoForge jar).
- Every cross-mod entry is optional - any subset of the supported mods works.
