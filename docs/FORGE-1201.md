# Pantrywork on Forge 1.20.1 — measurement and design

**Status: GREENLIT 2026-11-04 by SapperSquad, after the measurement below disproved the reason
the port had been refused since 2026-08-29.** Ships as a fifth file on the existing Modrinth /
CurseForge pages (`0.10.0+mc1.20.1-forge`), alongside the four 0.9.0 files — SapperSquad's call.

## Why the old refusal was wrong

`PUBLISHING.md` carried a paste-ready answer saying a 1.20.1 build was impossible because
"1.20.1 has no food tags to extend — the documented `forge:` crop set is beetroot, carrot,
nether_wart, potato, wheat". That is the crop set the **platform** documents. It is not what the
**food mods** ship. The mods extended `forge:` themselves on 1.20.1, exactly as they later
extended `c:`.

The old answer even flagged its own gap ("nobody has proven that *no* 1.20.1 Forge mod reads `c:`
tags") and that gap is precisely where it was wrong. The project's standing rule — **measure the
jars, do not quote the docs** — would have caught it. It is the one claim that never got measured.

Proof, from the mod that defines the convention everything else follows:

| Farmer's Delight branch | tag class | namespace |
|---|---|---|
| `1.20` | `ForgeTags.java` (+ `CommonTags.java`) | **`forge`** |
| `1.21` | `ForgeTags.java` **deleted**; `CommonTags.java` | **`c`** |

FD 1.20 declares **64** `forge:` tags, including `forge:crops/{cabbage,onion,rice,tomato}`,
`forge:vegetables/*`, `forge:milk`, `forge:milk/milk_bottle`, `forge:dough`, `forge:pasta`,
`forge:grain`, `forge:raw_fishes/*`, `forge:cooked_fishes/*`, the four raw and four cooked meats,
`forge:eggs`, `forge:berries`, `forge:bread`, `forge:salad_ingredients`. That is the same
two-level `<family>` + `<family>/<leaf>` shape Pantrywork bridges today.

**So 1.20.1 is a port, not an invention.**

## The measurement (19 jars, `tools/work/jars-1201`)

Downloaded 2026-11-04 from Modrinth. Scanned as data only.

| Measure | Result |
|---|---|
| `forge:` item-tag files | **957** |
| `c:` item-tag files | 58 — almost all Let's Do (F&C 35, Meadow 13, Vinery 6) + FoT 4, which dual-publish |
| Distinct **food** tag paths under `forge:` | **336** |
| Distinct food tag paths under `c:` | 32 |
| Path form | `data/<ns>/tags/items/` (**plural**) — all 1541 files |

Per-jar `forge:` tag counts worth knowing: Pam's Food Extended **393**, Pam's Food Core **196**,
Hearth and Harvest 88, Farmer's Delight 67, Create 42, Rustic Delight 38, Farm & Charm 35,
Kaleidoscope Cookery 34, Aquaculture 18, Meadow 15.

Pam's speaks the **same concatenated dialect** under `forge:` that it speaks under `c:` on 1.21 —
`forge:cheese/cheese`, `forge:cheese/silkentofu`, `forge:milk/freshmilk`, `forge:berries/*`,
`forge:citrusfruits/lemon`. Farm & Charm dual-publishes its underscored dialect into both
namespaces. So the dialect map transfers nearly 1:1.

## The job exists on 1.20.1 — same collisions

| Family | Shared-namespace spellings | Cross-refs between them |
|---|---|---|
| cheese | 7 | **2** |
| milk | 7 | 5 |
| onion | 4 | **0** |
| tomato | 8 | (FD-only `forge:vegetables/tomato`) |

- **Hearth and Harvest files its cheese in `forge:foods/cheese`, which nothing references.** Its
  cheese slices are invisible to Pam's and Meadow's cheese recipes. This is the canonical
  Pantrywork fix.
- `forge:vegetables/onion` is Farmer's Delight-only; Farm & Charm's onion reaches
  `forge:crops/onion` but not the vegetable family.
- **`forge:cheese/silkentofu` and `forge:butter/silkentofu` exist on 1.20.1**, so the tofu-as-dairy
  cost-floor hazard — the one 0.9.0 just fixed on the fish side — is present here too, and the
  existing judgments in `tools/cost-floors.json` largely carry over.

## Design

Mirror the 1.21 payload, changing exactly three things:

1. **Namespace** `c:` → `forge:` for the identity layer. Canonical becomes **`forge:foods/*`**,
   which is not invented: Hearth and Harvest already uses `forge:foods/cheese`.
2. **Path** `tags/item/` → `tags/items/` (plural). This is a silent killer in both directions —
   a plural path on 1.21 is dead, a singular path on 1.20.1 is dead.
3. **Role layer** keeps its own namespace (`pantrywork:food_component/*`) unchanged — it is ours,
   so it is version-independent.

The generator (`tools/GenerateBridges.ps1`) should take a target-platform switch rather than being
forked, so one source of truth emits both payloads. The cost floors must be **re-derived against
the 1.20.1 recipes**, not copied: the mods are at different versions (FD 1.3.4 not 1.3.2, Pam's
1.0.5/1.0.1, Cultural Delights 0.16.7 not 0.18.1) and the recipe ratios can differ.

## Roster gaps on 1.20.1

- **Croptopia** and **Refurbished Furniture** did not resolve on Modrinth's API (only addons
  surface). Fetch from CurseForge before building — Croptopia matters, it is one of the four
  dialects.
