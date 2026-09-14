# Pantrywork — publishing kit (current as of v0.7.0)

Store copy for the Modrinth / CurseForge project pages. Bump this file in the same pass as
`CHANGELOG.md` and `README.md` — never one alone.

**Files to upload — ADD as new versions; never delete older ones.**

| Upload as version | File | Game version tags | Loader | Dependencies |
|---|---|---|---|---|
| `0.7.0+mc1.21.1` | `dist/0.7.0/pantrywork-0.7.0.jar` | 1.21.1 | neoforge | none |
| `0.7.0+mc1.21.x-fabric` | `dist/0.7.0/pantrywork-0.7.0-fabric.jar` | 1.21.1–1.21.11 (booted on 1.21.1, 1.21.10, 1.21.11) | fabric | Fabric API, required |
| `0.7.0+mc26-fabric` | `dist/0.7.0/pantrywork-0.7.0-fabric-mc26.jar` | 26.1.2, 26.2 | fabric | Fabric API, required |
| `0.7.0+mc26` | `dist/0.7.0/pantrywork-0.7.0-neoforge-mc26.jar` | 26.1.2, 26.2 | neoforge | none |

Publish: `tools\publish.ps1 -Version 0.7.0 -ChangelogFile tools\changelog-current.md` (dry-run first).
The version names above are exactly what `publish.ps1` generates (`<Version>+mc<label>[-fabric]`).

**Fabric API, on BOTH stores:** `publish.ps1` sends **Fabric API** as a required dependency of the two
Fabric files (Modrinth project `P7dR8mSH`, `required`; CurseForge relation slug `fabric-api`,
`requiredDependency`), and both Fabric jars declare `"fabric-api": "*"` in `fabric.mod.json`. Without
it Fabric Loader refuses to start and names the missing dependency (booted 2026-09-13 on the staged
`-fabric` jar). The 2026-09-13 dry run (`-DryRun -SkipCurseForge`) listed it on the two Fabric files
only; the CurseForge relation was not printed (that dry run skips CurseForge). After the upload,
confirm it on the live pages (release blockers below); add it by hand where a store dropped it.

