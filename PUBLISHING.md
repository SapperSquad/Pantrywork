# Pantrywork — publishing kit (current as of v0.5.0)

Store copy for the Modrinth / CurseForge project pages. Bump this file in the same pass as
`CHANGELOG.md` and `README.md` — never one alone.

**Files to upload — ADD as new versions; never delete older ones.**

| Upload as version | File | Game version tag | Loader |
|---|---|---|---|
| `0.5.0+mc1.21.1` | `dist/0.5.0/pantrywork-0.5.0.jar` | 1.21.1 | neoforge |
| `0.5.0+mc1.21.x-fabric` | `dist/0.5.0/pantrywork-0.5.0-fabric.jar` | 1.21.1–1.21.11 | fabric |
| `0.5.0+mc26-fabric` | `dist/0.5.0/pantrywork-0.5.0-fabric-mc26.jar` | 26.1.2, 26.2 | fabric |
| `0.5.0+mc26` | `dist/0.5.0/pantrywork-0.5.0-neoforge-mc26.jar` | 26.1.2, 26.2 | neoforge |

Publish: `tools\publish.ps1 -Version 0.5.0 -ChangelogFile tools\changelog-current.md` (dry-run first).

Build all four with `./gradlew build -Prelease fabricJar fabricJar26 neoJar26`. The 0.5.0 payload
changed on every loader (seed-leak fix + optional convention refs), so upload all four files.

Fabric version range verified 2026-08-08: same unmodified jar passed live suites on 1.21.10
(FD Refabricated + Croptopia Refabricated, incl. cross-mod smoothie craft) and 1.21.11
(FD Refabricated; Croptopia Refabricated caps at 1.21.10). Croptopia Refabricated audit:
same croptopia: namespace, same tag dialect (640 c: files) — bridges hit it unmodified.

**NeoForge 26.x (new at 0.4.0):** `-neoforge-mc26` is data-only like the Fabric jars — no
modLoader declared in neoforge.mods.toml (26.x's no-code FML convention; lowcodefml is
deprecated), both `logoFile` AND `iconFile` so the icon shows on 26.1 and 26.2, MC range
`[26.1,27)`. The 1.21.x NeoForge file stays 1.21.1-only (FD proper and Pam's never shipped
past it); on 26.x the NeoForge food ecosystem is Croptopia + EpheroLib + Aquaculture 2 —
exactly what All the Mods 11 ships — and Pantrywork is verified against those.

Build the 1.21.1 NeoForge artifact with `./gradlew build -Prelease` — the plain `build` task leaves
the GameTest classes, the `pantrywork:empty` structure template, and the dev-only test recipes in the
jar. Fabric artifacts (`fabricJar`, `fabricJar26`) and `neoJar26` are data-only (no classes) with dev
content always excluded; each carries the Minecraft range it was actually verified against.

**Verification log** (every claim below was a live server boot + RCON suite, never inference):
- 2026-07/08: 1.21.1 FD+Croptopia+Pam's · 1.21.10 FD Refab + Croptopia Refab (7/7, cross-mod craft) ·
  1.21.11 FD Refab (6/6) · 26.1.2 FD Refab + Croptopia 4.3.1 (7/7, cross-mod craft) · 26.2 FD Refab (6/6).