- **Bountiful Fares** is Fabric-only on 1.20.1 (7 versions, 0 forge).
- **Pam's HC2 Crops and Trees have no 1.20.1 build at all** — the two modules 0.9.0 just added are
  1.21-only, so the 1.20.1 roster is smaller than 24.
- Pam's Food Core / Food Extended ship as `1.20.4` files tagged for 1.20–1.20.4, which **includes
  1.20.1**. Those are the right jars.

## Built so far (2026-11-04)

`GenerateBridges.ps1` now takes **`-Platform modern|forge1201`**. Modern is the default and its
output is **byte-identical** to before the change (re-verified after every edit: 111 tag files,
42 GATE / 91 EXCLUDE / 12 rescued PASS, `git status src/generated` clean).

What the switch changes, and nothing else:

| | modern (1.21+) | forge1201 |
|---|---|---|
| shared namespace (`$SharedNs`) | `c` | `forge` |
| tag path segment (`$TagSeg`) | `item` | `items` |
| jars read | `tools/work/jars` | `tools/work/jars-1201` |
| output root | `src/generated/resources` | `src/generated/forge1201` |

The key design decision: **tag identity is always recorded in the `c:` spelling**, whatever
namespace the line uses. The cost-floor keys, the floor-definer check and the planting /
food-evidence seed rules all reason about identity, so normalising on ingest is what lets one set
of judgments serve both platforms instead of forking 249 floors. Only reading and writing use
`$SharedNs`. The hand-authored tree stays the single source of truth in its `c:` spelling and has
its refs retargeted on a forge1201 run.

Two real bugs fell out of this, both now fixed:

- **`Get-JarModIds` only read `META-INF/neoforge.mods.toml`.** Forge 1.20.1 names it
  `META-INF/mods.toml`. Every 1.20.1 jar was therefore falling back to its *filename* as the mod
  id, which made every declared floor look fictional and every definer look undeclared — 418
  phantom problems on the first run, down to 134 once the 1.20.1 spelling was read.
- **Accepting both `tags/item/` and `tags/items/` in one scan was wrong.** It made the 1.21 run
  read files the game ignores: Let's Do Vinery ships a dead plural `tags/items/milk.json` in its
  1.21 jar, which registered Vinery as a definer of `c:milk` and stopped the modern build. The
  scan now reads exactly the path form that platform's game reads.

## The remaining work, measured not estimated

A forge1201 run reaches the cost gate and stops there with **134 problems** — which is the
guardrail doing its job, not a failure. Broken down:

- **39 STALE** — a 1.20.1 jar defines a judged tag and no floor is declared for that mod. These
  are genuine "read the recipe out of the jar" decisions: farmersdelight 17, kaleidoscope_cookery
  7, rusticdelight 4, fishofthieves 3, create 2, croptopia 2, hearthandharvest 2, vinery 1,
  aquaculture 1. Tags include `c:dough`, `c:flour`, `c:milk`, `c:eggs`, `c:pasta`, `c:grain`,
  `c:fruits`, the cooked and raw meats.
