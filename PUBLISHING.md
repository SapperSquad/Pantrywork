# Pantrywork — publishing kit (current as of v0.1.0, UNRELEASED)

Store copy for the Modrinth / CurseForge project pages. Bump this file in the same pass as
`CHANGELOG.md` and `README.md` — never one alone.

**Files to upload — ADD as new versions; never delete older ones.**

| Upload as version | File | Game version tag | Loader |
|---|---|---|---|
| `0.3.0+mc1.21.1` | `dist/0.3.0/pantrywork-0.3.0.jar` | 1.21.1 | neoforge |
| `0.3.0+mc1.21.x-fabric` | `dist/0.3.0/pantrywork-0.3.0-fabric.jar` | 1.21.1–1.21.11 | fabric |
| `0.3.0+mc26-fabric` | `dist/0.3.0/pantrywork-0.3.0-fabric-mc26.jar` | 26.1.2, 26.2 | fabric |

Publish: `tools\publish.ps1 -Version 0.3.0 -ChangelogFile tools\changelog-current.md` (dry-run first).

Build all three with `./gradlew build -Prelease fabricJar fabricJar26`. The NeoForge jar's content is
unchanged from 0.1.0, so re-uploading it is optional — but keeping one version number across all
files keeps the store listing coherent.

Fabric version range verified 2026-08-08: same unmodified jar passed live suites on 1.21.10
(FD Refabricated + Croptopia Refabricated, incl. cross-mod smoothie craft) and 1.21.11
(FD Refabricated; Croptopia Refabricated caps at 1.21.10). Croptopia Refabricated audit:
same croptopia: namespace, same tag dialect (640 c: files) — bridges hit it unmodified.
NeoForge file stays 1.21.1-only: FD proper/Pam's/Croptopia NeoForge have nothing newer to bridge.

Build the NeoForge artifact with `./gradlew build -Prelease` — the plain `build` task leaves the
GameTest classes, the `pantrywork:empty` structure template, and the dev-only test recipes in the jar.
Fabric artifacts (`fabricJar`, `fabricJar26`) are data-only (no classes) with dev content always
excluded; each carries the Minecraft range it was actually verified against.

**Verification log** (every claim below was a live server boot + RCON suite, never inference):
1.21.1 FD+Croptopia+Pam's · 1.21.10 FD Refab + Croptopia Refab (7/7, cross-mod craft) ·
1.21.11 FD Refab (6/6) · 26.1.2 FD Refab + Croptopia 4.3.1 (7/7, cross-mod craft) · 26.2 FD Refab (6/6).
Version roadmap: no 1.20.x (pre-`c:`-unification); NeoForge widens only when FD/Pam's/Croptopia
ship NeoForge builds past 1.21.1.

## RELEASE BLOCKERS — clear these before first upload

- [x] **`pantrywork:test/universal_sandwich` must not ship.** Verified 2026-07-19 against a fresh
      `-Prelease` build: jar audit found 0 matches for universal_sandwich / recipe/test / gametest /
      .nbt; the 57 real data files are intact. Re-verify on every release build.
- [x] **Branding: DECIDED — Pantrywork** (SapperSquad, 2026-07-19). Mod id `pantrywork` locked and carried
      through code/data/tools/docs the same day; GameTests re-verified green under the new id.
- [x] Confirm the `-PnoCompatMods` boot is green — it is the regression test proving every cross-mod
      reference is optional, which is the mod's central promise. Verified 2026-07-19 on a fresh
      world: zero errors, vanilla tag suite 5/5, tag recipe still resolves. (Wipe `run/world` first —
      stale test chests holding modded items log a harmless ItemStack error that muddies the read.)

---

## Summary (the short-description field)

> The ore dictionary that food mods never got. Bridges Farmer's Delight, Croptopia, and Pam's
> HarvestCraft 2 into one shared tag vocabulary, so any mod's cheese works in any other's recipe.

---

## Project description (paste into the body)

# 🍞 One cheese. Every recipe.

Farmer's Delight has cheese. Croptopia has cheese. Pam's has cheese. **None of them are the
same cheese** — three mods, three incompatible tag dialects, none referencing the others. So the
recipe that wants cheese takes exactly one of them, and your pack quietly has three parallel
food economies that never touch.

Pantrywork fixes that. It is pure data: a tag layer that bridges those dialects into the official
NeoForge / Farmer's Delight `c:foods/*` convention, then adds a second layer describing what an
ingredient *does*. No blocks, no items, no gameplay changes. Just recipes that finally work.

## 🏷️ Two layers

**Identity** — `c:foods/*`. Extends the built-in convention and translates the others into it.
Croptopia's plural dialect (`c:cheeses`) and Pam's concatenated dialect (`c:rawpork`) both resolve
to canonical names (`c:foods/cheese`, `c:foods/raw_pork`). Bridges run in **both** directions:
24 dialect tags also gain the other mods' equivalent items, so Croptopia's and Pam's *own* recipes
start accepting foreign ingredients too.

**Role** — `pantrywork:food_component/{protein, starch, dairy, garnish, liquid_base, sweetener}`.
Tags-of-tags over the identity layer, describing function rather than identity. Author one recipe
against `#pantrywork:food_component/protein` and it accepts vanilla steak, Farmer's Delight bacon,
and anything a future mod tags — without you shipping an update.

## 🔌 Zero hard dependencies

Every cross-mod reference is `required: false`. Install Pantrywork with all the supported mods, one
of them, or none — it loads clean either way and simply bridges whatever it finds. There is no
"you must also install…" line, because there isn't one.

**Server-side only** — drop it on the server and every player benefits, no client install needed.
Works in singleplayer too (your game runs an internal server; just install it normally).