- 2026-08-22 (0.4.0): **NeoForge 26.1.2.94** (the exact ATM11 build) solo — metadata clean,
  role tags + release purity green, required-false skip proven with Aquaculture absent ·
  **NeoForge 26.1.2.94 + Croptopia 4.3.1 + EpheroLib 1.3.0 + Aquaculture 2.9.2** (7/7: forward
  bridge, dairy/protein role chains incl. new Largemouth Bass, generated `c:fishes` union,
  negative, purity) · **NeoForge 26.2.0.64** solo (6/6) and **+ Croptopia 26.2** (5/5) ·
  **Fabric 26.1.2** FD Refab 3.6.17 + Croptopia 4.3.1 + pantrywork 0.4.0 (7/7 incl. smoothie
  craft) · **Fabric 26.2** same set (7/7 — smoothie craft newly possible on 26.2) ·
  **1.21.1 GameTests 5/5** with the full ten-mod dev set (payload-change regression).
  Note: recipe-level foreign-ingredient crafts on NeoForge-26 await FD's NeoForge port (in
  flight upstream, PR #1374) — Croptopia 26.x includes vanilla milk itself, so no honest
  bridge-craft pair exists there yet; tag-level bridging (what RecipeManager consumes) is
  fully exercised. Croptopia's 26.x port dropped its own `c:fishes`; on 26.x that dialect tag
  exists purely through Pantrywork's generated union (asserted live).
- 2026-08-29 (0.5.0): `tools/AuditRoles.ps1` green in both modes (0 seed violations, 0
  required-but-undefined refs) and proven non-vacuous by injecting a bogus required ref ·
  new `tagtest-seedfix.txt` 11/11 live (Croptopia produce still bridges; its seeds no longer
  reach `c:foods/vegetable` or `garnish`; plantable-food onion and roasted seed foods
  correctly retained) · all seven 1.21.1 RCON suites 90/90 · GameTests 5/5 ·
  `-PnoCompatMods` boot clean (0 errors, vanilla 4/4).
Version roadmap: no 1.20.x (pre-`c:`-unification). When FD's NeoForge 26.x port lands
(PR #1374 / Refabricated `neoforge/26.1` branch), boot it on the neo-26 harnesses and add the
craft-level assert to `tagtest-neo26-compat.txt`.

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

> The ore dictionary that food mods never got. Bridges ten food mods — Farmer's Delight, Croptopia,
> Pam's, the Let's Do series, Aquaculture and more — into one shared tag vocabulary, so any mod's
> cheese works in any other's recipe.

---

## Project description (paste into the body)

# 🍞 One cheese. Every recipe.

Farmer's Delight has cheese. Croptopia has cheese. Pam's has cheese. Meadow and Brewin' & Chewin'
have cheese. **None of them are the same cheese** — they all tag their food, in four incompatible
naming dialects that never reference each other. So the recipe that wants cheese takes exactly one
of them, and your pack quietly runs parallel food economies that never touch.

Pantrywork fixes that. It is pure data: a tag layer that bridges those dialects into the official
NeoForge / Farmer's Delight `c:foods/*` convention, then adds a second layer describing what an
ingredient *does*. No blocks, no items, no gameplay changes. Just recipes that finally work.

**NeoForge and Fabric**, on Minecraft 1.21.1 through 1.21.11 and 26.x.

## 🏷️ Two layers

**Identity** — `c:foods/*`. Extends the built-in convention and translates the others into it.
Croptopia's plural dialect (`c:cheeses`), Pam's concatenated dialect (`c:rawpork`), and Farm &
Charm's underscored dialect (`c:raw_pork`) all resolve to canonical names (`c:foods/cheese`,
`c:foods/raw_pork`). Bridges run in **both** directions: 36 dialect tags also gain the other mods'
equivalent items, so those mods' *own* recipes start accepting foreign ingredients too — Meadow's
cheese recipes take Croptopia cheese, Pam's fish recipes take an Aquaculture catch.

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

Every claim here was checked on a running server, not inferred. The supported mods are loaded
together and the bridges are exercised for real — Pam's own Grilled Cheese & Ham crafted from
Croptopia dairy and Farmer's Delight bacon; Croptopia's banana smoothie made with Farmer's Delight
Refabricated milk. The Fabric build is booted on 1.21.10, 1.21.11, 26.1.2 and 26.2; the NeoForge
builds on 1.21.1, 26.1.2 and 26.2 — the 26.1.2 boot on the exact NeoForge build All the Mods 11
ships, alongside its Croptopia and Aquaculture 2. A separate run boots it with **none** of the
supported mods installed, to prove it stays silent in a pack that has none of them. Automated
GameTests cover role tags, cross-mod identity, reverse bridges, and recipe resolution through
`RecipeManager`.

