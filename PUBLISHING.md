# Pantrywork — publishing kit (current as of v0.9.0)

Store copy for the Modrinth / CurseForge project pages. Bump this file in the same pass as
`CHANGELOG.md` and `README.md` — never one alone.

**Files to upload — ADD as new versions; never delete older ones.**

| Upload as version | File | Game version tags | Loader | Dependencies |
|---|---|---|---|---|
| `0.9.0+mc1.21.1` | `dist/0.9.0/pantrywork-0.9.0.jar` | 1.21.1 | neoforge | none |
| `0.9.0+mc1.21.x-fabric` | `dist/0.9.0/pantrywork-0.9.0-fabric.jar` | 1.21.1–1.21.11 (booted on 1.21.1, 1.21.10, 1.21.11) | fabric | Fabric API, required |
| `0.9.0+mc26-fabric` | `dist/0.9.0/pantrywork-0.9.0-fabric-mc26.jar` | 26.1.2, 26.2 | fabric | Fabric API, required |
| `0.9.0+mc26` | `dist/0.9.0/pantrywork-0.9.0-neoforge-mc26.jar` | 26.1.2, 26.2 | neoforge | none |

Publish: `tools\publish.ps1 -Version 0.9.0 -ChangelogFile tools\changelog-current.md` (dry-run first).
The version names above are exactly what `publish.ps1` generates (`<Version>+mc<label>[-fabric]`).

**Fabric API, on BOTH stores:** `publish.ps1` sends **Fabric API** as a required dependency of the two
Fabric files (Modrinth project `P7dR8mSH`, `required`; CurseForge relation slug `fabric-api`,
`requiredDependency`), and both Fabric jars declare `"fabric-api": "*"` in `fabric.mod.json` (re-read
out of the staged 0.8.0 jars). Without it Fabric Loader refuses to start and names the missing
dependency (booted on the staged 0.8.0 `-fabric` jar: it refuses to start, naming `fabric-api`). The
2026-10-06 dry run (`-DryRun -SkipCurseForge`) listed it on the two Fabric files only; the CurseForge
relation was not printed (that dry run skips CurseForge). After the upload, confirm it on the live
pages (release blockers below); add it by hand where a store dropped it.

Build all four with `./gradlew clean build -Prelease fabricJar fabricJar26 neoJar26`. The 0.9.0
payload changed on every loader (three new Pam's modules on the 1.21.1 side, and on EVERY file the
tofu exclusions and the four sanitized canonical tags), so upload all four files. Staged jars (built
2026-11-03, **rebuilt 2026-11-04** for the tofish fix; the same bytes are in `dist/0.9.0`; SHA-1 and
size measured in this pass — every earlier staged set is superseded and must not be uploaded, the
first 0.9.0 cut included):
`pantrywork-0.9.0.jar` 26302D0887306C04FDBB6869FCA0F803AE9F8360, 89,462 bytes ·
`-fabric` 31DCC8922B39721C3D1D5A115992D700C9A9D5E9, 87,369 ·
`-fabric-mc26` 843A48F62C0421F9695B66FD4DD20E6537E6EAEC, 87,368 ·
`-neoforge-mc26` 6056F2EA136B01199A183A4D01A4AF3526EEF10E, 87,705.
Each carries **151 payload files** — 134 data files (39 hand-authored + 95 generated) + `pack.mcmeta`
+ 16 conditional-overlay tag files in 14 overlays — identical across all four jars, version `0.9.0`,
authors `SapperSquad`, and no test recipe, structure template or gametest class. These exact files
were booted by every dedicated test server in the 0.9.0 verification log (each boot checked its
Pantrywork jar's SHA-1 against `dist/0.9.0` first). The dev-server suites run the source tree, whose
payload matches all four jars byte for byte apart from the two dev-only files `-Prelease` strips.
Both NeoForge jars declare the food mods as optional AFTER deps (read from the staged jars'
`neoforge.mods.toml`). The 1.21.1 jar lists **24**: farmersdelight, croptopia, pamhc2foodcore,
**pamhc2crops, pamhc2trees, pamhc2foodextended** (new in 0.9.0),
oceansdelight, ends_delight, vinery, farm_and_charm, meadow, brewinandchewin, aquaculture, create,
bountifulfares, fishofthieves, refurbished_furniture, and from 0.8.0 kaleidoscope_cookery,
hearthandharvest, culturaldelights, cookscollection, rusticdelight, hybrid_delights and
biomeswevegone. The 26.x jar
lists **12** — the 1.21.1 list minus create, bountifulfares and all seven 0.8.0 ids, none of which has a
**NeoForge** 26.x build (Rustic Delight has a Fabric 26.x build, which a NeoForge dep list cannot
name) — and still names mods with no 26.x build at all, such as Pam's and Farm & Charm, which is
harmless for optional deps. Fabric metadata carries no compat entries.

**Also on both stores this release** (store-mirror rule): paste the new Summary and Project description
below, and replace **gallery 4 only** — at 0.9.0 it is again the single image that changed (roster
twenty-one → twenty-four). The banner, galleries 1–3 and the icon are byte-identical to what is
already live (verified by hashing each against the 0.8.0 commit) and must not be re-uploaded.

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
- 2026-09-13 (0.7.0). **SUPERSEDED as the current release by the 0.8.0 block below** — kept as the
  record of what 0.7.0 was measured on; its SHA-1s (8DDE4467 / B884D869 / ACC303CC / C3828E60) are the
  0.7.0 jars, not the files to upload now. It in turn replaced every earlier 0.7.0
  result: those runs used builds from before the final repair round (SHA-1s 6993E4FB / F666A5AA /
  D79D4686 / 3E101DD7 and older). Every suite output classified by
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
- 2026-10-06 (0.8.0, first staging). **SUPERSEDED as the current release by the 0.8.0 re-cut block
  below** — kept as the record of what that staging was measured on. The seed-rule blocker fix
  (`CHANGELOG.md` 0.8.0, "Under the hood") changed eight generated tag files, so all four jars were
  rebuilt and every result here ran bytes that are no longer the release; those four superseded jars
  were moved out of `dist/0.8.0`, and their SHA-1s are deliberately gone from this file so nothing
  stale can be uploaded. Suite outputs classified by `tools/CountSuite.ps1` (an unannotated "Unknown item tag", a
  missing answer or a 0/0 suite counts as a failure; "+ N expected" = lines annotated as closed-condition
  probes, which must answer "Unknown item tag"). Clean world and fresh logs per boot; every dedicated
  server's Pantrywork jar SHA-1-checked against `dist/0.8.0` before boot.
  - **Static:** generator 104 tag files + `pack.mcmeta` (16 conditional, in 14 overlays; 42 GATE / 66
    EXCLUDE / 11 rescued PASS), re-run hash-identical · `-SelfTest` passed · AuditRoles full (730
    Pantrywork routes judged, 46 GATE verdicts proven conditional) and `-Minimal` (672 routes, 42
    gates), both exit 0 · release jars: 144 payload files each (127 data files + `pack.mcmeta` + 16
    conditional-overlay tag files), identical across all four jars, version 0.8.0, authors SapperSquad,
    no test recipe, structure template or gametest class; both Fabric jars declare `fabric-api`.
  - **NeoForge 1.21.1 dev boot** (every compat mod, including the five new ones): 14 suites at their
    header counts, including the new `tagtest-kaleido` at 101 passed / 0 failed / 5 expected,
    `tagtest-letsdo` 50 and `tagtest-feedback` 204 (both of which moved by exactly the gate churn this
    release introduced) · **`-PnoFarmAndCharm`**: tagtest-nofandc 21/0 · **`-PnoCompatMods`**:
    tagtest-nofd 5/0 · **GameTests 7/7**.
  - **NeoForge 1.21.1 dedicated server** (21.1.241, release jar): alone, plus eleven gate scenarios
    S1–S11 that switch the Pam's, Croptopia, Create, Farm & Charm, Cook's Collection, Hearth and
    Harvest, Kaleidoscope Cookery and Rustic Delight conditions on and off at item level. 13 of the 14
    overlays get both an open and a closed proof here.
  - **NeoForge 26.1.2.94 and 26.2.0.64**, each with Croptopia (compat suites, solo boots, and
    `tagtest-neo26-gates` at 7 passed / 0 failed / 12 expected: Croptopia is the only rescuer with a
    NeoForge 26.x build, so exactly three of the fourteen overlays open there).
  - **Fabric** 1.21.1, 1.21.10, 1.21.11, 26.1.2 and 26.2: `tagtest-fabric` 7/0, `tagtest-fabric-gates`
    22 passed / 0 failed / 10 expected, `tagtest-fabric-fd` 9/0 on the 1.21.11 harness.
  - **Fabric without Fabric API** (the staged `-fabric` jar alone): Fabric Loader refuses to start and
    names the missing dependency.
  - 22 boots, 33 suite runs, all green.
  - **Publish dry run** `tools\publish.ps1 -Version 0.8.0 -ChangelogFile tools\changelog-current.md
    -DryRun -SkipCurseForge`: exit 0, all four files resolved as `0.8.0+mc1.21.1` (neoforge, 1.21.1),
    `0.8.0+mc1.21.x-fabric` (fabric, 1.21.1–1.21.11), `0.8.0+mc26-fabric` and `0.8.0+mc26` (both 26.1.2
    + 26.2), version type `release`, project `rNg1wypx`. Fabric API (`P7dR8mSH`, `required`) is on the
    two Fabric files and on neither NeoForge file. It warned again that `CURSEFORGE_PROJECT_ID` is
    `1616194` and used `1617573` instead — expected, see the hazard note at the end of this file.
  - **Not covered, stated honestly.** Cultural Delights cannot boot on `tools/neo-server-1211` at all —
    its `neoforge.mods.toml` requires NeoForge ≥ 21.1.247 and that harness deliberately stays on
    21.1.241, so the release jars players run are still proven on the older build. So CD's half of the
    `culturaldelights_or_rusticdelight` gate, Bountiful Fares' half of the two `c:flour` gates, the open
    half of the `create` gate, and Hybrid Delights' three salt bridges (its jar needs HAPI and Kotlin
    for Forge, and its salt item exists only with Hybrid Aquatic installed) are proven on the dev boot
    only. Also not covered: the five new mods on Fabric (no Fabric harness carries them); Sinytra
    Connector; Quilt.