Build all four with `./gradlew clean build -Prelease fabricJar fabricJar26 neoJar26`. The 0.7.0
payload changed on every loader (four new mods, cooked eggs, cost floors, conditional overlays,
generator fixes), so upload all four files. Staged jars (built 2026-09-13; the same bytes are in
`build/libs`, `dist/0.7.0` and all eight harness mods folders; SHA-1, size):
`pantrywork-0.7.0.jar` 8DDE4467859590019FD6031C8BA8B07818E76387, 64,946 bytes ·
`-fabric` B884D869B237DB2588D6A8BBDABC4CEEEB7B47B5, 63,068 ·
`-fabric-mc26` ACC303CCEAC34B049DA87EA3446FBD71539FADF2, 63,066 ·
`-neoforge-mc26` C3828E60ADD63C93078B5D4A27B86530DD19F2A8, 63,403.
These exact files were booted by every dedicated test server in the 0.7.0 verification log (each boot
checked its Pantrywork jar's SHA-1 against `dist/0.7.0` first). The dev-server suites run the source
tree, whose 126-file payload matches all four jars byte for byte.
Both NeoForge jars declare the food mods as optional AFTER deps (read from the staged jars'
`neoforge.mods.toml`). The 1.21.1 jar lists 14: farmersdelight, croptopia, pamhc2foodcore, oceansdelight,
ends_delight, vinery, farm_and_charm, meadow, brewinandchewin, aquaculture, and new in 0.7.0 create,
bountifulfares, fishofthieves and refurbished_furniture. The 26.x jar lists the same minus create and
bountifulfares (12), so of the four new mods it adds only Fish of Thieves and Refurbished Furniture; it
still names mods that have no 26.x build, such as Pam's and Farm & Charm, which is harmless for optional
deps. Fabric metadata carries no compat entries.

**Also on both stores this release** (store-mirror rule): paste the new Summary and Project description
below, and replace the banner, gallery 2 and gallery 4 (see Gallery upload plan).

Fabric version range: the 1.21.x file declares `>=1.21.1 <1.22` and is tagged 1.21.1–1.21.11 from that
range; it was booted on 1.21.1, 1.21.10 and 1.21.11 (versions in between were not booted). 2026-08-08:
the same unmodified jar passed live suites on 1.21.10 (FD Refabricated + Croptopia Refabricated, incl.
cross-mod smoothie craft) and 1.21.11 (FD Refabricated; Croptopia Refabricated caps at 1.21.10).
Croptopia Refabricated uses the same `croptopia:` namespace and tag dialect (640 c: files) but a
different mod id, `croptopia-refabricated`. Since 0.7.0 that id matters: the Fabric conditions for
Croptopia-dependent swaps name both ids. The first 0.7.0 build named only `croptopia` and failed its
1.21.10 boot (5/2); the staged build passes it.

**NeoForge 26.x (new at 0.4.0):** `-neoforge-mc26` is data-only like the Fabric jars — no
modLoader declared in neoforge.mods.toml (26.x's no-code FML convention; lowcodefml is
deprecated), both `logoFile` AND `iconFile` so the icon shows on 26.1 and 26.2, MC range
`[26.1,27)`. The 1.21.x NeoForge file stays 1.21.1-only (FD proper and Pam's never shipped
past it); on 26.x the NeoForge food ecosystem is Croptopia + EpheroLib + Aquaculture 2 —
exactly what All the Mods 11 ships — and Pantrywork is verified against those.

Build the 1.21.1 NeoForge artifact with `./gradlew build -Prelease` — the plain `build` task leaves
the GameTest classes, the `pantrywork:empty` structure template, and the dev-only test recipes in the
jar. Fabric artifacts (`fabricJar`, `fabricJar26`) and `neoJar26` are data-only (no classes) with dev
content always excluded. Store version tags come from `publish.ps1`; the versions actually booted are
in the log below.

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
- 2026-08-30 (0.6.0): all TEN 1.21.1 RCON suites 126/126 (new tagtest-collisions 15/15 and
  tagtest-milkshim 11/11, whose negative asserts prove the milk shim does NOT widen to the
  six-item c:drinks/milk union) · GameTests 5/5 · `-PnoCompatMods` boot clean (0 errors,
  vanilla 5/5) · AuditRoles green incl. the new shim-containment check, proven non-vacuous by
  joining the shim to #c:foods and confirming exit 1.
- 2026-09-13 (0.7.0, the four staged jars listed above). **This block replaces every earlier 0.7.0
  result:** those runs used builds from before the final repair round (SHA-1s 6993E4FB / F666A5AA /
  D79D4686 / 3E101DD7 and older), which are superseded. Every suite output classified by
  `tools/CountSuite.ps1` (an unannotated "Unknown item tag", a missing answer or a 0/0 suite counts as a
  failure; "+ N expected" = lines annotated as closed-condition probes, which must answer "Unknown item
  tag"). Clean world and fresh logs per boot, stopped via RCON, java confirmed exited; every dedicated
  server's Pantrywork jar SHA-1-checked against `dist/0.7.0` before boot.
  - **Static:** generator 88 tag files + `pack.mcmeta` (8 conditional, in 5 overlays; 11 GATE / 45
    EXCLUDE / 7 rescued PASS), re-run hash-identical · `-SelfTest` passed · AuditRoles full (556 Pantrywork
    routes judged, 14 GATE verdicts proven conditional, 79 dilution-guard pairs) and `-Minimal` (505 / 11 /
    70), every counter 0 · release jars: 126 payload files each (117 data files + `pack.mcmeta` + 8
    conditional-overlay tag files), byte-identical to source (0 missing, extra or differing; no duplicate
    entries), no test recipe, structure template or gametest class, version 0.7.0, authors SapperSquad;
    both Fabric jars declare `fabric-api`.
  - **NeoForge 1.21.1 dev boot** (every compat mod, incl. Create 6.0.10, Bountiful Fares 3.0.12, Fish of
    Thieves 21.1.2.1, Refurbished Furniture 1.0.22; runs the source tree, byte-identical to the jars'
    payload): 13 suites 391/0 — tagtest 14, multi 14, reverse 18 (Pam's Grilled Cheese & Ham from F&C
    butter + B&C wedge, and the same recipe refusing Croptopia cheese), crafttest-reverse 4, crafttest 4,
    addons 8, origins 11, letsdo 49, brewaqua 24, seedfix 10, collisions 17, milkshim 15, feedback 203 (FD
    egg sandwich from Pam's + BF eggs; bread from Pam's bakeware + Create dough; Croptopia banana nut bread
    from Create flour + FoT banana + BF walnut; the melon slice in `c:fruits`). tagtest-nofandc is 18/3 on
    this boot by design (its three "Farm & Charm absent" lines must fail while F&C is loaded) ·
    **`-PnoFarmAndCharm`**: nofandc 21/0 (bread from Croptopia dough without F&C; FD, Pam's and Create
    dough out of Croptopia's `c:doughs`), feedback 203/0 · **`-PnoCompatMods`**: tagtest-nofd 5/0 ·
    **GameTests 7/7**.
  - **NeoForge 1.21.1 dedicated server** (21.1.241, release jar): alone, tagtest-neo26 5/0 (tagtest-nofd
    4/1 there: its cake line needs the dev-only test recipe) · five mod combinations that switch the
    Pam's, Croptopia, Create and flour conditions on and off (the Farm & Charm condition was switched on
    the dev server above); S1-S4 each tagtest-gates 12/0 plus its own file, S5 its own file only: S1 FD + Meadow 5/0 · S2 + Pam's 12/0 ·
    S3 + Pam's + Croptopia 16/0 (Croptopia grilled cheese from Pam's cheese) · S4 FD + Meadow + Croptopia
    7/0 (Croptopia banana smoothie with FD milk) · S5 Create alone 6/0 + 1 expected (Create's flour out
    of `c:flour` with no flour mod installed).
  - **NeoForge 26.1.2.94** + Croptopia 4.3.1 + EpheroLib 1.3.0 + Aquaculture 2.9.2: neo26-compat 7/0,
    neo26-gates 6/0 + 4 expected; alone: tagtest-neo26 5/0 · **NeoForge 26.2.0.64** + Croptopia 4.3.1 +
    Fish of Thieves 26.2.1.1 + Refurbished 1.0.25: compat262 5/0, neo26-feedback 37/0 (Croptopia
    pineapple chicken from a FoT pineapple, banana smoothie from a FoT banana, half pineapple refused),
    neo26-gates 6/0 + 4 expected; alone: tagtest-neo26 5/0.
  - **Fabric** (Fabric Loader 0.19.3) **1.21.1** (FD Refab 3.3.3 + Croptopia 4.2.4, Fabric API 0.116.14):
    tagtest-fabric 7/0 (Croptopia banana smoothie from FD milk), fabric-gates 12/0 + 4 expected · **Fabric
    1.21.10** (FD Refab 3.4.2 + Croptopia Refabricated 0.10.0, API 0.138.4): 7/0 + 12/0 + 4 expected ·
    **Fabric 1.21.11** (FD Refab 3.6.13, API 0.141.6): tagtest-fabric-fd 9/0 · **Fabric 26.1.2** (FD Refab
    3.6.17 + Croptopia 4.3.1, API 0.155.2) and **Fabric 26.2** (same mods, API 0.156.0): 7/0 + 12/0 + 4
    expected each.
  - **Fabric 1.21.1 without Fabric API** (the staged `-fabric` jar alone): Fabric Loader refused to start
    and named the missing dependency ("requires any version of fabric-api, which is missing!"); exit code
    1, no world created.
  - Logs (all 19 boots): harness baseline only; zero lines about `pack.mcmeta`, overlays, conditional
    tags or tag loading ("Couldn't load tag", "Failed to load", "Missing data pack"), with the
    conditions on or off.
  - Not covered: the four new mods on Fabric (no Fabric harness carries them); Sinytra Connector; Quilt.
Version roadmap: no 1.20.x (pre-`c:`-unification). When FD's NeoForge 26.x port lands
(PR #1374 / Refabricated `neoforge/26.1` branch), boot it on the neo-26 harnesses and add the
craft-level assert to `tagtest-neo26-compat.txt`.

## RELEASE BLOCKERS — clear these before first upload

- [x] **`pantrywork:test/universal_sandwich` must not ship.** Verified 2026-07-19 against a fresh
      `-Prelease` build: jar audit found 0 matches for universal_sandwich / recipe/test / gametest /
      .nbt; the real data files are intact. Re-verify on every release build. Last re-verified
      2026-09-13 (0.7.0, the staged SHA-1s above): all four jars hold the same 126 payload files (117
      data files + `pack.mcmeta` + 8 conditional-overlay tag files), byte-identical to source, with no
      test recipe, structure template or gametest class.
- [ ] **Fabric API is a required dependency of both Fabric files, on BOTH stores (from 0.7.0).**
      `publish.ps1` sends it (Modrinth project `P7dR8mSH`, `required`; CurseForge relation slug
      `fabric-api`, `requiredDependency`) and both Fabric jars declare `"fabric-api": "*"` in
      `fabric.mod.json`. After the upload, open the two Fabric files on Modrinth and on CurseForge and
      confirm Fabric API is listed as required; add it by hand where a store dropped it. Tick only after
      looking at the live pages.
- [x] **Branding: DECIDED — Pantrywork** (SapperSquad, 2026-07-19). Mod id `pantrywork` locked and carried
      through code/data/tools/docs the same day; GameTests re-verified green under the new id.
- [x] Confirm the `-PnoCompatMods` boot is green — it is the regression test proving every cross-mod
      reference is optional, which is the mod's central promise. Verified 2026-07-19 on a fresh
      world: zero errors, vanilla tag suite 5/5, tag recipe still resolves. (Wipe `run/world` first —
      stale test chests holding modded items log a harmless ItemStack error that muddies the read.)

---

## Summary (the short-description field)

> The ore dictionary that food mods never got. Bridges fourteen mods — Farmer's Delight, Croptopia,
> Pam's, the Let's Do series, Create and more — into one shared tag vocabulary, so one mod's cheese
> works in another's recipes at a fair price.

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

**NeoForge** on Minecraft 1.21.1 and 26.1–26.2, **Fabric** on 1.21.1–1.21.11 and 26.1–26.2 (Fabric
needs Fabric API).

## 🏷️ Two layers

**Identity** — `c:foods/*`. Extends the built-in convention and translates the others into it.
Croptopia's plural dialect (`c:cheeses`), Pam's concatenated dialect (`c:rawpork`), and Farm &
Charm's underscored dialect (`c:raw_pork`) all resolve to canonical names (`c:foods/cheese`,
`c:foods/raw_pork`). Bridges run in **both** directions: 74 dialect tags also gain the other mods'
equivalent items, so those mods' *own* recipes start accepting foreign ingredients too — Meadow's
cheese recipes take Brewin' & Chewin' cheese, Pam's fish recipes take an Aquaculture catch, and
Croptopia's pineapple recipes take a Fish of Thieves pineapple.

**Fair swaps only.** An item Pantrywork adds to a recipe tag may be at most 1.5x cheaper than the
cheapest thing each mod that defines that tag already puts there, counting how it is made (a
16-per-bucket milk bottle costs a sixteenth of a bucket). When only some of those mods accept
something that cheap, the swap is added only while one of them is installed (a conditional pack
overlay, which the game applies only while that mod is loaded). So a milk bottle never
fills a recipe written for a bucket, a bacon strip never counts as a whole porkchop in Pam's recipes,
and Refurbished Furniture's six-per-loaf toast stays out of other mods' recipes. The check covers what
Pantrywork adds; what each mod lists in its own tags is its own call. Version 0.7.0 removed or made
conditional every older swap that failed it, and its changelog lists them all.

**Role** — `pantrywork:food_component/{protein, starch, dairy, garnish, liquid_base, sweetener}`.
Tags-of-tags over the identity layer, describing function rather than identity. Author one recipe
against `#pantrywork:food_component/protein` and it accepts vanilla steak, Farmer's Delight bacon,
and anything a future mod tags — without you shipping an update. Roles describe what an ingredient
does, not what it costs: `dairy` holds milk bottles and plant milk next to buckets.

## 🔌 No food mod required

Every cross-mod reference is `required: false`. Install Pantrywork with all the supported mods, one
of them, or none — it loads clean either way and simply bridges whatever it finds. On Fabric,
**Fabric API** is required: it is what loads mod data, and without it Fabric Loader refuses to start and
names the missing dependency.

**Server-side only** — drop it on the server and every player benefits, no client install needed.
Works in singleplayer too (your game runs an internal server; just install it normally).

Supported: **Farmer's Delight** (incl. Refabricated on Fabric) · **Croptopia** (incl. Croptopia
Refabricated) · **Pam's HarvestCraft 2 Food Core** · **Ocean's Delight** (full identity module) ·
**End's Delight** (parent joins) · **[Let's Do] Vinery, Farm & Charm, Meadow** ·
**Aquaculture 2** · **Brewin' & Chewin'** · **Create** · **Bountiful Fares** · **Fish of Thieves** ·
**Refurbished Furniture** · **Origins** (carnivore/vegetarian diet tags).

