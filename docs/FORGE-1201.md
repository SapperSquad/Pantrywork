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

## The jar builds, and the audit found a real blocker (2026-11-05)

`gradlew forgeJar1201` produces **pantrywork-0.9.0-forge-mc1201.jar**, 56,848 bytes, 113 payload
files (112 data + `pack.mcmeta`), zero singular `tags/item` paths, zero classes, 21 optional
AFTER deps. `META-INF/mods.toml` (not `neoforge.mods.toml`), `modLoader = "lowcodefml"`,
`mandatory = true|false` not `type =`, loader dep `forge` - every one of those read out of real
1.20.1 jars rather than from documentation.

`AuditRoles.ps1` now takes `-Platform forge1201` too, with the same identity model: tag identity
is recorded in the `c:` spelling on both lines, so one set of checks and one set of cost
judgments serve both. Modern stays green, full and `-Minimal`. Normalising the definer map was
again the thing that mattered - before it, 137 of the 138 cost-floor failures and all 15 seed
violations were phantoms.

**What it then caught is real, and it blocks shipping: 30 dilution failures and 1 cost-floor
failure.** They share one cause, and it is upstream version drift:

| Croptopia | what its `doughs` tag contains |
|---|---|
| 4.0.1 (1.20.1) | `croptopia:dough`, **`#forge:dough`** - it REFERENCES the singular tag |
| 4.2.4 (1.21) | `croptopia:dough` only |

