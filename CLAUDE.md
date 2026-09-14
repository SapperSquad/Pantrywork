# Pantrywork

Cross-mod food interoperability layer for NeoForge 1.21.1. Mod id
`pantrywork`, package `com.pantrywork`. The payload is data (tag JSONs in
`src/main/resources/data`), not code — see `docs/TAXONOMY.md` for the
design (identity axis extends `c:foods/*`; role axis
`pantrywork:food_component/*`; dialect bridging via optional tag refs).

## Build / run

Requires JDK 21 — pinned machine-wide via `~/.gradle/gradle.properties`
(`org.gradle.java.home`), same as PhytoForge.

```
./gradlew build                       # NeoForge 1.21.1 jar in build/libs
./gradlew fabricJar                   # Fabric 1.21.x jar (data-only, no classes)
./gradlew fabricJar26                 # Fabric 26.x jar (same payload, 26.x version range)
./gradlew neoJar26                    # NeoForge 26.1-26.2 jar (data-only; template in src/neoforge26)
./gradlew clean build -Prelease fabricJar fabricJar26 neoJar26   # RELEASE: all four, then stage into dist/<version>/
./gradlew runServer                   # headless dev server + every compat mod in build.gradle's dependencies block (see below)
./gradlew runServer -PnoCompatMods    # boot-matrix run: no compat mods loaded
./gradlew runServer -PnoFarmAndCharm  # every compat mod EXCEPT Let's Do Farm & Charm (tagtest-nofandc.txt)
```

NeoForge 26.x metadata gotchas (learned live 2026-08-22): omit `modLoader`/`loaderVersion`
entirely for a no-code jar (lowcodefml still works but warns deprecated); ship BOTH
`logoFile` and `iconFile` (26.1 only knows the former, 26.2 deprecates it — coexistence is
the sanctioned span pattern and silences the warning since 26.2.0.62).

Fabric side: the jar is the same data wrapped in `fabric.mod.json`
(template in `src/fabric/templates`; dev content always excluded). Test
harness: `tools/fabric-server` (Fabric launcher + fabric-api + FD
Refabricated + Croptopia Fabric + EpheroLib, RCON preconfigured same
port/password) with suite `tools/tagtest-fabric.txt` — boot with
`java -Xmx2G -jar fabric-server-1.21.1.jar nogui` from that directory.

NeoForge pin is 21.1.241 (NOT PhytoForge's 21.1.72 — FD 1.3.2 requires
>= 21.1.219, Croptopia >= 21.1.80).

Compat mods come from two places (see `dependencies` in build.gradle):
Modrinth maven (FD) and local jars in `tools/work/jars/` (CurseForge-only
mods; re-fetch instructions in `tools/work/jars/SOURCES.md`). The full dev set:
FD, Croptopia+EpheroLib, Pam's Food Core, Ocean's Delight, End's Delight,
Origins+Jupiter, Let's Do Vinery/Meadow/Farm & Charm+Architectury, Brewin' &
Chewin', Aquaculture 2, and since 0.7.0 Create 6.0.10, Bountiful Fares
3.0.12+NexusLib, Fish of Thieves 21.1.2.1+Cloth Config and Refurbished
Furniture 1.0.22+Framework. Farm & Charm is listed on its own so
`-PnoFarmAndCharm` can drop it; the neoforge.mods.toml templates declare every
food mod as an optional AFTER dep: 14 ids in the 1.21.1 template, 12 in the 26.x one
(the same list minus create and bountifulfares; it still names Pam's, Farm & Charm,
Meadow and the other mods with no 26.x build, which is harmless for optional deps).

## Tag audit (release gate)

```
powershell -File tools\AuditRoles.ps1            # with every compat jar loaded
powershell -File tools\AuditRoles.ps1 -Minimal   # Pantrywork ALONE, no Fabric API
```

Resolves every tag this mod asserts, transitively, and exits nonzero on either
failure class it guards:

1. **Seeds in food tags.** Croptopia files planting seeds *inside* its produce
   tags, so a plain tag reference drags them into our canonical/role tags. Run
   this after any generator or compat-jar change.
2. **Required-but-undefined tag references.** A required ref to a tag nobody
   defines is a hard datapack load failure. `-Minimal` is the case the rest of
   the harness never covered: the mod installed alone, where convention tags
   (`c:foods/berry`, `c:buckets/milk`) simply do not exist.

Seed classification deliberately combines two signals — a name rule alone
condemns `croptopia:roasted_pumpkin_seeds` (real food), and `c:seeds`
membership alone condemns `farm_and_charm:onion` (plantable food). Keep
`Test-IsSeed` in this script and in `GenerateBridges.ps1` in step.