## 🧑‍🍳 For pack makers

Stop writing one recipe per food mod. Target a role tag and the recipe covers every mod your
players have installed, plus the ones they install later.

## 🛠️ For mod authors

`PantryworkTagKeys` exposes every tag as a constant, so you can reference the taxonomy without
hardcoding strings or taking a dependency on the mods being bridged.

## ✅ Verified, not assumed

Every claim here was checked on a running server, not inferred. The supported mods are loaded
together and the bridges are exercised for real — Pam's own Grilled Cheese & Ham crafted with
Farm & Charm butter and Brewin' & Chewin' cheese (and refused with Croptopia's cheaper cheese);
Farmer's Delight's egg sandwich made from Pam's and Bountiful Fares eggs; Croptopia's pineapple
chicken made from a Fish of Thieves pineapple on NeoForge 26.2; Croptopia's banana smoothie made
with Farmer's Delight milk. The Fabric build is booted on 1.21.1, 1.21.10, 1.21.11, 26.1.2 and 26.2;
the NeoForge builds on 1.21.1, 26.1.2 and 26.2 — the 26.1.2 boot on the exact NeoForge build All the
Mods 11 ships, alongside its Croptopia and Aquaculture 2. Separate runs boot it with **none** of the
supported mods installed, with Farm & Charm removed, and with and without the mods each conditional
swap depends on. Automated GameTests cover role tags, cross-mod identity, reverse bridges, cost
floors, and recipe resolution through `RecipeManager`.

---

## Gallery upload plan

**Art complete (2026-07-19), generated by `tools/GenPromo.java`** — regenerate with
`java tools/GenPromo.java` from the project root; never hand-edit the PNGs. Composed from the
bridged mods' real item textures (extracted to `tools/work/tex/`; re-extract from
`tools/work/jars/` if missing).