Supported: **Farmer's Delight** (incl. Refabricated on Fabric) · **Croptopia** ·
**Pam's HarvestCraft 2 Food Core** · **Ocean's Delight** (full identity module) ·
**End's Delight** (parent joins) · **[Let's Do] Vinery, Farm & Charm, Meadow** ·
**Aquaculture 2** · **Brewin' & Chewin'** · **Origins** (carnivore/vegetarian diet tags).

## 🧑‍🍳 For pack makers

Stop writing one recipe per food mod. Target a role tag and the recipe covers every mod your
players have installed, plus the ones they install later.

## 🛠️ For mod authors

`PantryworkTagKeys` exposes every tag as a constant, so you can reference the taxonomy without
hardcoding strings or taking a dependency on the mods being bridged.

## ✅ Verified, not assumed

Tested live on NeoForge 1.21.1 with Farmer's Delight 1.3.2, Croptopia 4.2.4, and Pam's HC2 Food
Core 1.0.4 loaded together — including a single crafting recipe that consumes vanilla bread,
Farmer's Delight bacon, and Croptopia lettuce at once. Automated GameTests cover role tags,
cross-mod identity, reverse bridges, and recipe resolution through `RecipeManager`.

---

## Gallery upload plan

**Art complete (2026-07-19), generated by `tools/GenPromo.java`** — regenerate with
`java tools/GenPromo.java` from the project root; never hand-edit the PNGs. Composed from the
bridged mods' real item textures (extracted to `tools/work/tex/`; re-extract from
`tools/work/jars/` if missing).

| File | Caption | Status at 0.3.0 |
|---|---|---|
| `promo/icon-512.png` | Project icon: pantry shelf | unchanged |
| `promo/banner-1920x640.png` | Four mods' cheeses converging into one tag | **REPLACE** — old one said "NeoForge 1.21.1" (now NeoForge & Fabric) and showed 3 mods |
| `promo/gallery-1-one-tag.png` | The two layers: identity tags bridging four dialects, role tags on top | **REPLACE** — old one said "Three dialects"; Farm & Charm made it four |
| `promo/gallery-2-four-mod-craft.png` | Pam's Grilled Cheese & Ham crafted from four mods' ingredients — the whole pitch in one image | unchanged |
| `promo/gallery-3-role-tags.png` | Recipe JSON targeting `#pantrywork:food_component/protein`, beside the items it accepts | **REPLACE** — protein row now shows 6 sources incl. Aquaculture + Meadow |
| `promo/gallery-4-supported-mods.png` | All ten bridged mods, with the "install all, some, or none" promise | **NEW** |

**Gallery uploads are manual.** The Modrinth PAT used by `publish.ps1` carries version scopes only
(create/delete versions); the gallery API returns 401 without project-edit scope. CurseForge has no
public gallery API at all. Either upload on each site by hand, or issue a PAT with project-edit
scope if you want this scripted later.

**Counts baked into the art** (`FOOD_MOD_COUNT`, `DIALECT_COUNT` in `tools/GenPromo.java`, plus the
headline strings): re-check these every time a compat module ships — images can't be grepped, so a
stale count survives silently. This release is the proof: "Three dialects" was wrong the moment
Farm & Charm landed.

No art carries version-specific claims yet. If a card ever states a mod count or supported-mod
list, re-check it every release — images can't be grepped and go stale invisibly.

---

## Changelog for the 0.1.0 uploads

> **0.2.0 — Minecraft 26.x support.** See `tools/changelog-current.md` for the paste-ready body.
>
> **0.1.0 — Initial release.** A shared tag vocabulary for food mods, for NeoForge and Fabric on
> Minecraft 1.21.1 (the Fabric jar is pure data — no code, no Fabric API requirement).
> - Identity layer extending the official `c:foods/*` convention, bridging Croptopia's and
>   Pam's HarvestCraft 2's tag dialects into it.
> - Role layer: `pantrywork:food_component/{protein, starch, dairy, garnish, liquid_base, sweetener}`
>   as tags-of-tags over the identity layer.
> - Reverse bridges: 24 dialect tags gain other mods' equivalent items, so Croptopia's and Pam's
>   own recipes accept foreign ingredients.
> - Compat modules for Farmer's Delight, Croptopia, Pam's HC2 Food Core, Ocean's Delight,
>   End's Delight, and Origins.
> - `PantryworkTagKeys` API class for downstream mods.
> - Every cross-mod entry is optional — any subset of the supported mods works.

---

## Platform facts

- Modrinth project id: *(not created yet)*
- CurseForge project id: *(not created yet — numeric, from the About Project sidebar; set
  `CURSEFORGE_PROJECT_ID` so `publish.ps1`-style automation can find it)*
- Minecraft: 1.21.1 · NeoForge 21.1.241+ (FD 1.3.2 needs ≥ 21.1.219, Croptopia ≥ 21.1.80) ·
  Fabric loader 0.14+ (data-only jar; Fabric API NOT required — don't list it as a dependency)
- Categories: `library`, `utility`, `food` — this is a library first; listing it under food/farming
  alone buries it for the pack makers who are the actual audience.
- Environment: client **optional**, server **required** — pure data (tags/recipes) that runs on the
  logical server and syncs to clients. Server-only install works for multiplayer; a client install
  is how singleplayer gets it (integrated server); a client joining a modded server needs nothing.
- License: split policy (SapperSquad, 2026-07-28) — **All Rights Reserved** on the Modrinth/CurseForge
  listing (`mod_license`/jar metadata match), **MIT** LICENSE in the GitHub repo. Authors who
  want to depend on or extend the taxonomy work from the MIT source.
- Platforms that received the last release: **none yet — unpublished.**