- **89 FICTIONAL** — a floor is declared for a mod that defines no such tag on 1.20.1. Three
  causes, and only the third needs judgment: (a) the mod does not exist on 1.20.1 at all —
  `pamhc2crops` 14, `pamhc2trees` 8, `bountifulfares` 10, 32 in total, so those floors simply do
  not apply on this platform; (b) `neoforge` 7, which is the platform's own tags and maps to
  Forge/vanilla on 1.20.1; (c) genuine version differences, led by `farmersdelight` 22 — FD 1.3.4
  does not file everything FD 1.3.2-on-1.21 files.
- **6 UNKNOWN** — items with no cost: `hearthandharvest:cheese_slice` and `:goat_cheese_slice`
  (in both `c:cheese` and `c:cheeses`), `farm_and_charm:sausage_with_oat_patty` in `c:cookedbeef`,
  `hearthandharvest:raisin_cookie` in `c:cookies`.

**This needs a per-platform floor model** — a floor that is real on 1.21 and absent on 1.20.1 is
not a fiction to delete, it is scoped. The shape to add is a platform overlay in
`cost-floors.json` rather than a second file, so the 1.21 judgments stay the base and only the
differences are stated. Every number still comes out of a 1.20.1 recipe: **do not copy a 1.21
floor across on the assumption the recipe is unchanged** — the versions differ (FD 1.3.4 not
1.3.2, Cultural Delights 0.16.7 not 0.18.1, Croptopia 4.0.1 not 4.2.4).

## The floors are done (2026-11-04)

A forge1201 run is **green: exit 0, 113 payload files** (73 generated + 39 hand-authored,
translated + pack.mcmeta), all valid JSON, no `c:` id anywhere in the tree. Modern stays
byte-identical.

- **4 item costs**, each read from a 1.20.1 recipe: `hearthandharvest:cheese_slice` and
  `:goat_cheese_slice` at 1/4 milk_bucket (fermenting 1000 mB milk + salt -> unripe wheel,
  aging -> wheel, cutting -> 4 slices; 1000 mB is one bucket, the same number Meadow's slice
  reaches the same way), `hearthandharvest:raisin_cookie` at 1/4 wheat (2 wheat + raisins -> 8,
  vanilla's cookie shape), `farm_and_charm:sausage_with_oat_patty` at 1 meat (2x minced beef
  -> 2 patties).
- **39 floors** derived, **89 scoped out** with null. They live in a new `platformFloors`
  section so the 1.21 base stays strict - an `unscanned` reason would have excused those floors
  on 1.21 too, where they must keep failing. The two checks cross-verify: null a floor for a mod
  that DOES define the tag on 1.20.1 and STALE FLOORS fires instead.
- Two rules had to be honoured while picking floors, and getting either wrong would have
  silently lowered one: a tag **default** covers an item with no explicit cost (the fish tags
  carry `default: 1`, which is what the tofish bug rode), and a definer listing only tag
  **refs** still has a floor - but those refs must be resolved through **that mod's own files
  only**. Following the merged view instead made Farmer's Delight's `c:raw_fishes` floor
  `kaleidoscope_cookery:sashimi` at 1/3 rather than its own cod slice at 1/2, and a lower floor
  lets cheaper items through.
- A 0-cost plant analogue is still never a floor: `croptopia:soy_milk` was skipped on
  `c:milk` in favour of its 1/16 milk bottle.

**1.20.1 has no pack overlays, so the conditional swaps cannot ship there.** Vanilla gained
overlays in 1.20.2 (pack format 18) and NeoForge's conditional variety is 1.20.5+; 1.20.1 is
format 15. Shipping a GATEd entry unconditionally would put a below-floor item into a tag
whenever its rescuer is absent - exactly what the floor exists to stop - so the generator drops
them on this platform and names each in the report. Five are affected: Pam's cheese and salt
(needed Croptopia), Hearth and Harvest's flour and corn meal (needed Create or Farm & Charm),
and Farmer's Delight's cabbage leaf. `pack.mcmeta` is written as bare `pack_format: 15` with no
overlay section at all.

Verdicts on 1.20.1: **5 GATE (all dropped), 67 EXCLUDE, 27 rescued PASS** - and
`pamhc2foodextended:rawtofishitem` is EXCLUDEd here too, so the 0.9.0 tofish fix carries over.

## Open before the first build

- Fetch the two missing jars, then re-run the scan so the dialect map is complete.
- Decide the canonical set: mirror all of `c:foods/*`, or only the families the 1.20.1 roster
  actually populates.
- A 1.20.1 Forge test harness (the existing ones are 1.21.1 NeoForge, 26.x and Fabric).