**0.4.0: no art changes needed** — the roster is still ten mods, four dialects, both loaders;
no card carries a Minecraft-version claim (checked `GenPromo.java` headline strings 2026-08-22).

**0.7.0: replace the banner, gallery 2 and gallery 4 on BOTH stores.**
- Gallery 4 lists fourteen mods (headline derived from `FOOD_MOD_COUNT`; the render fails if the
  roster disagrees). Its Brewin' & Chewin' icon is a cheese wedge, since the wheels are not food.
- Gallery 2 showed Croptopia butter/cheese + FD bacon in Pam's Grilled Cheese & Ham, which the 0.7.0
  cost floors made untrue. It now shows the verified craft (F&C butter + B&C cheese wedge + vanilla
  bread and porkchop), headlined "Three mods and vanilla. One sandwich.", and its footer says "No food
  mod required." instead of "Zero hard dependencies." (the Fabric files need Fabric API).
- The banner's Brewin' & Chewin' cheese is now the wedge too; every cheese it shows still reaches
  `#c:foods/cheese` (Croptopia's through its own `c:cheeses`).
- Icon, gallery 1 and gallery 3 are unchanged and their claims hold (four dialects; the protein role
  is unchanged). Every label is measured against its space at render time (`fitOrFail`).
- Re-checked 2026-09-13 against the staged jars (banner, gallery 2 and gallery 4 viewed; no
  regeneration needed). Gallery 4 shows fourteen mods (`FOOD_MOD_COUNT = 14`, the Supported list above
  minus Origins, which has its own footer line). Gallery 2's craft is tagtest-reverse.txt Craft B (Pam's
  skillet, vanilla bread, F&C butter, B&C flaxen cheese wedge, vanilla porkchop), which crafted on the
  dev boot (reverse 18/0, kill 2 entities); "No food mod required." holds on both loaders, since
  Fabric API is not a food mod. The banner's four cheeses (Croptopia cheese, Pam's cheese, Meadow
  cheese slice, B&C flaxen wedge) all resolve into `#c:foods/cheese` with the 0.7.0 data, with the
  conditional overlays on or off.

