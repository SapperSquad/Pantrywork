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
./gradlew build                       # NeoForge jar in build/libs
./gradlew fabricJar                   # Fabric 1.21.1 jar (data-only, no classes)
./gradlew runServer                   # headless dev server + all compat mods (FD, Croptopia+EpheroLib, Pam's, Ocean's/End's Delight, Origins+Jupiter)
./gradlew runServer -PnoCompatMods    # boot-matrix run: no compat mods loaded
```

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
map and blacklist live at the top of the script.

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
