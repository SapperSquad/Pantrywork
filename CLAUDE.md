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
./gradlew runServer                   # headless dev server + all compat mods (FD, Croptopia+EpheroLib, Pam's, Ocean's/End's Delight, Origins+Jupiter)
./gradlew runServer -PnoCompatMods    # boot-matrix run: no compat mods loaded
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
mods; re-fetch instructions in `tools/work/jars/SOURCES.md`).

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

## One-command verification (GameTest)

```
./gradlew runGameTestServer   # 5 gametests, exits nonzero on failure
```

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
tools\rcon.ps1 -File tools\tagtest.txt     # scripted suite
```

Test suites (all verified green 2026-07-19):
- `tools/tagtest.txt` — FD + vanilla tag membership (chest + `execute if items`)
- `tools/tagtest-nofd.txt` — vanilla-only run for `-PnoCompatMods` boots
- `tools/tagtest-multi.txt` — dialect bridges with Croptopia + Pam's, tri-mod craft
- `tools/tagtest-reverse.txt` / `tools/crafttest-reverse.txt` — reverse
  bridges: foreign items in dialect tags + real Croptopia/Pam's recipes
  crafted with foreign ingredients (the crafttest variant pads with dummy
  commands so contents checks land after the crafter tick)

Reverse-bridge data is GENERATED: `tools/GenerateBridges.ps1` (rerun after
compat-jar updates; writes src/generated/resources + a report). Category
map and blacklist live at the top of the script. Pass
`-ExtraJarDirs tools\work\jars-26x` to union the 26.x compat jars in
(26.x-only items like Aquaculture 2.9.x's largemouth bass enter the
bridges; on older lines those entries are required=false and skip). One
payload ships to every jar.

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
banner, three gallery cards) from code + the real item textures in
`tools/work/tex/` (extracted from the compat jars — re-extract if
missing). Same philosophy as ReelRivals' GenCards.java: art with content
claims must be regenerable, never a source-less PNG. ASCII-only file;
supported-mod claims in gallery 3 must be re-checked when modules change.

## Gotchas

- `pantrywork:test/universal_sandwich` (recipe) is dev-only tooling for the
  crafter tests — REMOVE before any release.
- All cross-mod tag/item references must be `{"id": …, "required": false}`;
  the `-PnoCompatMods` boot is the regression test for that. Wipe
  `run/world` before that boot: leftover test chests holding modded items
  log a spurious (harmless) "Tried to load invalid item" ERROR that makes
  the log scan look dirty.
- Never make dialect tags reference canonical tags (cycle risk) — see
  TAXONOMY.md "one-directional".
- 1.21.1 data layout: `tags/item` and `recipe` (singular), ingredient
  format `{"tag": "…"}` (the string `#` form is 1.21.2+).