| File | Caption | Status at 0.7.0 |
|---|---|---|
| `promo/icon-512.png` | Project icon: pantry shelf | unchanged |
| `promo/banner-1920x640.png` | Four mods' cheeses converging into one tag | **REPLACE** — the Brewin' & Chewin' cheese was a wheel (not food); now the wedge |
| `promo/gallery-1-one-tag.png` | The two layers: identity tags bridging four dialects, role tags on top | unchanged |
| `promo/gallery-2-four-mod-craft.png` | Pam's Grilled Cheese & Ham crafted with Farm & Charm butter and Brewin' & Chewin' cheese | **REPLACE** — old craft used Croptopia dairy + FD bacon, no longer accepted; headline "Three mods and vanilla. One sandwich."; footer "No food mod required.". The file name keeps "four-mod" so upload scripts and links still match |
| `promo/gallery-3-role-tags.png` | Recipe JSON targeting `#pantrywork:food_component/protein`, beside the items it accepts | unchanged |
| `promo/gallery-4-supported-mods.png` | All fourteen bridged mods, with the "install all, some, or none" promise | **REPLACE** — was ten mods |

**Gallery uploads are manual.** The Modrinth PAT used by `publish.ps1` carries version scopes only
(create/delete versions); the gallery API returns 401 without project-edit scope. CurseForge has no
public gallery API at all. Either upload on each site by hand, or issue a PAT with project-edit
scope if you want this scripted later.