---

## Gallery upload plan

**Art complete (2026-07-19), generated by `tools/GenPromo.java`** — regenerate with
`java tools/GenPromo.java` from the project root; never hand-edit the PNGs. Composed from the
bridged mods' real item textures (extracted to `tools/work/tex/`; re-extract from
`tools/work/jars/` if missing).

**0.4.0: no art changes needed** — the roster is still ten mods, four dialects, both loaders;
no card carries a Minecraft-version claim (checked `GenPromo.java` headline strings 2026-08-22).

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

## Changelog for the uploads

> **0.4.0 — NeoForge comes to Minecraft 26.x.** See `tools/changelog-current.md` for the
> paste-ready body (new NeoForge 26.1–26.2 jar verified on ATM11's exact build alongside its
> food mods; Largemouth Bass in the fish bridges; smoothie craft verified on Fabric 26.2).
>
> **0.2.0 — Minecraft 26.x support.** (shipped 2026-08-08)
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

- Modrinth: **LIVE** — project id `rNg1wypx`, slug `pantrywork`, 1,159 downloads / 8 versions as
  of 2026-08-22 (the 26.x Fabric file is the most-downloaded 0.3.0 artifact: 364). The
  `MODRINTH_PROJECT_ID` env var is set on this machine; `publish.ps1` picks it up.
- CurseForge: **LIVE** — project id `1617573` (env vars `CURSEFORGE_PROJECT_ID`/`_TOKEN` were
  setx'd at the 0.2.0 publish; tokens rotated after. publish.ps1 skips CF when unset).
- Minecraft: 1.21.1 (NeoForge 21.1.241+; FD 1.3.2 needs ≥ 21.1.219, Croptopia ≥ 21.1.80) ·
  26.1–26.2 (NeoForge 26.1+, data-only jar) ·
  Fabric loader 0.14+ (data-only jar; Fabric API NOT required — don't list it as a dependency)
- Categories: `library`, `utility`, `food` — this is a library first; listing it under food/farming
  alone buries it for the pack makers who are the actual audience.
- Environment: client **optional**, server **required** — pure data (tags/recipes) that runs on the
  logical server and syncs to clients. Server-only install works for multiplayer; a client install
  is how singleplayer gets it (integrated server); a client joining a modded server needs nothing.
- License: split policy (SapperSquad, 2026-07-28) — **All Rights Reserved** on the Modrinth/CurseForge
  listing (`mod_license`/jar metadata match), **MIT** LICENSE in the GitHub repo. Authors who
  want to depend on or extend the taxonomy work from the MIT source.
- Platforms that received the last release (0.3.0): **Modrinth + CurseForge**, three files each
  (published 2026-08-09, single clean publish.ps1 run). 0.4.0 upload: pending, four files.

## Publish-time hazard: the store-id env vars are GLOBAL

`MODRINTH_PROJECT_ID` / `CURSEFORGE_PROJECT_ID` are user-wide on this machine and
shared by every mod, so whichever project published most recently owns them. At
the 0.5.0 publish `CURSEFORGE_PROJECT_ID` had drifted to `1616194` — a different
project — and all four CurseForge uploads were aimed at the wrong mod. They failed
only because that project rejects the NeoForge loader id (error 1009); had it
accepted, Pantrywork's jars would have been published onto another mod's page.

`tools/publish.ps1` now bakes in Pantrywork's own ids (Modrinth `rNg1wypx`,
CurseForge `1617573`, both verified against the live pages) and warns when an env
var disagrees. Do not "fix" the env var for Pantrywork — that just breaks whichever
project set it. Pass `-CurseForgeProjectId` / `-ModrinthProjectId` for a one-off.
