# Pantrywork

**The ore dictionary that food mods never got.**

Farmer's Delight, Croptopia, and Pam's HarvestCraft 2 all ship common
(`c:`) item tags — in three incompatible naming dialects that never
reference each other. Pantrywork bridges them into the official
NeoForge/Farmer's Delight `c:foods/*` convention and adds a role layer on
top, so any mod's cheese, dough, flour, milk, or meat substitutes for any
other's in recipes.

- **Identity tags** (`c:foods/*`): extends the built-in convention;
  bridges Croptopia's plural dialect (`c:cheeses`) and Pam's concatenated
  dialect (`c:rawpork`) into canonical names (`c:foods/cheese`,
  `c:foods/raw_pork`). Reverse bridges make the mods' own recipes accept
  foreign ingredients too.
- **Role tags** (`pantrywork:food_component/{protein,starch,dairy,garnish,liquid_base,sweetener}`):
  what an ingredient *does* in a dish, defined as tags-of-tags over the
  identity layer. Author one recipe against
  `#pantrywork:food_component/protein` and it accepts vanilla steak, FD
  bacon, and anything future mods tag — forever. `PantryworkTagKeys`
  ships the constants for compile-time use (NeoForge jar).
- **Zero hard dependencies**: every cross-mod reference is optional; works
  with any subset of supported mods installed — or none.

**Both loaders, Minecraft 1.21.1**: NeoForge (21.1.241+) and Fabric (the
Fabric jar is pure data — no code, no Fabric API requirement).

Supported so far: Farmer's Delight (+ Refabricated on Fabric), Croptopia,
Pam's HarvestCraft 2 Food Core, Ocean's Delight, End's Delight, and
Origins (carnivore/vegetarian diet tags).

Verified live (2026-07-19): full RCON test suites plus 5 GameTests
(`gradlew runGameTestServer`) green on NeoForge with all compat mods
loaded, boot-matrix clean with none loaded, and the Fabric jar verified
on a real Fabric server — highlights include Pam's grilled-cheese-and-ham
crafted from four mods' ingredients (NeoForge) and Croptopia's banana
smoothie made with FD Refabricated milk (Fabric).

Docs: [docs/TAXONOMY.md](docs/TAXONOMY.md) (tag design) ·
[CLAUDE.md](CLAUDE.md) (build/test harness) ·
[PUBLISHING.md](PUBLISHING.md) (release kit)

Status: pre-release, launch-ready. Formerly developed under the working
name "FoodTags".

## Copyright

Copyright (c) 2026 SapperSquad. All rights reserved.

No license is granted: this work may not be copied, modified,
redistributed, or included in other distributions without express
permission from the copyright holder.