**Counts baked into the art** (`FOOD_MOD_COUNT`, `DIALECT_COUNT` in `tools/GenPromo.java`, plus the
headline strings): re-check these every time a compat module ships — images can't be grepped, so a
stale count survives silently. This release is the proof: "Three dialects" was wrong the moment
Farm & Charm landed.

No card states a Minecraft version. Three cards carry content claims that go stale: gallery 4 states
the bridged-mod count ("Fourteen mods bridged", derived from `FOOD_MOD_COUNT`) and the roster; gallery
2 shows one specific craft, which must be a craft a suite performs (tagtest-reverse.txt Craft B), and
says "No food mod required."; the banner shows four cheeses reaching `#c:foods/cheese`. Re-check them
every release — images can't be grepped and go stale invisibly.

---

## Changelog for the uploads

> **0.7.0 — Four more mods, cooked eggs, and swaps that have to be fair.** Paste-ready body in
> `tools/changelog-current.md`: Create, Bountiful Fares, Fish of Thieves and Refurbished Furniture;
> cooked eggs; four shipped-bug fixes including the `c:milk` dilution and the non-food cheese wheels;
> the cost-floor rule stated exactly (1.5x, per defining mod, conditional swaps); the full list of swaps
> that stopped working or became conditional; and the Fabric API requirement.
>
> **0.4.0 — NeoForge comes to Minecraft 26.x.** See `tools/changelog-current.md` for the
> paste-ready body (new NeoForge 26.1–26.2 jar verified on ATM11's exact build alongside its
> food mods; Largemouth Bass in the fish bridges; smoothie craft verified on Fabric 26.2).
>
> **0.2.0 — Minecraft 26.x support.** (shipped 2026-08-08)
>
> **0.1.0 — Initial release.** A shared tag vocabulary for food mods, for NeoForge and Fabric on
> Minecraft 1.21.1 (the Fabric jar is pure data — no code, no Fabric API requirement). *Corrected
> 2026-09-13: on Fabric, mod data is loaded by Fabric API, so it has always been needed. From 0.7.0 the
> Fabric files declare it, and without it Fabric Loader refuses to start and names the missing
> dependency.*
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
  Fabric loader 0.14+ (data-only jar) **+ Fabric API**: mod data packs are loaded by Fabric API's
  resource loader, which also applies the conditional overlays. Both Fabric jars declare
  `"fabric-api": "*"` and `publish.ps1` sends it as a required dependency (see the top of this file).
  Booted 2026-09-13: without Fabric API, Fabric Loader refuses to start and names the missing dependency.