The generator correctly EXCLUDEs `pamhc2foodcore:doughitem` from `c:doughs` (0.6 wheat against
Croptopia's 2.1 floor, x3.50) and correctly PASSes it into `c:dough`, where Create's 2/3 floor
is lenient. On 1.21 that is safe. On 1.20.1 Croptopia's own `doughs` pulls in everything from
`dough`, so the entry we legitimately wrote to the lenient tag arrives in the strict one anyway,
below its floor. Same shape for the milk, pasta and vegetable failures.

**The cost model needs the effective floor to be the strictest floor across the tag being
written AND every tag that references it transitively.** Writing item X into tag B is only safe
if X clears the floor of every A that can reach B.

**This is a latent hole on 1.21 as well, not only here.** It is unexercised there purely because
Croptopia dropped that reference between 4.0.1 and 4.2.4 - nothing in the model prevents another
mod from adding one tomorrow and quietly diluting a canonical tag. Fixing it benefits both
platforms, and because it changes floor semantics on a build that is already published, it is a
deliberate decision rather than a porting detail: **do not slip it in with the port.**

Dropping the GATEd entries was necessary but is not sufficient on a gate-less platform, for the
same reason: severing the direct entry does not sever an upstream reference path.

## Both platforms green (2026-11-06)

`-Platform forge1201` now passes the generator **and** the full audit: every counter 0, the new
check 8 included. Modern is untouched throughout - byte-identical payload, audit green full and
`-Minimal`, `-SelfTest` passed.

| | modern | forge1201 |
|---|---|---|
| generator | exit 0, 42 GATE / 91 EXCLUDE / 12 rescued PASS | exit 0, 19 GATE (all dropped) / 63 EXCLUDE / 21 rescued PASS |
| audit | exit 0 (full and `-Minimal`) | exit 0 |
| payload | unchanged | 107 files, jar 54,037 bytes |

Getting there turned up three things worth keeping.

**A platform overlay must never make a floor more lenient.** The first overlay nulled every
floor whose mod does not define that tag on 1.20.1. That is right only when the tag still has a
strict definer. It was wrong 49 times: `c:vegetables` kept only Rustic Delight, whose own
`forge:vegetables` lists its bell-pepper SLICES, so the slice became its own floor and every
half-cut passed trivially. Worse, **23 judged tags lost every floor**, and a judged tag with no
floor excludes nothing - `forge:foods/*` is almost entirely Pantrywork's own canonical layer on
1.20.1, so there is no upstream definer to derive one from. Both are fixed by carrying the base
floor across marked `unscanned`, with the reason stated: strictness can then only increase.

**The "declares no floors" guard must apply on every platform.** It had been relaxed for
non-modern platforms, which is how those 23 tags went quiet. Restored. The hand-kept dilution
table is what caught it, which is exactly why that table does not read `cost-floors.json`.

**"Already present" has to mean present without a third mod.** On a gate-less platform we must
not re-inject what a tag already holds - that adds nothing in game and makes Pantrywork the
author of a path it did not create, which the dilution guard then reports. But following every
reference is worse: it made `farm_and_charm:strawberry` look already-present in `forge:fruits`
when only Croptopia's chain delivered it, so skipping the injection silently made that bridge
conditional on Croptopia - caught by check 6. The rule that satisfies both: follow a reference
only when **every** definer of the referenced tag also defines the parent. Rustic Delight's own
`forge:vegetables/bell_pepper` qualifies; `forge:strawberries`, which Croptopia and Farm & Charm
both write, does not. This applies on forge1201 only - switching it on for 1.21 rewrites 62
files of a published payload and moves the verdicts, which is a decision about a shipped build,
not a porting detail.

## Check 8: the stricter-referrer guard

A judged tag that references a LOOSER judged tag is a hole no per-tag check can see: anything
we legitimately put in the looser one arrives in the stricter one below its floor. Croptopia
4.0.1's `forge:doughs` referenced `forge:dough` exactly so (floors 2.1 against 0.094) and the
reference was gone by 4.2.4.

Measured before adding it: **0 such edges on 1.21 across 193 judged references**, 1 on 1.20.1
(now resolved by the floor carry-over). So this is a guard against upstream changing its mind,
not a fix for a standing fault - which is why the 1.21 floor semantics were left alone rather
than rebuilt. **Mutation-proven**, the way the project proves its other checks: loosening
`c:foods/cabbage` to 1/16 while `c:foods/leafy_green` (which is exactly `#c:foods/cabbage`)
stays at 1/2 makes it fail with one precise line, and restoring the file makes it pass again.

## Stamped at 0.10.0 (2026-11-06)

`mod_version` 0.9.0 -> **0.10.0**, `gradlew forgeJar1201` ->
`pantrywork-0.10.0-forge-mc1201.jar`, 54,037 bytes, SHA-1 **04870274482D21048055BB0F4F86C4244BA2FF93**,
staged in `dist/0.10.0`.

The bump is provably version-string-only: hashing both builds entry by entry, **1 of 110 non-empty
zip entries differs, and it is `META-INF/mods.toml`**. The suites and probe pack regenerate
byte-identical from the new jar, so the generator is keying off payload content and not a
filename. All three scenarios and every static gate were still re-run on the staged bytes - solo
50/0 with a clean log, compat 338/0, control identical at 31 upstream errors, 0 naming us,
generator and audit exit 0 on both platforms with modern byte-identical. The full record is in
PUBLISHING.md under "0.10.0 - verification record".

The four 1.21.1 / 26.x jars were **not** rebuilt: they stay published at 0.9.0, and
`publish.ps1 -Only forge` keeps the release to the one file.

## Booted and suite-tested (2026-11-06)

The last open item was a 1.20.1 Forge harness. It exists now:
`tools/forge-server-1201` (Forge 1.20.1-47.4.28, installed with the official installer, RCON
25575/pantrywork and the flat peaceful world every other harness uses), driven by
`tools/boot-forge1201.ps1`.

| scenario | mods/ | result |
|---|---|---|
| `-Scenario solo` | the forge jar alone | **50 passed / 0 failed**, and a log with 0 errors of any class |
| `-Scenario compat` | + the 18 loadable roster jars | **338 passed / 0 failed** |
| `-Scenario control` | the 18 jars, Pantrywork REMOVED | upstream error set byte-identical to compat |

Three things about the harness are worth knowing before touching it.

**It needs JDK 21, not the machine default.** Forge 1.20.1 is javafml 47 and will not start on
JDK 26. The script passes `C:\Program Files\Java\jdk-21.0.11` explicitly, the same JDK
`tools/neo-server-1211` uses. It also launches from an `@argfile` under `libraries/` rather than
a server jar, which is why it is scripted at all when the NeoForge and Fabric harnesses are
hand-booted.

**The suites cannot look like `tagtest.txt`, because the commands those use do not exist here.**
`execute if items` and `minecraft:crafter` are both 1.21. Tag membership on 1.20.1 is asserted
through a predicate on an armor stand's mainhand - `tools/testpack-1201`, a test instrument that
holds predicates and no tag of its own and is never shipped, copied into `world/datapacks` by
the boot script before the world loads. Both suites and the probe pack are generated by
`tools/GenForge1201Suites.py` (Python, like `GenPromo.java` is Java; the reasoning is in its
header) and say "re-derive, do not hand-edit" because they are.

**Every assertion is phrased to answer "Test passed".** Inside an `execute as` fork 1.20.1
*swallows* the "Test failed" message, so a failed assertion answers nothing at all. That is
sound - `tools/CountSuite.ps1` already counts a missing answer as failed - but it means
`# expect:` annotations would classify wrongly here, so positives use `if` and negatives use
`unless` and the suites carry no annotations. The one practical trap: regenerating the probe
pack while a server is up leaves the world on the stale copy, and the suite then comes back
~300 empty answers. Both the generator and the boot script now say so.

### The suite was mutation-proven on the port's own central hazard

A green suite proves nothing until it can fail. The mutation used is the exact thing the port is
about: rebuild the forge jar with the **1.21 singular `data/<ns>/tags/item/`** path instead of
1.20.1's plural `tags/items/`, changing nothing else. 1.20.1 ignores that path entirely.

Result: **39 failed / 11 passed** - every one of the 39 positives collapses, and exactly the 11
negatives survive, which they must, because an empty tag satisfies a negative. That is also the
argument for keeping the positives: the negatives alone would have called a completely dead
payload green.

### What the compat boot found: `forge:doughs` is two doughs, not six

The first compat run (314 assertions, before the probe set was widened below) failed 3, all on
`forge:doughs`, and the cause turned out to be two
independent things stacking - both correct behaviour, neither a bug:

1. **Pantrywork deliberately does not inject them.** All four cheap doughs
   (FD 1.083, Kaleidoscope 1.013, Pam's 0.6, Create 2/3) undercut `forge:doughs`' Croptopia
   floor of 2.1 wheat, so they are GATE verdicts - legitimate only alongside Farm & Charm, which
   declares its own 0.094 floor. 1.21 ships that condition as a pack overlay. **Pack format 15
   has no overlays**, so on this line the entries are dropped, exactly as designed above.
2. **Upstream then drops its own edge.** Croptopia's `forge:doughs` references `#forge:dough`
   *optionally*, and Kaleidoscope's `forge:dough` references `#forge:doughs` back - a cycle. The
   game resolves it by discarding the optional edge, in silence.

Measured end state: `forge:dough` holds all six doughs; `forge:doughs` holds two (Croptopia's
own and the one Pantrywork injects ungated). **This is a real capability difference between the
1.21 jar and the 1.20.1 jar** - with Farm & Charm installed, 1.21 unifies doughs and 1.20.1
cannot - and it is the first place the 19 dropped GATE entries are observable in game. It is now
asserted as a negative in the compat suite with the reason attached, so delivering it later is a
deliberate, visible change. Store copy for the Forge build should say this plainly rather than
imply overlay parity.

### The probe set was filtering to `forge:`, and the wok gate went unasserted

Found 2026-11-06 while writing store copy, which is the point of writing store copy: the claim
wanted was Kaleidoscope's wok, and nothing backed it. `gen_compat` built its tag list as
`[t for t in ours if t.startswith('forge:')]`, so the three tags the payload writes in *mod*
namespaces were never probed - `kaleidoscope_cookery:oil`, `rusticdelight:cooking_oil` and
`origins:meat`. The first of those is the single highest-value bridge in the payload: the wok
checks it before it will cook, and all 225 of Kaleidoscope's wok recipes are behind it. It is the
headline of the 0.8.0 release and it had no coverage on this line at all.

Now `[t for t in ours if not t.startswith('pantrywork:')]` - everything except the role layer,
which the role and umbrella sections already cover. Compat went **314 -> 338 assertions over 83
tags**, all passing, and the wok tag is confirmed to hold six mods' oils: Kaleidoscope's own plus
Cook's Collection, Croptopia's olive oil, Hearth and Harvest, Pam's and Rustic Delight. Solo
re-ran 50/0 unchanged (the probe pack is additive, so widening compat cannot disturb it).

One thing the new coverage surfaced, which is upstream's call and not a fault: Pam's Food
Extended's firm tofu reaches `origins:meat`. It gets there because Food Extended itself writes
`forge:groundmeats` -> `#forge:groundmeats/firmtofu`, and our `origins:meat` references that
family - the same shape as Croptopia listing its own tofu in `croptopia:meat_replacements`. The
cost floor does not apply: a carnivore diet tag is not a recipe ingredient tag.

### Upstream noise on the compat boot, and the control that attributes it

The compat boot carries **31 errors, none of them ours**. Rather than argue that from reading
them, `-Scenario control` boots the same 18 jars with Pantrywork removed: the error set comes
back **byte-identical**, 31 for 31, with nothing unique to either side. The script also counts
ERROR/FATAL lines naming `pantrywork` on every boot, and that count is 0 in all three scenarios.

- **16 TagLoader missing-reference errors** from `pamhc2foodextended`, which lists
  `pamhc2crops:*`/`pamhc2trees:*` items as bare required strings. Those two mods have **no Forge
  1.20.1 build at all** - their only 1.20.x builds declare javafml `[49,)` where 1.20.1 supplies
  47, measured by trying them (the full table is in `tools/work/jars-1201/SOURCES.md`). So this
  is permanent on this line, it vindicates leaving both ids out of the optional-dependency list
  in `src/forge1201/templates/META-INF/mods.toml`, and no Pantrywork tag references any of the
  16 - checked, 0 refs, so nothing of ours cascades.
- **6 recipe parse errors** from the two Pam's jars, including `pamhc2foodcore` failing to find
  its *own* `caramelcupcakeitem`.
- **4 empty-file + 5 loot-table parse errors** from `culturaldelights` 0.16.7, which ships
  zero-byte `data/minecraft/recipes/*.json` overrides to delete vanilla recipes. NeoForge 1.21
  has real recipe removal; 1.20.1 just fails to parse an empty file.