Tags we merely inject into (another mod's dialect tag) are reported as
`upstream` and never fail the build — a datapack cannot subtract members, and
re-classifying another mod's own choices is against the project's own rules.

Since 0.7.0 it also fails on provenance-based classes (every entry is
tagged with the jar it came from, or `pantrywork`; a member "comes from us" when
any path to it passes through a Pantrywork entry):

3. **c:foods/milk shim widening by Pantrywork.** The shim holds `minecraft:milk_bucket` only
   (review CF-1 removed FD's 1/4 bottle). An item the item's OWN mod lists
   directly in its c:foods/milk (Bountiful Fares' coconut_milk_bottle) is reported
   as `UPSTREAM WIDENING`; any other widening fails.
4. **Non-food items routed by us.** Melon/pumpkin blocks, BF's coconut (a sapling
   item), create:honeyed_apple and fishofthieves:mango_pit in ANY tag we assert;
   Refurbished toast/bread_slice/jams only in c:toast, c:toasts, c:jams,
   c:jellies/* (Refurbished's own c:foods/bread holds the slice - its call).
   mango_pit has no current tag path: it is a future-upstream guard, proven live
   only by `GenerateBridges.ps1 -SelfTest`.
5. **Dilution.** An independent, hand-kept table of (tag, item) pairs below a cost
   floor: `never` pairs fail on any Pantrywork path, `gated` pairs fail on a path not
   conditional on a listed mod. It does NOT read cost-floors.json, so an edit there that
   "fixes" a number to hide a dilution still fails here.
6. **Third-mod dependence.** Re-resolves c:fruits without Croptopia and c:dough /
   c:flour without Farm & Charm (and without the overlays only that mod satisfies);
   farm_and_charm:strawberry, croptopia:dough and create:wheat_flour must still be members.
7. **Cost floor.** Re-derives the verdict (tools/CostFloor.ps1 + tools/cost-floors.json)
   for every item on every resolved Pantrywork path into a judged tag, hand-authored refs
   and upstream chains included. EXCLUDE fails; GATE fails unless every path is conditional
   on a rescuing mod (an upstream entry of that mod on the path, or an overlay whose mods
   are all rescuers). Also fails on: an item with no cost, a scanned jar defining a judged
   tag with no declared floor, a DECLARED floor whose mod defines the tag in no scanned jar on
   any line (tools/work/jars, jars-26x, jars-12110; `Test-FloorDefiners` - a fictional floor
   self-rescues its own items for free, which is how FD's bottle stayed in c:foods/milk), a
   Pantrywork entry in a tag cost-floors.json does not know, and pack.mcmeta overlays whose
   `neoforge:overlays` and `fabric:overlays` do not name the same rescuers plus each loader's
   `modAliases` (with `fabric:any_mods_loaded` whenever the Fabric list has more than one id),
   or do not match the directories on disk.

Gated entries: checks 1-6 see a pantrywork_gate_* overlay only when one of its mods is a
scanned jar (never in -Minimal); check 7 walks every overlay.

Check 2 also fails on a bare (REQUIRED) item id from an optional mod in our data.
2, 5 and 6 were mutation-proven on 2026-09-13 (sandbox copies). The cost-floor pass
mutation-proved 5 and 7 in place on 2026-09-13 (each restored by regenerating, generated
tree hash-identical afterwards): Pam's toast re-added to c:toasts, FD's milk bottle
ungated in c:milk, the c:milk overlay gated on the wrong mod, NeoForge/Fabric overlay
declarations disagreeing, a hand ref c:foods/dough -> #c:doughs, cost-floors.json edited
so the toast passes (generator emits it; check 5 catches it), and Meadow's floor deleted
from c:milk (check 7 and the generator both stop).

`powershell -File tools\GenerateBridges.ps1 -ExtraJarDirs tools\work\jars-26x -SelfTest`
plants mango_pit, a c:seeds `_seeds` item, a `_sapling` name and an unvetted
namespace into the fruit tags, plus a 1/100-bucket milk (must be EXCLUDEd) and a
1/4-bucket milk (must be GATEd on Pam's in c:milk), generates into %TEMP% (src/generated
untouched) and exits nonzero if any plant leaks or never reaches a union, an exclusion or
gate is wrong in the written base/overlay files, or pack.mcmeta does not declare exactly
the overlay directories on disk for both loaders. Run it with the audit.

## Cost floors and gates (2026-09-13)

- Data: `tools/cost-floors.json` (every item cost with its recipe, every tag's floor per
  defining mod, conventions, judgment calls). Rule: `tools/CostFloor.ps1`, dot-sourced by
  the generator and the audit. TAXONOMY.md "What a bridge may add" rule 3 explains it.
- Adding a compat jar or a new emit target: rerun the generator. It STOPS (writes nothing)
  on an item with no cost, a target with no cost-floors.json entry, or a jar that defines a
  judged tag without a declared floor. Add the numbers from the jar's recipes; never guess.
- GATEd items ship in `src/generated/resources/pantrywork_gate_<n>/` overlays (numbered; the
  tag ids inside are `pantrywork:gated/<mods joined by _or_>/c/<tag>`, and naming the
  directories after every mod id pushed paths past Windows' 260-char MAX_PATH) declared in
  the generated `src/generated/resources/pack.mcmeta`. Conditions inside tag JSON are
  ignored by every loader (read in the NeoForge and Fabric sources, then booted on six
  loaders): never use them. The "pack" section in pack.mcmeta is mandatory (Fabric drops a
  mod pack whose metadata lacks it), and the vanilla `overlays` key is unconditional.
- build.gradle must ship `pack.mcmeta` and `pantrywork_gate_*/**` in all four jars
  (processResources does it for the NeoForge 1.21.1 jar; fabricPayload and neoJar26 include
  them explicitly). A jar without them silently loses every gated entry.
- Fabric: mod data (overlays included) is loaded by Fabric API's resource loader, so both Fabric
  jars declare `"fabric-api": "*"` (FC1; src/fabric/templates/fabric.mod.json) and publish.ps1 sends
  it as a required dependency. Without Fabric API, Fabric Loader refuses to start and names the
  missing dependency (booted 2026-09-13 on the staged -fabric jar B884D869, exit 1, no world). An
  earlier build WITHOUT that declaration started with Pantrywork listed but inert.
- Mod-id aliases: `modAliases` in cost-floors.json maps a build published under another id to
  its canonical mod (`croptopia-refabricated` -> croptopia, Fabric 1.21.10). Definers, floors and
  gates use the canonical id; each loader's overlay condition also names that loader's aliases
  (Fabric croptopia gate = `any_mods_loaded [croptopia, croptopia-refabricated]`). The generator
  ALWAYS scans `tools/work/jars-12110` (Croptopia Refabricated, FD Refabricated 3.4.2/3.6.13) on
  top of `-ExtraJarDirs`, so an unaliased variant id stops it as an undeclared defining mod.
- Review fixes 2026-09-13 (after the cost-floor pass): c:foods/milk shim = bucket only (CF-1);
  Croptopia Refabricated alias (CF-2); croptopia:ground_pork costs 0 meat (tofu route) and left
  Pam's c:groundmeats/groundpork (CF-3); melon juice re-costed in whole fruit (CF-4; its "Croptopia's
  is back in Pam's c:juices/melonjuice" was REVERSED by the final check FC1-1: the glass bottle is the
  juice's craftRemainder, so it costs 0 and Croptopia's juice is x2.00 below Pam's). FC2-4 (SapperSquad:
  raw gathered produce = 1 base unit): the melon slice is the melon block's drop, so it costs 1 produce and is
  back in c:fruits; Pam's melon juice = 2 slices, Croptopia's = 1, still x2.00 EXCLUDE (at this unit the
  bottle no longer decides it). Mutation-proven in place (each restored, protected tree
  hash identical): a fictional c:toasts floor (generator STOPS, audit fails), the alias data
  renamed (generator STOPS on 35 undeclared croptopia-refabricated definers, audit overlay fail),
  the Fabric gate without the alias and with all_mods_loaded (audit overlay fails), FD's bottle
  back in the shim (checks 3, 5, 7), croptopia:ground_pork back in Pam's ground pork (checks 5, 7).

## One-command verification (GameTest)

```
./gradlew runGameTestServer   # 7 gametests, exits nonzero on failure
```

No gametest skips checks: every compat mod is on the dev classpath unconditionally,
so a missing jar fails through `modItem()`.

`src/main/java/com/pantrywork/gametest/PantryworkGameTests.java` — role tags,
cross-mod identity, reverse bridges, and both foreign-ingredient recipe
resolutions via RecipeManager. Uses the `pantrywork:empty` template
(regenerate with `javac tools/MakeEmptyStructure.java -d tools/work &&
java -cp tools/work MakeEmptyStructure`). Gametest classes, the template,
and test recipes are all stripped from `-Prelease` builds (verified).

## Live testing (RCON harness)

The dev server runs with RCON on port 25575, password `pantrywork`
(`run/server.properties`; `run/eula.txt` pre-accepted). Wait for
`RCON running` in `run/logs/latest.log` — and **delete latest.log before
boot-detection loops**, stale logs from the previous run false-positive.

```
tools\rcon.ps1 -Command "say hi"           # one-off command
tools\rcon.ps1 -File tools\tagtest.txt > t.out     # scripted suite
powershell -File tools\CountSuite.ps1 -Suite tools\tagtest.txt -Output t.out   # classify it
```

`tools\CountSuite.ps1` pairs every answer with its suite line: "Test passed" = passed; an answer
matching an `# expect: <text>` comment directly above the command = expected; ANYTHING else
("Test failed", an unannotated "Unknown item tag", "No entity was found", a syntax error, a
missing answer) = failed, and an annotated line that answers "Test passed" also fails. Exit 1 on
any failure, on a suite/output mismatch, or on 0 classified lines (a 0/0 suite DID NOT RUN).
Closed-gate probes are written `execute if items ... #pantrywork:gated/...` with stone in the
slot plus `# expect: Unknown item tag`, so a LEAKED overlay answers "Test failed" (review TV-3).

Test suites (all re-verified green 2026-09-13 for 0.7.0 on the dev server;
**every crafter check needs two `time query gametime` lines after the redstone
pulse** — with Create/BF/FoT/Refurbished loaded the crafter tick lands after the
next RCON command, so unpadded checks failed while the follow-up kill still
reported the result; tagtest-multi/-reverse, crafttest and tagtest-nofd were padded):
- `tools/tagtest.txt` — FD + vanilla tag membership (chest + `execute if items`)
- `tools/tagtest-nofd.txt` — vanilla-only run for `-PnoCompatMods` boots
- `tools/tagtest-multi.txt` — dialect bridges with Croptopia + Pam's, tri-mod craft
- `tools/tagtest-reverse.txt` / `tools/crafttest-reverse.txt` — reverse
  bridges: foreign items in dialect tags + real Croptopia/Pam's recipes
  crafted with foreign ingredients (the crafttest variant pads with dummy
  commands so contents checks land after the crafter tick)
- `tools/tagtest-feedback.txt` — 0.7.0 player-feedback bridges (Create, Bountiful
  Fares, Fish of Thieves, Refurbished Furniture, cooked eggs), the melon/pumpkin
  block fix, every cost-floor EXCLUDE that needs no Farm & Charm id (milk, cheese/
  butter, cuts and fillets, Pam's toast/oil/pasta, Croptopia's apple and melon juice (FC1-1), Croptopia's
  ground pork out of Pam's ground pork, the cabbage leaf, Ocean's Delight slices in c:foods/raw_fish;
  the melon slice is IN c:fruits since FC2-4: raw gathered produce = 1 unit), the
  GATEs whose gate mods are on both dev boots (FD milk in c:milk/c:milks, Pam's cheese; its Pam's
  salt line is reachability only, see the gates suites), and three crafts. Runs on BOTH the full
  and -PnoFarmAndCharm boots, so it holds no
  farm_and_charm id and no F&C-gated assertion (create:dough in c:doughs moved to letsdo)
- `tools/tagtest-letsdo.txt` — also holds the Farm & Charm cost floors (F&C cuts in
  Pam's tags, FD cuts against F&C's own floors, roasted_chicken out of Pam's
  c:cookedchicken AND FD's c:foods/cooked_chicken, F&C dough/pasta/farmer's bread out of
  FD's canonical tags, bacon_with_eggs out of c:cookedpork, cooked buffalo meat out of
  c:foods/cooked_meat), F&C corn in c:foods/corn and create:dough in c:doughs (gate open);
  full boot only
- `tools/tagtest-nofandc.txt` — Farm & Charm independence; only meaningful on a
  `runServer -PnoFarmAndCharm` boot (21/0 there), incl. Pam's bread from croptopia:dough
  without F&C and the Farm & Charm GATE closed live: Create, FD and Pam's dough OUT of
  c:doughs, still in c:dough. NOT vacuous on a full boot any more: there F&C opens that
  gate, so exactly the three `unless #c:doughs` lines fail (18/3, measured 2026-09-13) -
  the gate proven open and closed by the same three lines; any other failure is a bug
- `tools/tagtest-gates.txt` + `tagtest-gates-s1..s5.txt` — cost-floor gates on the
  NeoForge 1.21.1 RELEASE jar, one boot per scenario on tools/neo-server-1211 (S1 FD +
  Meadow; S2 + Pam's; S3 + Pam's + Croptopia; S4 FD + Meadow + Croptopia without Pam's;
  S5 Create ALONE - the only boot where the flour gate is closed while Create's flour exists;
  run only s5 there); scenario jars and expected counts are in the tagtest-gates.txt header.
  Gate proofs assert the overlay's OWN tag (`#pantrywork:gated/croptopia/c/vegetables`,
  `.../c/salts`) wherever a third mod's ref also reaches the item: Croptopia's c:vegetables ->
  #c:cabbage -> FD's #c:crops/cabbage reaches the cabbage leaf and Croptopia's c:salts -> #c:salt
  reaches Pam's salt with no overlay at all (review TV-1)
- `tools/tagtest-fabric-gates.txt` — the Fabric gate overlays at tag level, for Fabric harnesses
  WITH a Croptopia build (fabric-server, -12110 with Croptopia Refabricated, -2612, -262): 12
  passed + 4 expected (CountSuite)
- **FC2-4 re-cut 2026-09-13 (CURRENT: the jars in dist/0.7.0 and all eight harness mods folders; booted,
  see the FC2 boot matrix block right below).** SapperSquad's rule "raw gathered produce = 1 base unit": minecraft:melon_slice 1/5 -> 1 produce,
  Pam's melon juice 0.4 -> 2, Croptopia's 1/5 -> 1. Resolver: the slice PASSes c:fruits (x1.00, back as in
  0.6.0); c:juices/melonjuice <- croptopia:melon_juice 1 vs 2 = x2.00, still EXCLUDE. Generator (documented
  command) exit 0: 88 tag files + pack.mcmeta, 11 GATE / 45 EXCLUDE / 7 rescued PASS, only
  data/c/tags/item/fruits.json changed; -SelfTest passed; AuditRoles full 556 routes / 14 gates / 79 guard
  pairs, -Minimal 505 / 11 / 70, every counter 0 (check 5's (fruits, melon_slice) row removed;
  tagtest-feedback's slice line is now `execute if ... #c:fruits`, same 203 count; GameTest asserts the slice
  IN c:fruits). `gradlew clean build -Prelease fabricJar fabricJar26 neoJar26 --no-daemon`: pantrywork-0.7.0.jar
  8DDE4467859590019FD6031C8BA8B07818E76387, -fabric B884D869B237DB2588D6A8BBDABC4CEEEB7B47B5, -fabric-mc26
  ACC303CCEAC34B049DA87EA3446FBD71539FADF2, -neoforge-mc26 C3828E60ADD63C93078B5D4A27B86530DD19F2A8; each 126
  payload files (117 data + pack.mcmeta + 8 overlay files; FC1 removed juices/melonjuice.json) byte-identical
  to src, 0 missing/extra/differing/duplicate, no gametest/test recipe/structure, gate_1..5 for both loaders
  (Fabric gate_3 names croptopia-refabricated), "fabric-api" in both fabric.mod.json, croptopia:ground_pork in
  origins:meat, version 0.7.0, authors SapperSquad. Replaced jars (6993E4FB / F666A5AA / D79D4686 / 3E101DD7)
  moved to scratch, not deleted. publish.ps1 dry run (-SkipCurseForge) exit 0: four files resolve, Modrinth
  Fabric API (P7dR8mSH, required) on the two Fabric files only.
- **FC2 boot matrix 2026-09-13 (CURRENT, on the FC2-4 jars above; every boot result in the blocks below ran
  EARLIER bytes and is SUPERSEDED).** Counts re-derived in the docs pass by running tools\CountSuite.ps1 on
  every saved suite output (scratchpad fc2dev / fc2neo / fc2fab runs). Clean world + fresh logs per boot,
  stopped via RCON, java exited and 25575 free after each; every dedicated server's Pantrywork jar was
  SHA-1-checked against dist/0.7.0 before boot. DEV (source tree; its 126-file payload is 0 missing / extra
  / differing against all four dist jars): full `runServer` tagtest 14, multi 14, reverse 18 (Craft B kill
  2, negative craft no entity), crafttest-reverse 4, crafttest 4, addons 8, origins 11 (older blocks say 10),
  letsdo 49, brewaqua 24, seedfix 10, collisions 17, milkshim 15, feedback 203 (egg sandwich, bread from
  Create dough and banana nut bread killed; the melon slice line passes) = 13 suites 391/0; nofandc 18/3
  (the three open-gate `unless #c:doughs` lines). `-PnoFarmAndCharm`: nofandc 21/0, feedback 203/0.
  `-PnoCompatMods`: tagtest-nofd 5/0. `runGameTestServer`: "All 7 required tests passed". Recipes loaded
  5856 / 5686 / 1291 / 5857. neo-server-1211 (21.1.241, 8DDE4467): solo tagtest-neo26 5/0 + tagtest-nofd
  4/1 (the cake line, by design); S1 gates 12/0 + s1 5/0; S2 12/0 + s2 12/0; S3 12/0 + s3 16/0 (grilled
  cheese, kill 2); S4 12/0 + s4 7/0 (smoothie, kill 2); S5 s5 6/0 + 1 expected. neo-server-2612 (26.1.2.94,
  C3828E60; Croptopia 4.3.1 + EpheroLib 1.3.0 + Aquaculture 2.9.2): neo26-compat 7/0, neo26-gates 6/0 + 4
  expected; solo neo26 5/0. neo-server-262 (26.2.0.64; + Fish of Thieves 26.2.1.1, Refurbished 1.0.25):
  compat262 5/0, neo26-feedback 37/0 (Pineapple Chicken + Banana Smoothie killed, half_pineapple
  negative no entity), neo26-gates 6/0 + 4 expected; solo neo26 5/0. Fabric Loader 0.19.3: fabric-server
  1.21.1 (B884D869; FD Refab 3.3.3, Croptopia 4.2.4, API 0.116.14) tagtest-fabric 7/0 + fabric-gates 12/0 +
  4 expected; -12110 (Croptopia Refabricated 0.10.0, FD Refab 3.4.2, API 0.138.4) 7/0 + 12/0 + 4; -12111
  (FD Refab 3.6.13, API 0.141.6) tagtest-fabric-fd 9/0; -2612 (ACC303CC; API 0.155.2) and -262 (API
  0.156.0) 7/0 + 12/0 + 4 each; the FD-milk smoothie killed its result (2 entities) on all four Croptopia
  boots. No-Fabric-API boot (scratch copy of fabric-server, the dist -fabric jar alone): "Mod resolution
  failed", "Incompatible mods found!", Pantrywork 0.7.0 "requires any version of fabric-api, which is
  missing!", exit 1, no world. Logs (all 19 boots): zero lines matching pack.mcmeta, overlay,
  pantrywork_gate, pantrywork:gated, "Couldn't load tag", "Failed to load", "Missing data pack" or
  "Tried to load invalid"; WARN/ERROR lines are harness baseline.
- **Critic C1 doc fixes 2026-09-13 (docs only; payload, tests and jars unchanged).** Resolver
  scratchpad fc2crit\measure.ps1 (+ measure2/3): dist 0.6.0 jars against the staged 0.7.0 jars over 30
  installs (20 NeoForge 1.21.1 subsets on 21.1.241; the five Fabric harness sets plus 26.1.2 FD-only;
  neo-server-2612/-262 sets plus 26.2 Croptopia+FD and FD-only), loader tags included, recipe readers
  matched in `"tag":` and `"#tag"` form over 40 jars. C1-1: c:cabbage / c:onions / c:tomatoes / c:rice
  are read only by Croptopia recipes (4.2.4 and Refabricated 6/16/19/9; 4.3.1 builds 8/17/19/13), are
  identical in 0.6.0 and 0.7.0 wherever Croptopia loads, and removing the four generated files leaves
  every recipe-read tag unchanged in all 30 installs: store copy no longer lists them. C1-2: c:foods/milk
  readers are Bountiful Fares 1.21.1 (cocoa_cake + its minecraft:cake override) and FD Refabricated
  3.4.2's own 9 recipes on 1.21.10, where FD keeps its bottle; no FD addon reads it. C1-3: optional AFTER
  deps = 14 in the 1.21.1 template/jar, 12 in 26.x (minus create, bountifulfares). C1-4:
  create:wheat_flour in c:flour, 0.6.0/0.7.0: all mods Y/Y, no F&C n/Y, no BF+F&C+Pam's n/n,
  Create+Croptopia n/n, +F&C Y/Y, +Pam's n/Y, +BF n/Y, Create alone undef/n.
- **Re-cut 2026-09-13 (after the review-fix pass; SUPERSEDED bytes, see FC2-4 above).** Preflight: generator
  (documented command) hash-identical, AuditRoles full and -Minimal exit 0. `gradlew clean build -Prelease
  fabricJar fabricJar26 neoJar26 --no-daemon` reproduced the review-fix SHA-1s EXACTLY (the build is
  byte-reproducible), so every result in the review-fix block below ran the shipped bytes. dist/0.7.0
  re-staged from build/libs and inspected: 127 payload files each (118 data + pack.mcmeta + 8 overlay tag
  files) identical to src, pantrywork_gate_1..5 declared for both loaders (Fabric gate_3 names
  croptopia-refabricated), no test recipe/structure/gametest entries, version 0.7.0, authors SapperSquad,
  no personal-name string. Gap boots on these bytes (clean world, CountSuite): fabric-server-2612
  tagtest-fabric 7/0 (smoothie, game time 177->180, kill 2) + fabric-gates 12/0 + 4 expected;
  neo-server-1211 solo tagtest-neo26 5/0; neo-server-2612 solo and neo-server-262 solo tagtest-neo26 5/0
  each (compat jars moved to scratch and back, SHA-1s identical before/after, worlds wiped afterwards).
  Every dedicated harness has now run the shipped jars; only the no-Fabric-API boot (loader behaviour)
  was on an earlier build. Promo: gallery 2's "Zero hard dependencies." is now "No food mod required."
  (Fabric needs Fabric API); only that PNG changed. Store copy, CHANGELOG, README and TAXONOMY
  rewritten against a 0.6.0-vs-0.7.0 membership diff (TAXONOMY "What changed for players").
  `tools\publish.ps1 -Version 0.7.0 -ChangelogFile tools\changelog-current.md -DryRun -SkipCurseForge`: exit
  0, all four jars resolved (0.7.0+mc1.21.1, +mc1.21.x-fabric, +mc26-fabric, +mc26), dependencies empty (Fabric API
  goes on the two Fabric files by hand; PUBLISHING says so).
- **Review-fix pass 2026-09-13 (SUPERSEDED by FC2-4 + the FC2 boot matrix above: older bytes, 127-file
  payload, origins 10, s3 15; it had itself superseded the three cost-floor-pass blocks below).** Generator (documented command) 89 tag files, 11 GATE / 45 EXCLUDE / 7 rescued
  PASS, re-run hash-identical; -SelfTest passed; AuditRoles full 556 routes / 14 gates proven, -Minimal
  505 / 11, every counter 0. `gradlew clean build -Prelease fabricJar fabricJar26 neoJar26`:
  pantrywork-0.7.0.jar SHA1 6993E4FB2058D770B38B821975C146F88C89596E, -fabric F666A5AA989223F549C45F0BAF132355C29E01FA,
  -fabric-mc26 D79D46861C404BD70E8BF484747B7C46EF337EFE, -neoforge-mc26 3E101DD78E5EEB6941253C02DA9C05BBDA68556D;
  each 127 payload files (118 data + pack.mcmeta + 8 overlay tag files) byte-identical to src, no
  duplicates, no gametest/test recipe/structure. These exact bytes are staged in dist/0.7.0 and in
  all eight harness mods folders (replaced jars moved to scratch, not deleted). Every suite classified
  with tools\CountSuite.ps1; clean world + fresh logs per boot; stopped via RCON; java confirmed exited.
  DEV full `runServer`: tagtest 14, multi 14, reverse 18, crafttest-reverse 4, crafttest 4, addons 8,
  origins 10, letsdo 49, brewaqua 24, seedfix 10, collisions 17, milkshim 15, feedback 203 - all 0
  failed; nofandc 18/3 (the three open-gate lines, by design). `-PnoFarmAndCharm`: nofandc 21/0,
  feedback 203/0. `-PnoCompatMods`: tagtest-nofd 5/0. `runGameTestServer`: all 7 required tests passed.
  Every craft's kill reported its result. neo-server-1211 (release jar): S1 gates 12/0 + s1 5/0; S2
  12/0 + s2 12/0; S3 12/0 + s3 15/0 (grilled cheese, kill 2); S4 12/0 + s4 7/0 (smoothie, kill 2); S5
  (Create alone) s5 6/0 + 1 expected. neo-server-262: compat262 5/0, neo26-feedback 37/0 (Pineapple
  Chicken + Banana Smoothie killed), neo26-gates 6/0 + 4 expected. neo-server-2612: neo26-compat 7/0,
  neo26-gates 6/0 + 4 expected. fabric-server-12110 (Croptopia Refabricated): tagtest-fabric 7/0 (game
  time 191->194, kill 2) + fabric-gates 12/0 + 4 expected - CF-2 RESOLVED. fabric-server-12111:
  tagtest-fabric-fd 9/0. fabric-server (1.21.1): tagtest-fabric 7/0 + fabric-gates 12/0 + 4.
  fabric-server-262: tagtest-fabric 7/0 + fabric-gates 12/0 + 4. Logs: harness baseline only (dev: 136
  FoT translations, refmaps, Origins stacking_effect, knives/twilightforest tags, offline mode; 5856
  recipes), zero lines about pack.mcmeta, overlays or gated tags. Not re-booted in this pass (fabric-server-2612 and the
  NeoForge solo boots were closed by the re-cut block above): the no-Fabric-API boot (its result -
  mod inert without Fabric API - is about the loader, measured on the cost-floor jar).
- SUPERSEDED (earlier bytes; see the FC2 boot matrix): Cost-floor pass, NeoForge 1.21.1 DEV matrix re-run 2026-09-13 (clean world + fresh
  latest.log per boot; generator re-run first, src/generated hash-identical; both audits
  and -SelfTest exit 0). Full `runServer`: tagtest 14, multi 14, reverse 18 (incl. the
  negative craft: Pam's grilled cheese and ham refuses croptopia:cheese), crafttest-reverse
  4, crafttest 4, addons 8, origins 10, letsdo 49, brewaqua 24, seedfix 10, collisions 16,
  milkshim 15, feedback 202 - all 0 failed; nofandc 18/3 (the expected open-gate lines, see
  above). `-PnoFarmAndCharm`: nofandc 21/0, feedback 202/0. `-PnoCompatMods`: tagtest-nofd
  5/0. `runGameTestServer`: all 7 required tests passed. Every craft's follow-up kill
  reported its result (+ tool remainder); log scans on all four boots held only harness
  baseline (FoT missing translations, mixin refmaps, Origins stacking_effect decode, "Not
  all defined tags ... c:tools/knives" / twilightforest biome tag, offline mode) and zero
  lines about pack.mcmeta, overlays, pantrywork_gate_* or pantrywork:gated tags
- SUPERSEDED (earlier bytes; see the FC2 boot matrix): Cost-floor pass, NeoForge RELEASE jars 2026-09-13 (`gradlew clean build -Prelease neoJar26`;
  pantrywork-0.7.0.jar SHA1 7AE7D2A3..., -neoforge-mc26 SHA1 C95C77BA...; neither holds
  gametest classes, the test recipe or the structure; both carry pack.mcmeta + 8 overlay tag
  files and a data payload byte-identical to src). Clean world + fresh logs per boot, stopped
  via RCON, java confirmed exited. neo-server-1211: solo tagtest-nofd 4/1 (the cake line, by
  design on a release jar) + tagtest-neo26 5/0; S1 gates 12/0 + s1 4/0; S2 12/0 + s2 11/0; S3
  12/0 + s3 13/0 (grilled cheese from Pam's cheese, kill 2 entities); S4 12/0 + s4 6/0 (banana
  smoothie with FD milk, kill 2 entities). neo-server-2612: compat 7/0, neo26-gates 6 + 4
  expected; solo neo26 5/0. neo-server-262: compat262 5/0, feedback 37/0 (both crafts killed
  their result), neo26-gates 6 + 4 expected; solo neo26 5/0. Every log: harness baseline only,
  zero lines about pack.mcmeta, overlays or gated tags.
- SUPERSEDED (earlier bytes; see the FC2 boot matrix): Cost-floor pass, FABRIC jars 2026-09-13 (`gradlew fabricJar fabricJar26`; -fabric SHA1 CF2E3A03...,
  -fabric-mc26 SHA1 5BF344B3...; each 127 payload files byte-identical to src/main + src/generated, 8
  overlay tag files, no test recipe/structure/classes, no duplicate entries). All five Fabric harnesses
  now hold these jars (1.21.10 and 1.21.11 had the 0.1.0 jar until then). Clean world + fresh logs per
  boot, stopped via RCON, java confirmed exited. fabric-server (1.21.1): tagtest-fabric 7/0 (FD-milk
  smoothie crafted, kill 2 entities). fabric-server-12111: tagtest-fabric-fd 9/0, negatives proven
  non-vacuous (c:milk, c:milks, c:rawpork defined: stone probes "Test passed"; all 8 gated tags
  "Unknown item tag"). fabric-server-2612 and -262: tagtest-fabric 7/0 each. With Croptopia loaded,
  gate probes gave 12 passed + exactly 4 closed-gate "Unknown item tag" answers on 1.21.1, 26.1.2 and 26.2.
  Fabric WITHOUT Fabric API (fabric-server, Pantrywork alone, jars restored afterwards): `datapack list`
  = [vanilla (built-in)] only, "Missing data pack pantrywork" WARN (from initial-enabled-packs), every
  Pantrywork tag incl. gated ones "Unknown item tag" - the mod is inert, nothing leaks ungated (that jar
  had no fabric-api dependency; since FC1 Fabric Loader refuses to start instead, see the FC2 boot matrix).
  RESOLVED in the review-fix pass (was OPEN here): on fabric-server-12110 (1.21.10) this jar went
  tagtest-fabric 5/2 because Croptopia Refabricated's mod id `croptopia-refabricated` never opened the
  Fabric croptopia gate. Fixed by `modAliases` (the Fabric condition now also names that id) and the
  generator always scanning tools/work/jars-12110; measured 7/0 + fabric-gates 12/0 + 4 expected on the
  release jar (see the review-fix block above). Side note, 1.21.10 only: FD Refabricated 3.4.2 tags its
  milk bottle c:foods/milk, not c:drinks/milk, so the bottle reaches the dairy role there only through the
  (now opening) croptopia gate's c:milks.
- fabric-server-12110 and -12111 now set `pause-when-empty-seconds=-1` like the 26.x harnesses (a paused
  server never ticks crafters, so the 1.21.10 smoothie check would be vacuous).

Reverse-bridge data is GENERATED: `tools/GenerateBridges.ps1` (rerun after
compat-jar updates; writes src/generated/resources incl. pack.mcmeta and the gate
overlays, + tools/work/bridges-report.txt with every GATE/EXCLUDE and its ratios). The
category map and the non-food denylist live at the top of the script, the cost floors in
tools/cost-floors.json; the rules are written up in TAXONOMY.md "What a bridge may add".
ALWAYS run it as
`powershell -File tools\GenerateBridges.ps1 -ExtraJarDirs tools\work\jars-26x`:
0.6.0 shipped without Aquaculture 2.9.x's largemouth bass because a run left the
flag out (`tools\work\jars-12110` needs no flag: the script always scans it). The flag unions the 26.x compat jars in
(26.x-only items like Aquaculture 2.9.x's largemouth bass enter the
bridges; on older lines those entries are required=false and skip). One
payload ships to every jar. After a jar update, read the report's
`dropped unvetted` lines: they name upstream ids for mods nobody has examined.

## NeoForge 1.21.1 release-jar harness (tools/neo-server-1211)

NeoForge 21.1.241 dedicated server, installed with the NeoForge installer; RCON
25575/pantrywork like every harness, flat world, chest at 8 -60 8. Launch from the dir
with JDK 21: `& "C:\Program Files\Java\jdk-21.0.11\bin\java.exe" @user_jvm_args.txt
@libraries/net/neoforged/neoforge/21.1.241/win_args.txt nogui`. First booted 2026-09-13
(clean on the release jar alone). The dev runServer only ever proved the dev classpath;
this is where the `-Prelease` jar (test recipe and gametests stripped) boots, and where
the cost-floor gates are proven closed and open: swap compat jars from tools/work/jars
into mods/ per the scenarios in tools/tagtest-gates.txt, one clean boot each. On a
release jar tagtest-nofd.txt's cake crafter check cannot pass (the dev test recipe is
stripped); assert purity on the unconsumed input the way tagtest-neo26.txt does.

## 26.x server harnesses (release-jar verification)

Per-line dedicated servers under tools/, all RCON on 25575/pantrywork,
one at a time: `fabric-server-2612`, `fabric-server-262` (launch:
`java -Xmx2G -jar fabric-server-<mc>.jar nogui`, JDK 25+), and
`neo-server-2612` (NeoForge 26.1.2.94 — ATM11's exact build),
`neo-server-262` (26.2.0.64), installed via the NeoForge installer
(launch from the dir: `java @user_jvm_args.txt
@libraries/net/neoforged/neoforge/<ver>/win_args.txt nogui`, use
jdk-26.0.1). Suites: `tagtest-neo26.txt` (solo boot: vanilla role tags +
release purity via a powered crafter), `tagtest-neo26-compat.txt`
(croptopia+epherolib+aquaculture — the ATM11 pair), `tagtest-neo26-compat262.txt`
(croptopia only; no Aquaculture on 26.2 yet), `tagtest-fabric.txt` (both
fabric 26.x harnesses, incl. the FD-milk smoothie craft).
`tagtest-neo26-gates.txt` (both NeoForge 26.x harnesses WITH Croptopia, never solo): no GATEd
item has a NeoForge 26.x build, so the gate overlays are proven at the tag level - the four
croptopia-gated `pantrywork:gated/*` tags exist (6 passed incl. two native-member checks) and
the four closed-gate lines answer exactly "Unknown item tag" (expected; any other answer is a bug).
`tagtest-neo26-feedback.txt` (0.7.0, neo-server-262 only): Fish of Thieves
fruits into Croptopia's c:fruits / per-fruit tags, mango_pit/half_pineapple/
raw_mango exclusions, Refurbished cheese/dough/flour/salt in, toast/bread_slice/
jam out, Croptopia milk_bottle/soy_milk NOT in c:milk or c:drinks/milk (but still
in the dairy role), Croptopia cheese/butter NOT in c:cheese/c:butter (c:milk,
c:cheese and c:butter exist there only via Pantrywork's own files), plus two
Croptopia crafts with FoT fruit (shaped pineapple_chicken, shapeless
banana_smoothie) and a half_pineapple negative.
neo-server-262 now also carries Fish of Thieves 26.2.1.1 + Cloth Config 26.2.155
and Refurbished 1.0.25 + Framework 0.13.26 (list + hashes in
`tools/neo-server-262/HARNESS-MODS.txt`); compat262 still passes with them.
SUPERSEDED (review F11): an early 2026-09-13 "release smoke" recorded here (fabric 7/0 x3,
neo-2612 compat 7/0, neo-262 compat262 5/0 + feedback 37/0) ran jars from BEFORE the cost-floor
pass; the current jars and their measured results are in the "FC2-4 re-cut" and "FC2 boot matrix"
blocks above.
Boot recipe for any harness: delete
`logs\latest.log`, launch from the harness dir with jdk-26.0.1, wait for
`RCON running`, run the suite, send `stop`, then scan the log.
26.2 gotcha: `execute unless items entity @e[...]` with no matching entity ERRORS
("No entity was found") instead of passing - assert crafter negatives on the
unconsumed input slot, never on an empty entity selector.

**26.x harness gotcha:** dedicated servers pause when empty
(`pause-when-empty-seconds=60` default) — a paused server still answers
RCON and passes tag checks, but crafters never tick, so craft asserts
pass/fail vacuously. All four harnesses set `pause-when-empty-seconds=-1`;
assert tick flow with two `time query gametime` lines before trusting any
crafter result. Also: `execute if items ... container.N <item>` takes the
item predicate directly (no `with` keyword — that's `item replace` syntax).

Conventions used by the suites: chest at `8 -60 8` for membership checks
(no player needed headless); crafter at `8 -60 12` + redstone block at
`9 -60 12` for recipe tests. Crafter results race the 150ms RCON cadence —
the authoritative signal is the follow-up `kill @e[type=item]` reporting
what it killed.

## Promo art

`java tools/GenPromo.java` regenerates everything in `promo/` (icon,
banner, four gallery cards) from code + the real item textures in
`tools/work/tex/` (extracted from the compat jars and the vanilla client jar:
`assets/<ns>/textures/item/<name>.png` saved as `<ns>__<name>.png`, vanilla and
the original set unprefixed, e.g. `porkchop.png`; re-extract if missing). Same
philosophy as ReelRivals' GenCards.java: art with content claims must be
regenerable, never a source-less PNG. ASCII-only file. Claims baked into art:
- gallery 4 (`galleryRoster`) is the supported-mod roster. Its headline is
  derived from `FOOD_MOD_COUNT`, and the render throws if the roster disagrees.
- gallery 2 (`galleryCraft`) shows one cross-mod craft, which must be a craft a
  suite actually performs (0.7.0: tagtest-reverse.txt Craft B). Cost-floor
  changes can make it untrue; 0.7.0's did. Its headline counts the mods in that
  craft, and vanilla is not a mod ("Three mods and vanilla. One sandwich.").
- `fitOrFail` throws when text is wider than its space. Still Read every PNG
  after regenerating: a label collision shipped once.

## Gotchas

- `pantrywork:test/universal_sandwich` (recipe) is dev-only tooling for the
  crafter tests — REMOVE before any release.
- All cross-mod tag/item references must be `{"id": …, "required": false}`;
  the `-PnoCompatMods` boot is the regression test for that. Wipe
  `run/world` before that boot: leftover test chests holding modded items
  log a spurious (harmless) "Tried to load invalid item" ERROR that makes
  the log scan look dirty.
- Never make dialect tags reference canonical tags (cycle risk) — see
  TAXONOMY.md "one-directional". The only refs the generator writes into dialect
  tags point at our own `pantrywork:gated/*` item lists.
- Never add a hand-authored ref from a canonical tag to a dialect tag that holds an
  item below the canonical tag's floor: route it through a judged `pantrywork:bridged/*`
  enumeration (forwardSanitized in the generator). AuditRoles check 7 fails otherwise.
- 1.21.1 data layout: `tags/item` and `recipe` (singular), ingredient
  format `{"tag": "…"}` (the string `#` form is 1.21.2+).