- 2026-10-06 (0.8.0 re-cut #1, SHA-1s CF295036 / D8D31300 / EBB90AB3 / CFF8781E). **SUPERSEDED as
  the current release by the 2026-10-07 blueberry block below** — the blueberry bridge added two
  generated tag files, so those four jars were rebuilt again and every result here ran bytes that
  are no longer shipped. Their SHA-1s are kept only so an uploaded file can be identified; the jars
  themselves were moved out of `dist/0.8.0`.
  The seed-rule blocker fix dropped Cultural Delights' and Hearth and Harvest's corn
  kernels and `create:chocolate_glazed_berries` from eight generated tag files, which changed every
  jar's bytes, so the entire matrix was re-run on the new ones and nothing is carried over from the
  block above. Suite outputs classified by `tools/CountSuite.ps1` (an unannotated "Unknown item tag",
  a missing answer or a 0/0 suite counts as a failure; "+ N expected" = lines annotated as
  closed-condition probes, which must answer "Unknown item tag"). Clean world and fresh logs per
  boot, stopped via RCON, java confirmed exited and port 25575 free between boots; every dedicated
  server's Pantrywork jar SHA-1-checked against `dist/0.8.0` before boot.
  - **Static:** generator 104 tag files + `pack.mcmeta` (16 conditional, in 14 overlays; 42 GATE / 66
    EXCLUDE / 11 rescued PASS — unchanged by the fix, which dropped three silent PASSes), re-run
    hash-identical · `-SelfTest` passed · AuditRoles full (127 tags, 14 overlays, **713** Pantrywork
    routes judged, 46 GATE verdicts proven conditional, 102 dilution-guard pairs) and `-Minimal`
    (**657** routes, 42 gates, 94 pairs), every counter 0 and both exit 0 — the first staging's 730 /
    672 fell by exactly the 17 (tag, item) pairs the three dropped entries accounted for · both tools
    report the platform convention tags from `neoforge 21.1.247`, the `gradle.properties` pin ·
    release jars: 144 payload files each (127 data files + `pack.mcmeta` + 16 conditional-overlay tag
    files), identical across all four jars, version 0.8.0, authors SapperSquad, no test recipe,
    structure template or gametest class; both Fabric jars declare `fabric-api`; and a direct byte
    scan confirms no jar contains the string `corn_kernels` or `chocolate_glazed_berries`.
  - **NeoForge 1.21.1 dev boot** (every compat mod, including the five new ones; 4 boots, 18 suite
    runs): full `runServer` 14 suites 548/0 — tagtest 14, multi 14, reverse 18, crafttest-reverse 4,
    crafttest 4, addons 8, origins 11, letsdo 50, brewaqua 24, seedfix 10, collisions 17, milkshim 15,
    feedback 204, **tagtest-kaleido 155 + 5 expected** — plus tagtest-nofandc 18/3, which is by design
    on this boot (its three "Farm & Charm absent" lines must fail while F&C is loaded) ·
    **`-PnoFarmAndCharm`**: nofandc 21/0, feedback 204/0 · **`-PnoCompatMods`**: tagtest-nofd 5/0 ·
    **GameTests 7/7**.
  - **NeoForge 1.21.1 dedicated server** (21.1.241, release jar; 12 boots, 17 suite runs): alone,
    tagtest-neo26 5/0 and tagtest-nofd 4/1 — the one documented failure in the whole matrix: that
    suite's cake line needs the dev-only test recipe `-Prelease` strips · then eleven gate scenarios
    S1–S11, one clean boot each, switching the Pam's, Croptopia, Create, Farm & Charm, Cook's
    Collection, Hearth and Harvest, Kaleidoscope Cookery and Rustic Delight conditions on and off at
    item level: `tagtest-gates` 19/0 + 7 expected on each of S1–S4, plus s1 7/0 + 4, s2 15/0 + 4,
    s3 18/0 + 1, s4 9/0 + 1, s5 6/0 + 5, s6 30/0 + 5, s7 16/0 + 4, s8 19/0 + 3, s9 20/0 + 3,
    s10 7/0 + 3, s11 17/0 + 3. 13 of the 14 overlays get both an open and a closed proof here.
  - **NeoForge 26.1.2.94** (ATM11's exact build) + Croptopia: neo26-compat 7/0 and
    `tagtest-neo26-gates` 7/0 + 12 expected; alone: tagtest-neo26 5/0 · **NeoForge 26.2.0.64** +
    Croptopia: compat262 5/0, neo26-feedback 37/0, neo26-gates 7/0 + 12 expected; alone:
    tagtest-neo26 5/0. Croptopia is the only rescuer with a NeoForge 26.x build, so exactly three of
    the fourteen overlays open on those harnesses.
  - **Fabric** (Fabric Loader 0.19.3, five harnesses): **1.21.1**, **1.21.10**, **26.1.2** and
    **26.2** each tagtest-fabric 7/0 and `tagtest-fabric-gates` 22/0 + 10 expected · **1.21.11**
    `tagtest-fabric-fd` 9/0 (the other two suites are scoped by their own headers against a harness
    with a Croptopia build, and this one has none).
  - **Fabric without Fabric API** (the `-fabric` jar alone): Fabric Loader refused to start and named
    `fabric-api`; exit code 1, no world created.
  - 22 release boots, 33 suite runs, every one at its documented count (the single exception is the
    documented tagtest-nofd cake line above), on top of the 4 dev boots.
  - **Publish dry run** `tools\publish.ps1 -Version 0.8.0 -ChangelogFile tools\changelog-current.md
    -DryRun -SkipCurseForge`, re-run on these jars: exit 0, all four files resolved as
    `0.8.0+mc1.21.1` (neoforge, 1.21.1), `0.8.0+mc1.21.x-fabric` (fabric, every version 1.21.1
    through 1.21.11), `0.8.0+mc26-fabric` and `0.8.0+mc26` (both 26.1.2 + 26.2), version type
    `release`, project `rNg1wypx`. Fabric API (`P7dR8mSH`, `required`) is on the two Fabric files and
    on neither NeoForge file. It warned again that `CURSEFORGE_PROJECT_ID` is `1616194` and used
    `1617573` instead — expected, see the hazard note at the end of this file.
  - **Not covered, stated honestly.** Cultural Delights cannot boot on `tools/neo-server-1211` at all —
    its `neoforge.mods.toml` requires NeoForge ≥ 21.1.247 and that harness deliberately stays on
    21.1.241, so the release jars players run are still proven on the older build. So CD's half of the
    `culturaldelights_or_rusticdelight` gate and its four 1/2 cuts, Bountiful Fares' half of the two
    `c:flour` gates, the open half of the `create` gate, and Hybrid Delights' three salt bridges (its
    jar needs HAPI and Kotlin for Forge, and its salt item exists only with Hybrid Aquatic installed)
    are proven on the dev boot only — Rustic Delight stands in for Cultural Delights on the release
    matrix. Also not covered: the five new mods on Fabric (no Fabric harness carries them); Sinytra
    Connector; Quilt.
- 2026-10-07 (0.8.0 re-cut #2 — the blueberry bridge; the four jars listed at the top of this file).
  **This is the current release.** The sixth player report (Oh The Biomes We've Gone blueberries)
  added two generated tag files and four entries to a third, so all four jars were rebuilt and the
  whole matrix was re-run on the new bytes; nothing is carried over from the block above except the
  dev-boot results, which run the source tree, and that tree is byte-identical to these jars
  (measured below). Suite outputs classified by `tools/CountSuite.ps1` (an unannotated "Unknown item
  tag", a missing answer or a 0/0 suite counts as a failure; "+ N expected" = lines annotated as
  closed-condition probes, which must answer "Unknown item tag"). Fresh world and fresh logs per
  boot, stopped via RCON, java confirmed exited and port 25575 free between boots; every harness's
  Pantrywork jar SHA-1-checked against `dist/0.8.0` first.
  - **Static:** generator (documented command) **106 tag files** + `pack.mcmeta` (16 conditional, in
    14 overlays; 42 GATE / 66 EXCLUDE / 11 rescued PASS — unchanged, the blueberry work needed no new
    verdict), re-run byte-stable · `-SelfTest` passed · AuditRoles full (**720** Pantrywork routes
    judged, 46 GATE verdicts proven conditional) and `-Minimal` (**664** routes, 42 gates), every
    counter 0 and both exit 0 · release jars: **146 payload files each** (129 data files +
    `pack.mcmeta` + 16 conditional-overlay tag files) — re-measured file by file against the
    regenerated source tree, **0 missing, 0 extra, 0 differing on all four jars**, the only two source
    files absent from each being the dev-only test recipe and gametest structure that `-Prelease`
    strips, which is the point · `biomeswevegone` appears in exactly 3 payload files per jar
    (`c/tags/item/blueberries.json`, `fruits.json`, `fruits/blueberry.json`) and in the 1.21.1
    `neoforge.mods.toml`, nowhere else.
  - **NeoForge 1.21.1 dedicated server** (21.1.241, release jar **E61935B3**; 13 boots, 18 suite
    runs): alone, tagtest-neo26 5/0 and tagtest-nofd 4/1 — the one documented failure in the whole
    matrix, that suite's cake line needing the dev-only test recipe `-Prelease` strips · then **twelve
    gate scenarios S1–S12**, one clean boot each: `tagtest-gates` 19/0 + 7 expected on each of S1–S4,
    plus s1 7/0 + 4, s2 15/0 + 4, s3 18/0 + 1, s4 9/0 + 1, s5 6/0 + 5, s6 30/0 + 5, s7 16/0 + 4,
    s8 19/0 + 3, s9 20/0 + 3, s10 7/0 + 3, s11 17/0 + 3, and **s12 27/0 + 3**.
    **S12 is new and is the blueberry scenario** — Farmer's Delight + Hearth and Harvest + Croptopia
    + EpheroLib + Oh The Biomes We've Gone 2.6.2 and its four hard deps (TerraBlender, CorgiLib, Oh
    The Trees You'll Grow, GeckoLib). BYG's NeoForge floor is 21.1.173, so unlike Cultural Delights it
    can boot on this harness. It proves the bridge with **two real crafts** (Hearth and Harvest's
    blueberry crate from nine BYG berries; Croptopia's blueberry jam from one — three ingredients on
    purpose, because a lone BYG berry is ambiguous with BYG's own one-slot blue-dye recipe), the
    `soul_fruit` exclusion (out of `c:fruits` and `pantrywork:bridged/fruit`, still in BYG's own
    `c:foods/fruit`), and the `c:blueberry`-is-a-seed-tag negative.
  - **NeoForge 26.1.2.94** (ATM11's exact build, jar **1E2615AF**) + Croptopia: neo26-compat 7/0 and
    `tagtest-neo26-gates` 7/0 + 12 expected; alone: tagtest-neo26 5/0 · **NeoForge 26.2.0.64** (same
    jar) + Croptopia: compat262 5/0, neo26-feedback 37/0, neo26-gates 7/0 + 12 expected; alone:
    tagtest-neo26 5/0.
  - **Fabric** (Fabric Loader 0.19.3, five harnesses): **1.21.1**, **1.21.10** (jar **0728AF65**),
    **26.1.2** and **26.2** (jar **EB67143E**) each tagtest-fabric 7/0 and `tagtest-fabric-gates`
    22/0 + 10 expected · **1.21.11** `tagtest-fabric-fd` 9/0.
  - **Fabric without Fabric API** (the shipped `-fabric` jar `0728AF65` alone, scratch copy of the
    1.21.1 harness): "Mod resolution failed", "Incompatible mods found!", "Mod 'Pantrywork'
    (pantrywork) 0.8.0 requires any version of fabric-api, which is missing!", and **no world
    directory created**.
  - **23 release boots, 34 suite runs**, every one at its documented count (the single exception is
    the documented tagtest-nofd cake line above), on top of the 4 dev boots recorded in the block
    above, whose source tree is byte-identical to these jars.
  - **Log scan, all 23 boots:** zero lines matching `pack.mcmeta`, `overlay`, `pantrywork_gate`,
    `pantrywork:gated`, "Failed to load", "Missing data pack", "Tried to load invalid" or "Couldn't
    load tag" — **except** exactly two lines on each of the three Kaleidoscope-Cookery scenarios
    (S7, S9, S10), the documented upstream Quark baseline. S12's scan is clean, so adding BYG and
    four library mods introduced nothing.
  - **Publish dry run** `tools\publish.ps1 -Version 0.8.0 -ChangelogFile tools\changelog-current.md
    -DryRun -SkipCurseForge`, re-run on these jars and this changelog: exit 0, all four files
    resolved as `0.8.0+mc1.21.1` (neoforge, 1.21.1), `0.8.0+mc1.21.x-fabric` (fabric, every version
    1.21.1 through 1.21.11), `0.8.0+mc26-fabric` and `0.8.0+mc26` (both 26.1.2 + 26.2), version type
    `release`, project `rNg1wypx`. Fabric API (`P7dR8mSH`, `required`) is on the two Fabric files and
    on neither NeoForge file. It warned again that `CURSEFORGE_PROJECT_ID` is `1616194` and used
    `1617573` instead — expected, see the hazard note at the end of this file.
  - **Not covered, stated honestly.** Everything in the block above still applies (Cultural Delights
    cannot boot on `tools/neo-server-1211`; Bountiful Fares' half of the two `c:flour` gates; the open
    half of the `create` gate; Hybrid Delights' three salt bridges — all dev-boot-only). New with the
    blueberry work: **no Fabric harness carries BYG**, so the Fabric side of the blueberry bridge is
    proven by the data and by S12, not by a Fabric boot — the same status as Rustic Delight and Hybrid
    Delights. BYG does publish Fabric builds (Modrinth lists 2.6.2-Fabric for 1.21.1, 4.2.2 for
    1.21.10 and 4.3.x/4.4.x for 1.21.11) and **no 26.x build on any loader**, so on the two 26.x files
    the blueberry entries are simply inert. Only the 1.21.1 Fabric build is the same 2.6.2 whose tags
    were read here; the 4.x builds were not inspected.
- **2026-10-08 — 0.8.0 PUBLISHED to both stores.** `tools\publish.ps1 -Version 0.8.0
  -ChangelogFile tools\changelog-current.md` exit 0: four files to Modrinth (`0.8.0+mc1.21.1`,
  `+mc1.21.x-fabric`, `+mc26-fabric`, `+mc26`) and four to CurseForge, all eight in one run, no
  duplicates — the Modrinth version list reads exactly four 0.8.0 rows whose SHA-1s are E61935B3 /
  0728AF65 / EB67143E / 1E2615AF, and all four CurseForge files show **Approved**. Store copy moved
  in the same pass per the mirror rule: Summary and Project description via
  `PATCH /v2/project/rNg1wypx` (204) on Modrinth and the General + Description tabs on CurseForge,
  gallery 4 replaced on both. Both public pages read back correct.
  **Three gotchas worth keeping:**
  1. **The Modrinth summary field is capped at 256 characters** and the first 0.8.0 draft was 295.
     CurseForge's is also 256 (its field shows a live counter; the final line measures 246).
  2. **PS 5.1 `Invoke-RestMethod` decodes Modrinth's JSON as Latin-1** (Modrinth sends
     `application/json` with no charset), so em dashes and the 🍞 come back as `â€”` / `ðŸž` and the
     page looks corrupted when it is not. Verify with an explicit UTF-8 decode of the raw bytes
     before "fixing" anything — the live text was correct both times this looked wrong.
  3. Modrinth's project GET is cached ~20s after a write; a read-back straight after a gallery POST
     will show the old list.
Version roadmap: no 1.20.x (pre-`c:`-unification). When FD's NeoForge 26.x port lands
(PR #1374 / Refabricated `neoforge/26.1` branch), boot it on the neo-26 harnesses and add the
craft-level assert to `tagtest-neo26-compat.txt`.

## 0.9.0 — verification record (2026-11-03)

Four jars in `dist/0.9.0`, staged into all eight harness mods folders (the 0.8.0 jars moved to
scratch, not deleted). SHA-1s:
`pantrywork-0.9.0.jar` **26302D0887306C04FDBB6869FCA0F803AE9F8360** ·
`-fabric` **31DCC8922B39721C3D1D5A115992D700C9A9D5E9** ·
`-fabric-mc26` **843A48F62C0421F9695B66FD4DD20E6537E6EAEC** ·
`-neoforge-mc26` **6056F2EA136B01199A183A4D01A4AF3526EEF10E**.
These are the REBUILD of 2026-11-04. The first cut (D03A9021 / 46626DF6 / 4FA521B0 / C34D0B34)
carried a cost-floor leak and **must not be uploaded** — see "The rebuild" below.

**151 payload files** per jar (134 data + `pack.mcmeta` + 16 overlay tag files, 14 overlays),
identical across the four and matching the source tree except the two dev-only files
`-Prelease` strips. **24** optional AFTER deps in the 1.21.1 jar (was 21: added `pamhc2crops`,
`pamhc2trees`, `pamhc2foodextended`); the 26.x jar is unchanged at **12**, since none of the
three has a 26.x build. Version `0.9.0`, authors `SapperSquad`.

Static gates: generator exit 0 and byte-stable on re-run, `-SelfTest` PASSED, `AuditRoles.ps1`
full and `-Minimal` both exit 0 with every counter at 0.

**27 boots, every suite at its documented count, zero regressions.** 4 dev (full `runServer`
9742 recipes with 15 suites plus the new `tagtest-pams` **119/0**; `-PnoFarmAndCharm`;
`-PnoCompatMods`; `runGameTestServer` 7/7) and 23 release (neo-server-1211 solo + the full
S1–S12 gate matrix; neo-server-2612 and -262 compat, gates and solo; all five Fabric harnesses;
and the no-Fabric-API boot, which refuses to start and names `fabric-api`). The full table is in
`CLAUDE.md` under "0.9.0 BOOT MATRIX 2026-11-03".

**The rebuild (2026-11-04).** Writing up `docs/TAXONOMY.md` turned up a cost-floor leak in the
first 0.9.0 cut: Pam's Food Extended's `rawtofishitem` — a plant analogue made from one pressed
soybean, no fish at any step — had no row in `tools/cost-floors.json`, so it fell through to the
fish tags' `default: 1`, was priced as a whole cod, and shipped into `c:rawfish`, `c:fishes`,
`c:raw_fishes` and canonical `c:foods/raw_fish`. Fixed with a 0-fish cost row and by routing
`c:foods/raw_fish` through the judged enumeration the three raw meats already use. The payload
difference between the two builds is **5 entries in 4 of the 151 files**, and the only item that
leaves any tag anywhere is that one. Re-verified on the new bytes: all static gates, then **the
entire 27-boot matrix re-run on the rebuilt jars on 2026-11-04** — 4 dev (full `runServer` 9742
recipes with all 16 suites, `-PnoFarmAndCharm`, `-PnoCompatMods`, GameTests 7/7) and 23 release
(neo-server-1211 solo + S1–S12; neo-server-2612 and -262 compat, gates and solo; all five Fabric
harnesses; and the no-Fabric-API boot, which refuses to start and names `fabric-api`). Every suite
at its documented count, zero regressions, and the log scan clean on all 27 apart from the
documented KC-without-Quark pair on the three Kaleidoscope scenarios and the dev boots carrying it.
**No result in this record rests on the superseded first cut.**

**Store-copy audit for this release** (the 0.8.0 pass found three claims that had been false on
the live pages since 0.1.0, so this is now a standing step):
- The roster count moved 21 → 24 in the summary, in gallery 4 (`FOOD_MOD_COUNT`, which the
  render refuses to disagree with) and in the mod list below. The count IS the 1.21.1 jar's
  optional-AFTER list, re-counted out of the built jar: 24.
- **Do not claim Pantrywork bridges Pam's Food Extended's items.** It bridges none of them —
  725 of its 871 items carry no `c:` tag at all, and the rest are tofu/soy analogues the cost
  floor excludes. Its value is the other direction: 743 of its recipe ingredient slots now
  accept other mods' food. Phrase it as inbound, which is what the boots proved.
- The two crafts quoted anywhere in copy must be ones a suite actually performs. For 0.9.0 those
  are `tagtest-pams.txt` phase F: fried onions from Croptopia's onion + Cultural Delights'
  butter, and cheese on toast from Croptopia's toast + Meadow's cheese slice.

## RELEASE BLOCKERS — clear these before first upload

- [x] **`pantrywork:test/universal_sandwich` must not ship.** Verified 2026-07-19 against a fresh
      `-Prelease` build: jar audit found 0 matches for universal_sandwich / recipe/test / gametest /
      .nbt; the real data files are intact. Re-verify on every release build. Last re-verified
      2026-11-04 (0.9.0, the staged SHA-1s above, the rebuild): all four jars hold the same 151 payload
      files (134 data files + `pack.mcmeta` + 16 conditional-overlay tag files), with no test recipe,
      structure template or gametest class. (0.8.0 block, superseded: 146 payload files, same result.)
- [x] **Fabric API is a required dependency of both Fabric files, on BOTH stores (from 0.7.0).**
      `publish.ps1` sends it (Modrinth project `P7dR8mSH`, `required`; CurseForge relation slug
      `fabric-api`, `requiredDependency`) and both Fabric jars declare `"fabric-api": "*"` in
      `fabric.mod.json` — re-read out of the staged 0.8.0 jars in this pass.
      **Confirmed live 2026-10-08, and the earlier doubt is now explained.** Modrinth: the version
      API shows `P7dR8mSH / required` on `0.8.0+mc1.21.x-fabric` and `0.8.0+mc26-fabric`, and on
      neither NeoForge file. CurseForge: **it is there, but no public page renders it.** The file
      page shows only name/uploader/size/loader/versions, and *Relations → Dependencies* on the
      project page says "Dependencies (0)" because that tab is **project-level only**. Per-file
      relations live in the authors UI at
      `authors.curseforge.com/#/projects/1617573/files/<fileId>` → *Related Projects (Dependencies)*,
      which reads **Fabric API / Required Dependency** on file 9095774 (Fabric 1.21.x) and 9095775
      (Fabric 26), and "There are no relations for this project" on 9095773 (NeoForge 1.21.1) —
      exactly the right scoping. **Do not "fix" this by adding a project-level relation:** that would
      apply to the NeoForge files too and tell NeoForge users to install Fabric API. Re-check the
      same three author pages each release.
- [ ] **0.9.0: gallery 4 is replaced on BOTH stores.** Again the only image that changed, and it
      again carries the mod count (now **twenty-four**). Banner, galleries 1–3 and the icon are
      byte-identical to the live ones — do not re-upload them. Use the 0.8.0 recipe immediately
      below, including the Modrinth `DELETE ?url=` gotcha (it wants the `_350.webp` url, not
      `raw_url`).
- [x] **0.8.0: gallery 4 was replaced on BOTH stores.** It was the only image that changed at 0.8.0, and it
      carries the mod count (now twenty-one). The banner and gallery 2 regenerate byte-identical, so leave
      them alone. Done 2026-10-08: Modrinth via the gallery API (new card featured, the old
      "Fourteen mods bridged" deleted — note `DELETE ?url=` wants the **`_350.webp`** url from the
      listing, not `raw_url`, which 400s); CurseForge via the Media tab (uploaded, retitled
      "Twenty-one mods bridged", Feature Media starred, description set, old card deleted). Both
      galleries read back as five images with the twenty-one-mod card present.
- [x] **Branding: DECIDED — Pantrywork** (SapperSquad, 2026-07-19). Mod id `pantrywork` locked and carried
      through code/data/tools/docs the same day; GameTests re-verified green under the new id.
- [x] Confirm the `-PnoCompatMods` boot is green — it is the regression test proving every cross-mod
      reference is optional, which is the mod's central promise. Verified 2026-07-19 on a fresh
      world: zero errors, vanilla tag suite 5/5, tag recipe still resolves. (Wipe `run/world` first —
      stale test chests holding modded items log a harmless ItemStack error that muddies the read.)

---

## Summary (the short-description field)

**HARD LIMIT 256 CHARACTERS on Modrinth** — the API rejects a longer one. Measure before pasting;
the first 0.8.0 draft was 295 and would have failed. The line below is **247** (twenty-one -> twenty-four cost one character; re-measure on every roster change).

> The ore dictionary that food mods never got. Bridges twenty-four mods — Farmer's Delight, Croptopia,
> Pam's, the Let's Do series and more — into one shared tag vocabulary, so one mod's cheese, salt or
> oil works in another's recipes at a fair price.

---

## Project description (paste into the body)

# 🍞 One cheese. Every recipe.

Croptopia has cheese. Pam's has cheese. Meadow has cheese. Brewin' & Chewin' has cheese. **None of
them are the same cheese** — they all tag their food, in four incompatible
naming dialects that never reference each other. So the recipe that wants cheese takes exactly one
of them, and your pack quietly runs parallel food economies that never touch. Kaleidoscope Cookery's
wok will not even light unless you hand it *its* cooking oil, with five other mods' oils sitting
in the same chest.

Pantrywork fixes that. It is pure data: a tag layer that bridges those dialects into the official
NeoForge / Farmer's Delight `c:foods/*` convention, then adds a second layer describing what an
ingredient *does*. No blocks, no items, no gameplay changes. Just recipes that finally work.

**NeoForge** on Minecraft 1.21.1 and 26.1–26.2, **Fabric** on 1.21.1–1.21.11 and 26.1–26.2 (Fabric
needs Fabric API).

## 🏷️ Two layers

**Identity** — `c:foods/*`. Extends the built-in convention and translates the others into it.
Croptopia's plural dialect (`c:cheeses`), Pam's concatenated dialect (`c:rawpork`), and Farm &
Charm's underscored dialect (`c:raw_pork`) all resolve to canonical names (`c:foods/cheese`,
`c:foods/raw_pork`). Bridges run in **both** directions: 74 of those mods' own dialect tags gain the
other mods' equivalent items (84 tag files in all, the other ten being canonical `c:foods/*` leaves
like `c:foods/corn` and `c:foods/oranges`), so their *own* recipes accept foreign ingredients — Meadow's
cheese recipes take Brewin' & Chewin' cheese, Pam's fish recipes take an Aquaculture catch, and
Croptopia's pineapple recipes take a Fish of Thieves pineapple.

Where a mod reads a tag of its own instead of a shared one, Pantrywork writes that tag. Kaleidoscope
Cookery's wok checks `#kaleidoscope_cookery:oil` before it will cook, so five mods' cooking oils now
prime it — and that is the gate in front of all 225 of its wok recipes.

And where a mod grows food but files it in no shared tag at all, Pantrywork files it. Oh The Biomes
We've Gone's blueberries sat in its own berry tag and in no blueberry tag anywhere, so no other mod
could see them; they now reach Hearth and Harvest's five blueberry recipes and Croptopia's three.

**Fair swaps only.** An item Pantrywork adds to a recipe tag may be at most 1.5x cheaper than the
cheapest thing each mod that defines that tag already puts there, counting how it is made (a
16-per-bucket milk bottle costs a sixteenth of a bucket). When only some of those mods accept
something that cheap, the swap is added only while one of them is installed (a conditional pack
overlay, which the game applies only while that mod is loaded). So a milk bottle never
fills a recipe written for a bucket, a bacon strip never counts as a whole porkchop in Pam's recipes,
and Refurbished Furniture's six-per-loaf toast stays out of other mods' recipes. The check covers what
Pantrywork adds; what each mod lists in its own tags is its own call. Version 0.7.0 removed or made
conditional every older swap that failed it, and its changelog lists them all; 0.8.0 removed nothing,
and its changelog lists the two swaps that gained a condition and the three conditions that got easier
to satisfy. 0.9.0 removed five: Pam's Food Extended files five tofu analogues in its raw beef, pork,
mutton and fish tags, and each one is a pressed soybean, so none of them reaches a canonical meat or
fish tag through Pantrywork any more. In the same pass four canonical tags — raw beef, raw pork, raw
mutton and raw fish — stopped pointing at a whole dialect and now list their members, which is what
let the tofu in; the members themselves are unchanged.

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
Refabricated) · **Pam's HarvestCraft 2 — all four modules: Food Core, Crops, Trees and Food Extended** ·
**Ocean's Delight** (full identity module) ·
**End's Delight** (parent joins) · **[Let's Do] Vinery, Farm & Charm, Meadow** ·
**Aquaculture 2** · **Brewin' & Chewin'** · **Create** · **Bountiful Fares** · **Fish of Thieves** ·
**Refurbished Furniture** · **Kaleidoscope Cookery** · **Hearth and Harvest** · **Cultural Delights** ·
**Cook's Collection** · **Rustic Delight** · **Hybrid Delights** · **Oh The Biomes We've Gone** (a
worldgen mod, here for the four fruits it grows) · **Origins** (carnivore/vegetarian
diet tags).

## 🧑‍🍳 For pack makers

Stop writing one recipe per food mod. Target a role tag and the recipe covers every mod your
players have installed, plus the ones they install later.

## 🛠️ For mod authors

`PantryworkTagKeys` (NeoForge jar) exposes the role tags and the most-asked-for identity tags —
cheese, butter, dough, cooked rice, flour — as compile-time constants, so you can reference the
taxonomy without hardcoding strings or taking a dependency on the mods being bridged. Anything else
in the layer is a plain `c:` tag id you can write directly.

## ✅ Verified, not assumed

Every bridge claimed here was checked on a running server, not inferred — recipe *counts* are read
out of the mods' own files, but whether a swap works is always measured. The supported mods are loaded
together and the bridges are exercised for real — Pam's own Grilled Cheese & Ham crafted with
Farm & Charm butter and Brewin' & Chewin' cheese (and refused with Croptopia's cheaper cheese);
Farmer's Delight's egg sandwich made from Pam's and Bountiful Fares eggs; Croptopia's pineapple
chicken made from a Fish of Thieves pineapple on NeoForge 26.2; Croptopia's banana smoothie made
with Farmer's Delight milk; Hearth and Harvest's blueberry crate and Croptopia's blueberry jam made
from Oh The Biomes We've Gone berries; and, new at 0.9.0, two of Pam's Food Extended recipes built
entirely out of other mods' food — fried onions from Croptopia's onion and Cultural Delights' butter,
and cheese on toast from Croptopia's toast and Meadow's cheese slice. The Fabric build is booted on 1.21.1, 1.21.10, 1.21.11, 26.1.2 and 26.2;
the NeoForge builds on 1.21.1, 26.1.2 and 26.2 — the 26.1.2 boot on the exact NeoForge build All the
Mods 11 ships, alongside its Croptopia and Aquaculture 2. Separate runs boot it with **none** of the
supported mods installed, with Farm & Charm removed, and with and without the mods the conditional
swaps depend on — twelve such combinations on the 1.21.1 release jar alone, which prove
thirteen of the fourteen conditions both open and closed. The few they cannot reach are proven on the
development boot instead, and the changelog says which rather than implying full coverage. Automated
GameTests cover role tags, cross-mod identity, reverse bridges, cost floors, and recipe resolution
through `RecipeManager`.

Where something *cannot* be fixed with tags, the changelog says so rather than implying otherwise:
a recipe that names an exact item id cannot be widened by any datapack, and several of the supported
mods do exactly that.

---

## Gallery upload plan

**Art complete (2026-07-19), generated by `tools/GenPromo.java`** — regenerate with
`java tools/GenPromo.java` from the project root; never hand-edit the PNGs. Composed from the
bridged mods' real item textures (extracted to `tools/work/tex/`; re-extract from
`tools/work/jars/` if missing).

**0.4.0: no art changes needed** — the roster is still ten mods, four dialects, both loaders;
no card carries a Minecraft-version claim (checked `GenPromo.java` headline strings 2026-08-22).

**0.9.0: replace gallery 4 on BOTH stores. Nothing else.** Regenerated 2026-11-03 with
`java tools/GenPromo.java` (JDK 21) after `FOOD_MOD_COUNT` went 21 → 24 and the roster gained its
three Pam's rows. Every PNG was re-hashed against the 0.8.0 commit afterwards and **only
`gallery-4-supported-mods.png` changed** — B61D16D4 → CE7A4FD8. The banner (6464C0DC), gallery 1
(33EEC10C), gallery 2 (8E75C1B0), gallery 3 (72811F90) and the icon (B4D3454C) are byte-identical to
what is already live, so their claims are untouched and they must not be re-uploaded.
- Gallery 4 is now **three rows of eight** (was 7/7/7). Headline: "Twenty-four mods bridged."
- The three new icons are real item textures: Crops' corn and Trees' banana, both items Pantrywork
  genuinely bridges, and Food Extended's sushi. **The sushi is an identifying icon, not a bridge
  claim** — Pantrywork bridges none of Food Extended's own items. Its roster row is earned the other
  way round, as the biggest consumer of what the other mods supply; the comment beside the row says
  so, and the store copy says "inbound" for the same reason.
- Gallery 2's craft is unchanged and still true (tagtest-reverse.txt Craft B — Pam's Grilled Cheese
  & Ham from F&C butter and B&C cheese). 0.9.0 touched no item in it: the tofu exclusions are all
  Food Extended items, and the four sanitized canonical tags kept every member they had.
- Gallery 1's "Four dialects" still holds — Pam's three new modules speak the SAME concatenated
  dialect as Food Core, which is exactly why this release needed no new machinery.
- The card was opened and read after the run: 24 tiles, no label collision, no overflow, and the
  footer line still gives Origins its own credit outside the count.

**0.8.0: replaced gallery 4 on BOTH stores. Nothing else.** Regenerated 2026-10-06 with
`java tools/GenPromo.java` (JDK 21) after `FOOD_MOD_COUNT` went 14 → 20 and the roster gained its six
new rows, then **regenerated again 2026-10-07** when the blueberry work took the count to 21. Every
PNG was re-hashed after each run and **only `gallery-4-supported-mods.png` changed** — SHA-1 prefixes
now: banner `6464C0DC`, gallery 1 `33EEC10C`, gallery 2 `8E75C1B0`, gallery 3 `72811F90`, gallery 4
`B61D16D4`, icon `B4D3454C`; `git status promo/` lists gallery 4 alone as modified against 0.7.0.
The icon, banner, gallery 1, gallery 2 and gallery 3 are byte-identical to what is already live, so
their claims are untouched and they must not be re-uploaded.
- Gallery 4 is now **three full rows (7/7/7)** instead of two of seven: the slot size and row pitch
  shrank to fit, and each row is centred on its own count. The
  render enforces this — a label that would run into the next row or into the footer line throws, as
  does a roster that disagrees with `FOOD_MOD_COUNT`. Headline: "Twenty-one mods bridged."
- The seven new icons are the real item textures of items 0.8.0 actually bridges: Kaleidoscope Cookery's
  fried egg, Hearth and Harvest's butter, Cultural Delights' avocado, Cook's Collection's lemon, Rustic
  Delight's red bell pepper, Hybrid Delights' salt and Oh The Biomes We've Gone's blueberries.
  Extracted into `tools/work/tex/` from the jars in `tools/work/jars/` in the same pass.
- **A judgment, not arithmetic:** Oh The Biomes We've Gone is a *worldgen* mod that happens to grow
  food. It is counted because the headline number is the 1.21.1 jar's optional-AFTER list and
  Pantrywork does bridge four of its fruits — but it is not a cooking mod, and the comment beside its
  roster row says so. If that reads wrong on the live page, drop it from the toml and the roster
  together; the render refuses to let the two disagree.
- Gallery 2's craft is unchanged and still true (tagtest-reverse.txt Craft B); gallery 1's "Four
  dialects" is unchanged and still true — 0.8.0's new mods are Farmer's Delight addons using FD's own
  naming, and the new shared salt tag (`c:dusts/salt`) is a fifth *tag name*, not a fifth naming
  dialect. The banner's four cheeses still all reach `#c:foods/cheese`.
- All three regenerated PNGs that carry content claims (banner, gallery 2, gallery 4) were opened and
  read after the run: no label collision, no overflow, no text running off a card.

**0.7.0: replaced the banner, gallery 2 and gallery 4 on BOTH stores.**
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

| File | Caption | Status at 0.9.0 |
|---|---|---|
| `promo/icon-512.png` | Project icon: pantry shelf | unchanged (byte-identical, B4D3454C) |
| `promo/banner-1920x640.png` | Four mods' cheeses converging into one tag | unchanged (byte-identical, 6464C0DC) |
| `promo/gallery-1-one-tag.png` | The two layers: identity tags bridging four dialects, role tags on top | unchanged (byte-identical, 33EEC10C) |
| `promo/gallery-2-four-mod-craft.png` | Pam's Grilled Cheese & Ham crafted with Farm & Charm butter and Brewin' & Chewin' cheese | unchanged (byte-identical, 8E75C1B0). The file name keeps "four-mod" so upload scripts and links still match |
| `promo/gallery-3-role-tags.png` | Recipe JSON targeting `#pantrywork:food_component/protein`, beside the items it accepts | unchanged (byte-identical, 72811F90) |
| `promo/gallery-4-supported-mods.png` | All twenty-four bridged mods, with the "install all, some, or none" promise | **REPLACE** — was twenty-one mods (B61D16D4); now CE7A4FD8 |

**Gallery uploads are manual.** The Modrinth PAT used by `publish.ps1` carries version scopes only
(create/delete versions); the gallery API returns 401 without project-edit scope. CurseForge has no
public gallery API at all. Either upload on each site by hand, or issue a PAT with project-edit
scope if you want this scripted later.

**Counts baked into the art** (`FOOD_MOD_COUNT`, `DIALECT_COUNT` in `tools/GenPromo.java`, plus the
headline strings): re-check these every time a compat module ships — images can't be grepped, so a
stale count survives silently. This release is the proof: "Three dialects" was wrong the moment
Farm & Charm landed.

No card states a Minecraft version. Three cards carry content claims that go stale: gallery 4 states
the bridged-mod count ("Twenty-four mods bridged", derived from `FOOD_MOD_COUNT`) and the roster; gallery
2 shows one specific craft, which must be a craft a suite performs (tagtest-reverse.txt Craft B), and
says "No food mod required."; the banner shows four cheeses reaching `#c:foods/cheese`. Re-check them
every release — images can't be grepped and go stale invisibly. `FOOD_MOD_COUNT` must equal the number
of optional AFTER deps in `src/main/templates/META-INF/neoforge.mods.toml` (Origins is a consumer, not
a bridged food mod, and has the card's footer line to itself): **24 at 0.9.0**, checked both ways in
this pass — counted out of the BUILT jar's `neoforge.mods.toml`, not the template.

---

## Changelog for the uploads

> **0.9.0 — The rest of Pam's HarvestCraft, and a free lunch taken off the menu.** Paste-ready body
> in `tools/changelog-current.md`: Pam's HarvestCraft 2 Crops, Trees and Food Extended, taking the
> roster to 24; Crops' and Trees' ~250 items landing in tag families the pack already reads, with
> Pam's two-level dialect growing the family tags by itself; **Food Extended as the release's point —
> 743 of its 3,472 tag-read ingredient slots now accept other mods' food**, stated as inbound because
> Pantrywork bridges none of its items; the two crafts that prove it (fried onions from Croptopia's
> onion + Cultural Delights' butter, cheese on toast from Croptopia's toast + Meadow's cheese slice);
> five tofu analogues excluded and four canonical tags sanitized, with the members unchanged; the
> tofish fix, said plainly to have been caught before release; what tags cannot fix; and the two
> upstream Pam's bugs.
>
> **0.8.0 — Six more mods, and the wok finally lights.** (shipped 2026-10-08) Paste-ready body in
> `tools/changelog-current.md`: Kaleidoscope Cookery, Hearth and Harvest, Cultural Delights (+ Cook's
> Collection), Rustic Delight and Hybrid Delights; the wok oil tag that gates all 225 of Kaleidoscope's
> wok recipes; Hybrid Delights' salt into 75 recipes and a fifth salt spelling bridged into 36; oils
> and butter into Pam's, Croptopia's and Rustic Delight's slots; **Oh The Biomes We've Gone's
> blueberries into the shared blueberry tag, 8 recipes across Hearth and Harvest and Croptopia, with
> the soul-fruit exclusion stated plainly**; four unreported gaps (cabbage, leafy
> greens, onion, tomato, bell peppers); nothing removed, two swaps newly conditional and three
> conditions widened, each with its reason; what tags cannot fix (including, explicitly, the Cultural
> Delights ↔ Hearth and Harvest butter complaint); and three upstream bugs worth filing.
>
> **0.7.0 — Four more mods, cooked eggs, and swaps that have to be fair.** (shipped 2026-09-14) Was in
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
- Minecraft: 1.21.1 — Pantrywork's own declared NeoForge range is `[21.1.0,)` and is unchanged at
  0.8.0; the release jar is still booted on 21.1.241, the build `tools/neo-server-1211` deliberately
  keeps. What needs a newer NeoForge is the *compat mods*, not Pantrywork: FD 1.3.2 ≥ 21.1.219,
  Croptopia ≥ 21.1.80, Rustic Delight and Hybrid Delights ≥ 21.1.219, and **Cultural Delights 0.18.x
  ≥ 21.1.247** (which is why the dev pin moved there) ·
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
  banner's caption; fixed). **0.8.0 was published to both stores on 2026-10-08** —
  four files each; the full record and its three gotchas are in the release log above. (This
  paragraph read "built, verified and staged … NOT yet published" until 2026-11-03: it described the
  pre-publish state and the publish pass did not come back to it. Audit this section against the
  release log every release — a stale "not yet published" line here is the same failure mode as the
  three store claims the 0.8.0 audit found had been false on the live pages since 0.1.0.)

## Why no Forge build? (paste-ready answer to a recurring question)

Asked again by a player 2026-11-01 ("a Forge 1.20.1 version"). The answer has been the project's
position since the 2026-08-29 roadmap note ("no 1.20.x, pre-`c:`-unification"); the evidence below
was re-checked against the NeoForge/Forge docs on 2026-11-01 so the reply can cite facts, not taste.

**The short reply, paste as-is:**

> Short answer: there won't be a Forge 1.20.1 build, and it's not a packaging decision — on 1.20.1
> the thing this mod does doesn't exist yet.
>
> Pantrywork works by extending the shared `c:` tag convention, so that one mod's cheese satisfies
> another mod's recipe. The `c:` namespace only became the convention in **NeoForge 1.20.5**. On
> 1.20.1 the equivalent namespace is `forge:`, and the `forge:` vocabulary has no food tags at all —
> its crop tags are beetroot, carrot, nether wart, potato and wheat, full stop. There is no
> `forge:foods/*` for a mod like this to extend. 1.20.1 also uses the plural `tags/items/` folder
> where 1.21+ uses singular `tags/item/`, so every file would also be in the wrong place.
>
> So a 1.20.1 build wouldn't be a port — it would be inventing a food-tag vocabulary from scratch
> and hoping twenty other mods adopt it. That's a different mod, and a worse bet for you: on 1.21.1
> the mods you'd want bridged already agree on `c:`.
>
> If you're on 1.20.1 and want cross-mod food recipes working, the honest recommendation is a
> handful of hand-written tag files for your own pack — happy to point at how the tags are laid out
> here so you can copy the shape.

**The facts behind it, if pressed:**

| Claim | Evidence |
|---|---|
| `c:` is a 1.20.5+ convention | NeoForge docs: the 1.20.3/1.20.4 pages say `forge`, the 1.20.6 pages say `c` |
| 1.20.1 has no food tags to extend | the documented `forge:` crop set is beetroot, carrot, nether_wart, potato, wheat |
| path differs too | 1.20.1 `data/<ns>/tags/items/`, 1.21+ `data/<ns>/tags/item/` (singular) |
| it is not a repackage | all 151 payload files would change namespace AND path, and every bridged mod's 1.20.1 jar would need re-reading and re-costing (195 item costs, 249 floors, 14 gates re-derived) |

**One caveat to keep honest:** nobody has proven that *no* 1.20.1 Forge mod reads `c:` tags. The
2026-11-01 check could not reach MinecraftForge's own 1.20.x source, so this rests on documented
convention, not an exhaustive survey. It does not change the conclusion — there is still no
`forge:` food vocabulary to extend — but do not claim "`c:` does not work on 1.20.1" as a fact.

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
run warned again: `CURSEFORGE_PROJECT_ID` was `1616194`, and the script used `1617573`. The 2026-10-06
0.8.0 dry run is recorded in the verification log above.