- Categories: `library`, `utility`, `food` — this is a library first; listing it under food/farming
  alone buries it for the pack makers who are the actual audience.
- Environment: client **optional**, server **required** — pure data (tags/recipes) that runs on the
  logical server and syncs to clients. Server-only install works for multiplayer; a client install
  is how singleplayer gets it (integrated server); a client joining a modded server needs nothing.
- License: split policy (SapperSquad, 2026-07-28) — **All Rights Reserved** on the Modrinth/CurseForge
  listing (`mod_license`/jar metadata match), **MIT** LICENSE in the GitHub repo. Authors who
  want to depend on or extend the taxonomy work from the MIT source.
- Platforms that received the 0.3.0 release: **Modrinth + CurseForge**, three files each
  (published 2026-08-09, single clean publish.ps1 run). **0.7.0 published 2026-09-14 to both stores**
  (commit `33ac9ff`): four files each via one clean `publish.ps1` run; Modrinth verified live (four
  versions, SHA-1s match `dist/0.7.0`, Fabric API `P7dR8mSH` required on both Fabric files). Same pass:
  summary + description replaced on both stores (Modrinth via the API, CurseForge via the authors
  portal), banner / gallery 2 / gallery 4 replaced on both, the old three deleted, and every gallery
  image titled and captioned identically on both stores (Modrinth's two-layers card had carried the
  banner's caption; fixed).

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
project set it. Pass `-CurseForgeProjectId` / `-ModrinthProjectId` for a one-off. The 2026-09-13 dry
run warned again: `CURSEFORGE_PROJECT_ID` was `1616194`, and the script used `1617573`.
