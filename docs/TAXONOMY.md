# Pantrywork Tag Taxonomy

Design snapshot 2026-07-19. Grounded in what NeoForge 21.1.241, Farmer's
Delight 1.21.1-1.3.2, Croptopia 4.2.4, and Pam's HC2 Food Core 1.0.4
actually ship (dumps in `tools/work/*-ctags.txt` / `*-ctag-names.txt`).

## The core finding: dialects, not absence

The research assumption ("food mods share no compat layer") needed
refinement once the jars were opened: the big food mods DO ship `c:` tags —
Croptopia 701 files, Pam's 196, FD ~70 — they just use three incompatible
naming dialects that never reference each other:

| Concept | Official (NeoForge/FD) | Croptopia | Pam's |
|---|---|---|---|
| raw pork | `c:foods/raw_pork` | — | `c:rawpork`, `c:rawmeats/rawpork` |
| cheese | (none) | `c:cheeses` | `c:cheese` |
| dough | `c:foods/dough` | `c:doughs` | `c:dough` |
| flour | (none) | `c:flour` | `c:flour` ← natural collision between these two (Create's `c:flours` still needed a bridge — 0.7.0) |
| fruit | `c:foods/fruit` | `c:fruits/*` | `c:fruits/*` |

So Pantrywork is a **dialect bridge**: each canonical tag (official naming)
includes the dialect tags as optional tag references. No per-item
enumeration for bridged categories, and any items those mods add later
flow through automatically.

Bridging is **one-directional at the tag level** (dialect → canonical):
making dialect tags also include canonical ones would create tag
reference cycles, which fail to load. The reverse direction — a Croptopia
recipe requiring `c:cheeses` accepting Pam's cheese — is handled by
`tools/GenerateBridges.ps1`, which emits **item-level** optional entries
into each dialect tag (88 tag files in `src/generated/resources` as of 0.7.0, 8 of
them in conditional pack overlays,
report in `tools/work/bridges-report.txt`; rerun after any compat-jar update,
always with `-ExtraJarDirs tools\work\jars-26x`). Its
category map was chosen from what the mods' recipes actually consume
(488 Croptopia + 200 Pam's recipes scanned). A blacklist keeps items the
target mods plausibly excluded on purpose (pufferfish, golden foods) out
of every injection; 0.7.0 widened it to non-food blocks and saplings (see
"What a bridge may add"). Verified live 2026-07-19: Croptopia's grilled
cheese crafts with Pam's cheese; Pam's grilled-cheese-and-ham crafts from four
mods' ingredients, tool remainders intact. Since 0.7.0 that craft is skillet +
vanilla bread + Farm & Charm butter + a Brewin' & Chewin' cheese wedge + a
porkchop. The original version (Croptopia butter/cheese + FD bacon) fails the
economic floor, and a negative craft proves Pam's recipe now refuses
Croptopia cheese.

Bonus finding from the recipe scan: several categories looked like they
already interoperated with no bridge, because the mods coincidentally picked
identical tag names that merge at load (`c:flour`, `c:salt`/`c:salts`,
`c:tomatoes`, `c:onions`, `c:rice`, `c:vegetables`, the `c:fruits` parents).
Through 0.6.0 Pantrywork left those alone.

**0.7.0 correction:** a merge only covers the mods that declare the name
*directly*. Create files its flour under `c:flours`, so `c:flour` reached it
only through Farm & Charm's `c:flour -> #c:flours` reference, and Refurbished
Furniture's flour carried no `c:` tag at all; Bountiful Fares' maize sat in `c:foods/corn`,
which no consumer reads. The generator now also emits into those shared names
(`c:flour`, `c:flours`, `c:salt`, `c:salts`, `c:tomatoes`, `c:onions`, `c:rice`,
`c:vegetables`, `c:cabbage`, `c:crops/corn`, `c:fruits`), adding only items the
name does not already list directly. Duplicate entries are harmless (tag loading
de-duplicates). Salt, tomato, onion, rice, vegetables and cabbage were already
emit targets before 0.7.0; the generator's skip bug (rule 1 below) was what kept
their files from being written. In play the `c:cabbage`, `c:onions`, `c:tomatoes` and
`c:rice` files change nothing (re-measured 2026-09-13, critic C1-1): only Croptopia's
recipes read those names on every scanned line, Croptopia's own definitions already reach
every item the files add, and removing the four files from the 0.7.0 jars leaves every
recipe-read tag unchanged in all 30 scanned installs. What may be added is governed by "What a bridge
may add (0.7.0)" below.

## Two axes, two namespaces

**Identity axis — `c:` namespace.** What an item *is*. NeoForge already
ships a `c:foods/*` convention (raw_meat, cooked_meat, bread, fruit,
vegetable, soup, pie, berry, cookie…) populated with vanilla items, and
Farmer's Delight extends it heavily, including species-level flat names
(`c:foods/raw_pork`, `c:foods/cooked_bacon`, `c:foods/dough/wheat`,
`c:foods/leafy_green`). **FD's naming is the de-facto standard — follow it
exactly, never invent a parallel taxonomy.** New categories the convention
lacks (cheese, flour, butter, sweetener…) are added as new `c:foods/*`
subtags and joined to the `c:foods` parent.

**Role axis — `pantrywork:` namespace.** What an item *does in a dish*:

```
pantrywork:food_component/protein      #c:foods/cooked_meat + cooked_fish + cooked_egg
pantrywork:food_component/starch       #c:foods/bread + cooked_rice + pasta + baked_potato
pantrywork:food_component/dairy        #c:buckets/milk + drinks/milk + milk + milks + cheese + butter
pantrywork:food_component/garnish      #c:foods/vegetable + berry + leafy_green
pantrywork:food_component/liquid_base  water/milk buckets + broths + sauces
pantrywork:food_component/sweetener    sugar + honey
pantrywork:food_component              parent: all of the above
```

Role tags are **tags-of-tags over the identity axis**. That's the
leverage: any mod that joins (or already follows) the `c:foods/*`
convention automatically feeds every role tag, with zero per-mod work
here. Per-mod compat modules only ever populate identity tags.

Kept under `pantrywork:` rather than `c:` per the handoff's open decision —
promote to `c:food_component/*` only if the convention gets outside
adoption (migration is mechanical).

## Rules

1. **All cross-mod references are optional** — `{"id": …, "required": false}`
   on any item or tag from another mod. Pantrywork must load cleanly with any
   subset of supported mods installed. References to vanilla, NeoForge-shipped
   `c:` tags, or our own tags may be required.
2. **Never re-classify another mod's own tag choices** (e.g. FD deliberately
   left ham out of `c:foods/raw_pork` — that's their call). Compat modules
   fill *gaps*, they don't override.
3. **Naming follows FD/NeoForge precedent**: singular (`berry` not
   `berries`), species as flat suffix names (`raw_pork`), preparation as
   prefix (`cooked_`), subtypes as nested paths (`dough/wheat`).
4. Recipes (including the dev-only `pantrywork:test/universal_sandwich`, which
   must be removed before release) target tags, never mod item IDs.

## Per-mod module status (verified live 2026-07-19)

| Mod | Ships c: tags | Bridge status |
|---|---|---|
| Farmer's Delight 1.3.2 | yes — official dialect, the naming standard | gap-fill only (`c:foods/cooked_rice`); verified |
| Croptopia 4.2.4 | yes — 701 files, plural dialect (`cheeses`, `doughs`) | parent-category bridges verified (cheese/dough/flour/fruit/vegetable/milk) |
| Pam's HC2 Food Core 1.0.4 | yes — 196 files, concatenated dialect (`rawpork`, `cookedbeef`) | full dialect map bridged + verified |
| Ocean's Delight 1.0.4 | no — zero c: tags | per-item identity module (raw/cooked fish, soups); verified |
| End's Delight 2.6.1 | yes — FD-style, but exotic meats not joined to parents | tag-ref gap-fill into `raw_meat`/`cooked_meat`; verified |
| Origins (NeoForge) 0.3 | n/a — consumer, not producer | `origins:meat` fed from canonical tags; verified (carnivore can eat modded meat) |
| FD Refabricated 3.3.3 (Fabric) | yes — mirrors FD's dialect | covered by the FD bridges; verified on the Fabric build |
| Let's Do Vinery 1.5.3 | **no — zero c: tags** | per-item module: grapes/cherry → `c:foods/fruit`, 9 juices + cider → `c:drinks` |
| Let's Do Farm & Charm 1.1.23 | yes — 39 tags, **third dialect: flat-underscored** (`c:raw_pork`, `c:cooked_beef`) | full dialect map bridged both ways; verified |
| Let's Do Meadow 1.4.8 | yes — 12 tags using our bridged names (`cheese`/`cheeses`/`milk`/`salt`) | flows in unmodified; gap-fill for buffalo meat. Its 6 cheese + 13 salt recipes now accept foreign ingredients |
| Aquaculture 2 2.7.21 | yes — **official dialect** (`c:foods/raw_fish` w/ 27 fish, `c:foods/cooked_fish`) | fish already canonical + role; the generator propagates its 27 fish into the Pam's/Ocean's/F&C fish dialects |
| Brewin' & Chewin' 4.5.0 | yes, but into its **own `brewinandchewin:` namespaced tags** (cheese wedges/wheels, `fermented_drinks`) | cheese wedges → `c:foods/cheese` (the ripe wheels are food-less blocks and never bridged since the cost-floor pass), 16 drinks → `c:drinks`; soups already canonical; 0.7.0: preserves → Pam's `c:jellies/*` flavour slots |
| Create 6.0.10 (0.7.0) | yes — `c:foods/dough` (official), `c:flours` (plural) | dough/flour → Pam's `c:dough`/`c:flour`, Croptopia's `c:doughs`/`c:flour`; `honeyed_apple` denylisted; 1.21.1 only (no 26.x build); verified |
| Bountiful Fares 3.0.12 (0.7.0) | yes — plural leaves under the official path (`c:foods/oranges`, `c:foods/corn`), plus `c:flour` | maize → corn tags; orange/lemon/plum/elderberry/walnut ↔ Croptopia's per-fruit tags; `cooked_egg` → `c:foods/cooked_egg`; its `coconut` (a sapling item) denylisted; ids for unexamined mods in its tags dropped; 1.21.1 only; verified |
| Fish of Thieves 21.1.2.1 / 26.2.1.1 (0.7.0) | yes — generic only (`c:foods/fruit`, `c:fruits/sweet`, raw/cooked fish) | fruit → `c:fruits`; whole banana/coconut/mango/pineapple → Croptopia's `c:fruits/<fruit>` via `extra` (half_pineapple, raw_mango stay generic); `mango_pit` denylisted; fish → Pam's/Croptopia/F&C fish dialects; verified on NeoForge 1.21.1 and 26.2 |
| Refurbished Furniture 1.0.22 / 1.0.25 (0.7.0) | **no** food tags of its own (only `bread_slice` in `c:foods/bread`) | cheese/wheat_flour/sea_salt/dough by name via `extra`; toast, bread_slice and jams never bridged; its own recipes use exact ids; verified on NeoForge 1.21.1 and 26.2 |

### The generator follows non-`c:` tags now

Brewin files its cheese behind `brewinandchewin:foods/cheese_wedge` rather
than a `c:` tag. As of 0.3.0, `GenerateBridges.ps1` indexes **every**
namespace's item tags (not just `c:`) and follows references into them, so a
canonical tag that points at a mod's own tag still pulls the items behind it
into the reverse bridges. Any future mod that hides food this way is handled
with no special-casing.

### A third meat dialect

Farm & Charm added a variant nobody else uses — flat-underscored — so the
meats now collide three ways and every canonical meat tag bridges all of them:

| Concept | Official (NeoForge/FD) | Pam's | Farm & Charm |
|---|---|---|---|
| raw pork | `c:foods/raw_pork` | `c:rawpork` | `c:raw_pork` |
| cooked beef | `c:foods/cooked_beef` | `c:cookedbeef` | `c:cooked_beef` |

### Seeds never cross a bridge

Croptopia files its seeds *inside* its produce tags (`c:strawberries` holds
both the strawberry and its seed). That is legitimate inside Croptopia, but
injecting a seed into another mod's food tag would let a seed satisfy a food
recipe — so `GenerateBridges.ps1` excludes `_seed`/`_sapling` items from every
injection, and `tools/tagtest-letsdo.txt` asserts it.

### Known gap: fruit has no role

`c:foods/fruit` is bridged on the identity axis but maps to **no role tag** —
`garnish` is deliberately the savory pool (vegetable/berry/leafy_green). So
Croptopia's ~40 fruits and Vinery's grapes are identity-tagged but roleless.
Giving fruit a role (either widening `garnish` or adding a `fruit` role) is a
semantic change to a shipped mod, so it is left as an open design decision
rather than made silently. Pinned by an assertion in the Let's Do suite.

Not yet bridged: Croptopia's ~600 per-dish plural tags (`hamburgers`,
`beef_jerkies`…) — most are dish-level, low interop value; revisit with
the generator. Pam's `c:salt`/`c:batter`/`c:stock`-style ingredient tags are
bridged only where a role tag consumes them (stock → liquid_base).

### Forward sanitization: `pantrywork:bridged/*`

Some upstream produce tags deliberately mix planting seeds in with the food —
Croptopia's `c:vegetables` holds both `lettuce` and `lettuce_seed`. Referencing
such a tag from a canonical tag drags the seeds along, and a datapack tag cannot
subtract members, so for those categories the generator enumerates the food
item-by-item into `pantrywork:bridged/<name>` and the canonical `c:foods/*` tag
references that instead. This is why `c:foods/vegetable` no longer points at
`#c:vegetables` directly.

The trade: produce added by a future version of an upstream mod is not picked up
until the generator is re-run. A stale entry is invisible; a seed satisfying a
food recipe is a bug — so correctness wins. `GenerateBridges.ps1` prints exactly
what it dropped, and `tools/AuditRoles.ps1` fails the build if any ever gets
through.

**Identifying a seed needs two signals, not one.** A name rule alone condemns
`croptopia:roasted_pumpkin_seeds`, which is real food; `c:seeds` membership alone
condemns `farm_and_charm:onion`, which is plantable *and* edible. So: a trailing
`_seed`/`_sapling` is decisive on its own, while a trailing `_seeds` only counts
when the ecosystem also files the item under `c:seeds`.

Tags belonging to another mod are exempt from this rule. If Croptopia keeps a
seed in its own `c:fruits`, that is its call — the audit reports it as `upstream`
and moves on. What matters is that nothing of ours reaches it.

### What a bridge may add (0.7.0)

Four rules decide whether an item may enter another mod's tag. Each is enforced
twice: by `tools/GenerateBridges.ps1` when the data is written, and by
`tools/AuditRoles.ps1`, which fails the build.

**1. Skip only direct entries.** An emit target skips an item only when the target
lists that item itself (a non-`#` entry). Through 0.6.0 it skipped anything the
tag could *reach* through any reference, a third mod's included: `croptopia:dough`
reached Pam's `c:dough` only via Farm & Charm's `c:dough -> #c:doughs`, and
`farm_and_charm:strawberry` reached `c:fruits` only via Croptopia's
`#c:strawberries`. Uninstall the middle mod and the bridge vanished. AuditRoles
check 6 re-resolves `c:fruits` without Croptopia and `c:dough`/`c:flour` without
Farm & Charm; `runServer -PnoFarmAndCharm` proves the same live.

**2. Vetted namespaces only.** An item crosses a bridge only if its namespace ships
`assets/<ns>/lang` inside a jar the generator actually scanned, or is `minecraft`.
Upstream tags routinely list optional ids for mods nobody here has opened:
Bountiful Fares names `natures_spirit:coconut`, `wilderwild:coconut`,
`atmospheric:orange`/`blood_orange`, `environmental:plum`, `nomansland:walnuts` and
`hauntedharvest:corn`. That is BF's call inside BF's tags. Copying those ids into
other mods' tags would vouch for items nobody checked are food, not seeds, not
blocks and not cheap. They are dropped and logged as `dropped unvetted` in
`tools/work/bridges-report.txt`, for category unions and forward-sanitized members
alike.

**3. The cost floor (SapperSquad, 2026-09-13: strictly, everywhere).** Every item a
Pantrywork path delivers into a tag some recipe consumes is judged against each mod
that defines that tag, not against the union:

- **cost(X)** is the cheapest route to make X through its own mod, in the base unit of
  its category (milk bucket, wheat, whole meat, whole fish, one gathered crop...),
  counting yields, containers not returned and side ingredients. Dairy counts milk
  content only; plant milks cost 0 and are never a floor.
- **floor(M, T)** is the cheapest item defining mod M itself lists in T.
- X may be up to **1.5x** cheaper than a floor. Then, per (tag, item):
  - **PASS**: within tolerance of every defining mod's floor.
  - **GATE**: too cheap for some defining mods, but some mod N's own floor is already
    within 1.5x of it. N's recipes accept an equally cheap item upstream, so X is
    added only while N is loaded. When N is X's own mod, a hard dependency of it, or
    the platform, the gate is always satisfied and it is a PASS.
  - **EXCLUDE**: too cheap, and no defining mod rescues it.

The numbers live in `tools/cost-floors.json` (every cost with the recipe it came from,
every floor per defining mod, and the judgment calls), the rule in
`tools/CostFloor.ps1`. `GenerateBridges.ps1` derives each verdict from them and refuses
to write anything when an item has no cost or a scanned jar defines a judged tag with
no declared floor. `tools/work/bridges-report.txt` lists every GATE and EXCLUDE with its
ratios.

**How a gate ships.** Conditions inside a tag file are ignored by every loader, so GATEd
items go into pack overlays: `pantrywork_gate_<n>/data/pantrywork/tags/item/gated/<mods>/...`
(tag `pantrywork:gated/<mods joined by _or_>/c/<tag>`),
declared in the jar's `pack.mcmeta` under both `neoforge:overlays` (a `neoforge:mod_loaded`
or `neoforge:or` condition) and `fabric:overlays` (`fabric:all_mods_loaded` /
`any_mods_loaded`). The ungated tag file carries an optional `#pantrywork:gated/...` ref, so
with the gate closed the overlay tag simply does not exist. Proven live on the staged 0.7.0 release jars
(2026-09-13): open and closed on NeoForge 1.21.1 (five mod combinations switching the Pam's, Croptopia, Create
and flour conditions, tagtest-gates; the Farm & Charm condition on the dev server with and without
Farm & Charm), at tag level on
NeoForge 26.1.2 and 26.2 (neo26-gates, 6 passed + 4 closed) and on Fabric 1.21.1, 1.21.10, 26.1.2 and 26.2
(fabric-gates, 12 passed + 4 closed); the Fabric 1.21.11 harness has no Croptopia and its suite probes no
overlay tag. On Fabric the overlays, like all mod data, need Fabric API.

Each loader's condition names the canonical rescuers **plus that loader's mod-id aliases**
(`modAliases` in `cost-floors.json`). Croptopia's Fabric 1.21.10 build is Croptopia
Refabricated, mod id `croptopia-refabricated`, with Croptopia's recipes and tags, so the Fabric
croptopia gate is `any_mods_loaded [croptopia, croptopia-refabricated]`; before the review fix
it named `croptopia` only and never opened on 1.21.10 (tagtest-fabric 5/2 there). The generator
always scans `tools/work/jars-12110`, where that jar lives, so a new alias shows up as a defining
mod with no floor and stops the run.

**Forward refs.** A hand-authored canonical tag that references a dialect tag cannot
subtract members, so where a dialect holds an item below the canonical tag's floor, the
canonical file points at a generated, judged `pantrywork:bridged/*` enumeration instead:
`c:drinks/milk`, `c:foods/dough`, `c:foods/pasta`, `c:foods/bread` and
`c:foods/cooked_chicken`. The role tags keep their members by referencing the dialect tags
directly where needed (starch -> `#c:pasta`, `#c:bread`) or naming the few dishes that left
(protein: cooked buffalo meat, roasted chicken, cooked elder guardian slice); a role is
classification, not a recipe slot.

Milk, per item, in buckets:

| Item | Cost |
|---|---|
| `minecraft:milk_bucket`, `meadow:wooden_milk_bucket` | 1 |
| `farmersdelight:milk_bottle` | 1/4 (bucket + 4 bottles → 4) |
| `pamhc2foodcore:freshmilkitem` | 1/8 (bucket → 8) |
| `croptopia:milk_bottle` | 1/16 (bucket + 3 glass → 16) |
| `croptopia:soy_milk` | no milk at all (bottle + soybean, food press) |

- `c:milks`: defined by Croptopia (its 1/16 bottle; soy milk is a plant milk) and Meadow
  (buckets). FD's bottle and Pam's fresh milk are 4x and 8x below Meadow's bucket but
  within Croptopia's floor: **GATE croptopia**.
- `c:milk`: defined by Farm & Charm and Meadow (buckets) and Pam's (bucket + 1/8
  fresh milk). FD's 1/4 bottle is 4x below the buckets but within Pam's floor:
  **GATE pamhc2foodcore**. Croptopia's bottle and soy milk are below all three:
  **EXCLUDE**. **0.6.0 shipped both there; that was the bug.**
- `c:drinks/milk`: defined by NeoForge (bucket) and Farmer's Delight (its 1/4
  bottle), and read by FD's cake, pie crust, custard and hot cocoa. Our
  hand-authored file used to reference `#c:milks` + `#c:milk`, which routed all
  three cheaper milks in. A reference cannot subtract, so the file now points at
  the generated `pantrywork:bridged/drinks_milk`, which lists the bucket-class
  members only. The dairy and liquid_base role tags reference `#c:milk` and
  `#c:milks` directly instead: a role is our own semantic tag, not a recipe slot
  with a floor.

The same floor keeps Croptopia's cheese and butter (~1/16 bucket each, made from
that bottle) out of `c:cheese`/`c:butter`, whose floors are Pam's 1/8 and Meadow's
and Farm & Charm's 1/4. It also keeps half-portion cuts out of whole-item tags:
FD bacon, minced beef, chicken cuts, mutton chops, patties and fish slices (raw and
cooked), Farm & Charm bacon, chicken parts, roasted chicken and bacon and eggs, Ocean's
Delight slices, and Aquaculture fillets (2.7.21 `FishWeightHandler`: an Atlantic halibut
fillets into 14, six species into 1). Those tags are Pam's whole-meat and whole-fish
tags and Farm & Charm's `c:raw_beef`, `c:raw_mutton`, `c:cooked_mutton`,
`c:raw_fishes` and `c:cooked_fishes`. Where Farm & Charm's own tags already hold
cuts (`c:raw_pork`, `c:raw_chicken`, `c:cooked_pork`, `c:cooked_beef`,
`c:cooked_chicken`), FD's cuts clear the floor and stay. Cheap items that are
*native* to a tag are that mod's own call (rule 2 above) and are left alone.

The 2026-09-13 pass derived the rest (all in the report):
- GATE: Pam's cheese and salt in `c:cheeses`/`c:salts` (Croptopia; the salt gate is redundant
  while Croptopia's own `c:salts -> #c:salt` already reaches Pam's salt), FD's cabbage leaf
  in `c:vegetables` (Croptopia; redundant while Croptopia's own `c:vegetables -> #c:cabbage`
  already reaches the leaf; neither redundant gate changes anything live), Create/FD/Pam's dough in
  `c:doughs` (Farm & Charm), Pam's dough in `c:foods/dough` (Create), Create flour in
  `c:flour` (Bountiful Fares, Farm & Charm or Pam's).
- EXCLUDE: Pam's toast in `c:toasts`, Pam's cooking oil in `c:olive_oils`, Croptopia's
  apple and melon juice in Pam's `c:juices/applejuice` and `c:juices/melonjuice`, F&C dough, pasta,
  farmer's bread and roasted chicken and Pam's pasta in FD's `c:foods/*` dough, pasta,
  bread and cooked chicken, Meadow's cooked buffalo meat in `c:foods/cooked_meat`, Ocean's
  Delight's fugu and elder guardian slices in `c:foods/raw_fish`, and FD's cabbage leaf in
  `c:foods/vegetable`.
- Judgment calls are recorded in `cost-floors.json` "judgments": the salt floors measure
  processing on infinite water and stone. The first pass also called the melon slice a
  portion (1/5 of a block) and excluded it from `c:fruits`; SapperSquad's rule "raw gathered
  produce = 1 base unit" reversed that (FC2-4): the slice is what breaking a melon drops, so it
  costs 1, like an apple, and stays in `c:fruits` as it was in 0.6.0.

The review of that pass (same day) corrected three verdicts and one guard:
- **`c:foods/milk` holds the bucket only.** The first pass treated Farmer's Delight as a defining
  mod of its own deprecated tag and so kept its bottle. No scanned FD jar defines it on a line
  where another mod reads it (FD 1.3.2 and Refabricated 3.3.3/3.6.x only define `c:drinks/milk`;
  only Refabricated 3.4.2, Fabric 1.21.10, still lists its bottle, and there the only readers are
  FD's own nine recipes, which keep the bottle through FD's own entry; Bountiful Fares' cocoa cake
  and cake override, the only other readers, have no 1.21.10 build; no FD addon reads the tag). Against BF's bucket the bottle is 4x below: EXCLUDE. The
  generator and audit now fail on any declared floor whose mod defines the tag in no scanned jar
  (`Test-FloorDefiners`), because such a floor rescues its own mod's items for free.
- **`croptopia:ground_pork` leaves Pam's `c:groundmeats/groundpork`.** Croptopia presses
  `#croptopia:pork_replacements` = porkchop OR tofu (soybean + water bottle), so its cheapest
  route has no meat: cost 0, like soy milk. It no longer reaches Pam's pork sandwich or meatloaf.
- **Croptopia's melon juice stays out of Pam's `c:juices/melonjuice`.** The review (CF-4) put it
  back: with a slice priced at 1/5 fruit, Pam's 2 slices = 0.4, and it priced Croptopia's as
  1 slice + a 0.10 glass bottle = 0.3 (x1.33, PASS). The final check (FC1-1) reversed that. The
  bottle is the juice's craft remainder (`Juice` -> `new Drink(...
  craftRemainder(Items.GLASS_BOTTLE))` in Croptopia 4.2.4 and every 26.x build), and Pam's melon
  jelly, popsicle and smoothie are shapeless crafting recipes, so the bottle comes back: it costs
  0. With a slice now one gathered unit (FC2-4), Croptopia's juice is 1 against Pam's 2 (x2.00),
  Pam's is the only mod defining the tag, EXCLUDE. At that unit the bottle no longer decides it:
  CF-4's charged bottle (1.1) would fail too, at x1.82. The same convention ("a container costs 0 when the item gives it back") puts
  Croptopia's apple juice at 1 (x2.00, still EXCLUDE) and Brewin' & Chewin's jams at 3.1 (their
  `JamJarItem` also returns its bottle; still PASS in Pam's jelly slots). 0.6.0 shipped the melon
  juice bridge.
- **The Fabric croptopia gate opens for Croptopia Refabricated** (see "How a gate ships").

**What the rule does not cover.** It judges what Pantrywork adds, including items passed on by
another mod's reference to a tag Pantrywork writes. It does not touch what a mod lists in its own
tags (rule 2: Croptopia's own `c:milks` keeps its 1/16 bottle, FD's `c:drinks/milk` keeps its 1/4
bottle). Role tags have no floor: `dairy` references `#c:milk` and `#c:milks`, so it holds Croptopia's
bottle and soy milk next to buckets, and a recipe written against a role accepts all of them. On
Fabric the overlays, like all mod data, are loaded by Fabric API, which both Fabric jars declare as
required: without it Fabric Loader refuses to start and names the missing dependency, so no
conditional entry can load without its condition. Costs are measured on the scanned mod
versions (`tools/work/jars`, `jars-26x`, `jars-12110`); a recipe change upstream can move a floor
until the generator is re-run with the new jar.

### What changed for players (0.7.0 against 0.6.0)

Measured 2026-09-13 by resolving every tag Pantrywork touches, with provenance, against the 0.6.0
tree (HEAD) and the 0.7.0 tree over every scanned jar, all mods loaded and every condition met.
"Out" means the item is no longer in that tag by any route; items that lost only a Pantrywork route
but stay through the tag's own mod (FD's cuts in FD's own tags, FD's bottle in `c:drinks/milk`) are
not changes and are not listed. Ratios for every generated verdict are in
`tools/work/bridges-report.txt`; costs and their recipes in `tools/cost-floors.json`.

**Out, below a floor:**

| Item | Tags it left | Cost against the floor that fails it |
|---|---|---|
| `croptopia:milk_bottle`, `croptopia:soy_milk` | `c:milk`, `c:drinks/milk` (and so `c:drinks`, `farm_and_charm:milk`) | 1/16 bucket and no milk, against buckets (Pam's 1/8 in `c:milk`) |
| `pamhc2foodcore:freshmilkitem` | `c:drinks/milk` (and `c:drinks`) | 1/8 bucket against FD's 1/4 bottle |
| `farmersdelight:milk_bottle` | `c:foods/milk` | 1/4 against Bountiful Fares' bucket (review CF-1) |
| `croptopia:cheese` / `croptopia:butter` | `c:cheese` / `c:butter` (and `farm_and_charm:butter`) | 1/16 bucket against Pam's 1/8 and Meadow's or F&C's 1/4 |
| FD `bacon`, F&C `bacon` | Pam's `c:rawpork` | 1/2 porkchop against 1 |
| FD `cooked_bacon`, F&C `bacon_with_eggs` | Pam's `c:cookedpork` | 1/2; 0.583 (3 per porkchop + 2 eggs + butter) |
| FD `minced_beef` | Pam's `c:rawbeef`, F&C `c:raw_beef` | 1/2 |
| FD `beef_patty` | Pam's `c:cookedbeef` (no recipe reader) | 1/2 |
| FD `chicken_cuts`, F&C `chicken_parts` | Pam's `c:rawchicken` | 1/2; 1/3 |
| FD `cooked_chicken_cuts`, F&C `roasted_chicken` | Pam's `c:cookedchicken` (no recipe reader); the roast also FD's `c:foods/cooked_chicken` and `c:foods/cooked_meat` | 1/2; 0.228 |
| FD `mutton_chops`, `cooked_mutton_chops` | Pam's `c:rawmutton`; Pam's `c:cookedmutton` and F&C `c:raw_mutton`/`c:cooked_mutton` (no recipe reader) | 1/2 against 1 (F&C cooked: 1.25) |
| FD `cod_slice`, `salmon_slice` | Pam's `c:rawfish`, `c:fishes`; F&C `c:raw_fishes` | 1/2 fish |
| FD `cooked_cod_slice`, `cooked_salmon_slice`, `aquaculture:fish_fillet_cooked` | Pam's `c:cookedfish`, F&C `c:cooked_fishes` (no recipe reader) | 1/2; 1/14 (Atlantic halibut) |
| Ocean's Delight `fugu_slice`, `elder_guardian_slice` | `c:foods/raw_fish`, `c:foods/safe_raw_fish`, Pam's `c:rawfish`/`c:fishes`, F&C `c:raw_fishes` | a cut, below the whole-fish floors |
| Ocean's Delight `cooked_elder_guardian_slice` | `c:foods/cooked_fish`, Pam's `c:cookedfish`, F&C `c:cooked_fishes` (no recipe reader) | a cut |

"No recipe reader" means no recipe in the scanned mod versions reads that tag (per-install
membership diff, 2026-09-13), so the removal is kept for consistency but changes nothing in play.
| `meadow:cooked_buffalo_meat` | `c:foods/cooked_meat` | judgment call (census) |
| F&C `dough`, `raw_pasta`, `farmers_bread`; Pam's `pastaitem` | FD's `c:foods/dough`, `c:foods/pasta`, `c:foods/bread` | 0.094 / 0.047 / 0.065 wheat; Pam's pasta 0.6 against FD's 1.083 |
| `pamhc2foodcore:toastitem` | Croptopia's `c:toasts` | 5/8 loaf against 1 (x1.60) |
| `pamhc2foodcore:cookingoilitem` | Croptopia's `c:olive_oils` | x4.00 |
| `croptopia:apple_juice`, `croptopia:melon_juice` | Pam's `c:juices/applejuice`, `c:juices/melonjuice` | 1 apple against 2; 1 melon slice against 2 (x2.00 each; the glass bottle returns as a craft remainder, FC1-1) |
| `croptopia:ground_pork` | Pam's `c:groundmeats/groundpork`, `c:groundmeats` | 0 meat (tofu route) against 1/2 (review CF-3); still in `origins:meat`, named there directly (FC1-3) |
| `farmersdelight:cabbage_leaf` | `c:foods/vegetable` | 1/2 cabbage against 1 |

**Out, not food:** `minecraft:melon` (`c:foods/fruit`), `minecraft:pumpkin` (`c:foods/vegetable` and
the garnish role), `brewinandchewin:flaxen_cheese_wheel` and `scarlet_cheese_wheel` (`c:cheese`,
`c:cheeses`, `c:foods/cheese`, `meadow:cheese` and the dairy role). No other role-tag member left
(the dishes that left canonical tags are named in the role files directly); the roles gained the three
cooked eggs (protein) and Refurbished Furniture's cheese (dairy).

**Now conditional (all unconditional in 0.6.0).** The named mod's own recipes already accept an item
that cheap, so the swap always holds there; the other readers lose it when that mod is absent.

| Item | Tag (readers that lose it) | Only while |
|---|---|---|
| `farmersdelight:milk_bottle` | `c:milk` (Farm & Charm, Meadow) | Pam's HarvestCraft 2 |
| `farmersdelight:milk_bottle`, `pamhc2foodcore:freshmilkitem` | `c:milks` (Meadow) | Croptopia (or Croptopia Refabricated) |
| `pamhc2foodcore:cheeseitem` | `c:cheeses` (none: Croptopia's recipes are its only readers, so no visible change) | Croptopia |
| `farmersdelight:wheat_dough`, `pamhc2foodcore:doughitem` | `c:doughs` (Croptopia) | Farm & Charm |
| `pamhc2foodcore:doughitem` | `c:foods/dough` (Farmer's Delight) | Create |

**New in 0.7.0 and conditional:** `create:dough` in `c:doughs` (Farm & Charm), `create:wheat_flour`
in `c:flour` (Bountiful Fares, Farm & Charm or Pam's; with Farm & Charm installed it already arrived
through F&C's `c:flour -> #c:flours`, so it is new only with Pam's or BF and no F&C). Two gated entries
change nothing in play: `pamhc2foodcore:saltitem` in `c:salts` and `farmersdelight:cabbage_leaf` in
`c:vegetables` (both Croptopia), because Croptopia's own `c:salts -> #c:salt` and `c:vegetables ->
#c:cabbage -> #c:crops/cabbage` reach them whenever Croptopia is installed, in 0.6.0 as now. Likewise
the leaf's unconditional entry in `c:cabbage` (Croptopia's floor is the leaf itself): Croptopia's own
`c:cabbage -> #c:crops/cabbage` already held it on every scanned Croptopia build, and on 1.21.1 no
other mod defines `c:cabbage`. Re-measured 2026-09-13 per install scenario on the NeoForge 1.21.1
jar set (all gate mods; without each of Croptopia, Farm & Charm, Pam's, Create, Bountiful Fares; without
BF + F&C + Pam's; without all five), 0.6.0 tree against the 0.7.0 tree with overlays applied by loaded
mod. **New and unconditional:** every PASS listed in the report.

**On 26.x** Farm & Charm, Pam's, Create and Bountiful Fares have no builds, so their conditions never
open: FD's `wheat_dough` is out of Croptopia's `c:doughs` on every 26.x jar, and FD's bottle is never in
`c:milk` there. The Croptopia condition does open, so FD's bottle stays in `c:milks` (the Fabric 26.x
smoothie craft).

AuditRoles check 5 holds an independent, hand-kept table of (tag, item) pairs that must
stay absent or gated; check 7 re-derives every verdict along every resolved Pantrywork
path, hand-authored refs included.

**4. Non-food never crosses a bridge.** Besides seeds (next section), a denylist
keeps these out of every injection and every `pantrywork:bridged/*` list:
- `minecraft:pufferfish` and the golden foods: items the target mods plausibly
  excluded on purpose.
- `minecraft:melon` and `minecraft:pumpkin`: the *blocks*, which Pam's files next to
  the food in `c:fruits/melon` and `c:vegetables/pumpkin`. 0.6.0 copied both into
  `c:foods/fruit` and `c:foods/vegetable`.
- `bountifulfares:coconut`: the palm sapling block item, with no food component. BF
  files it in its own `c:coconuts` and Croptopia's `c:fruits` pulls that in
  upstream; Pantrywork never spreads it further.
- `create:honeyed_apple`: a processed treat, same precedent as the golden apple.
- `fishofthieves:mango_pit`: a planting seed the seed rule cannot see by name. No
  current tag path reaches it; `GenerateBridges.ps1 -SelfTest` plants it to prove
  the entry still works.
- `brewinandchewin:flaxen_cheese_wheel` / `scarlet_cheese_wheel`: food-less block items
  (`BnCItems` builds them as `new BlockItem(...)` with no food component). 0.3.0-0.6.0
  put them in `c:cheese`/`c:cheeses` and, through a hand ref, `c:foods/cheese` and the
  dairy role. The wedges cut from them are the food and still cross.

### Cooked eggs: a hand-authored gap fill (0.7.0)

`c:foods/cooked_egg` is Farmer's Delight's tag, read by its egg sandwich and bacon
and eggs. Pam's fried egg, Bountiful Fares' cooked egg and Croptopia's sunny-side
eggs are in no tag at all, so `src/main/resources/data/c/tags/item/foods/cooked_egg.json`
lists them item by item, all `required: false`. Each costs one egg, like FD's fried
egg (Croptopia makes two from two eggs), so no floor is crossed. Pam's boiled and
scrambled eggs and `croptopia:scrambled_eggs` stay out: they are a different
preparation from the fried egg those recipes are written for. The protein role
picks all three up through its existing `#c:foods/cooked_egg` reference.

### Refurbished Furniture: bridged by name, and what is not (0.7.0)

Refurbished tags none of its food, so its cheese, wheat flour, sea salt and dough
are added by name (`extra`) to the cheese, flour, salt and dough categories. Its
**toast, bread slice and jams are never bridged**. One bread makes six slices and
each slice makes one toast, so Refurbished toast is about 6x cheaper than
Croptopia's (one per bread). Its sweet and glow berry jams are one berry in a
frying pan with no sugar, against Pam's jelly (juice of two berries plus sugar) and
Brewin' & Chewin's preserves (three fruit plus sugar). `bread_slice` does sit in
Refurbished's own `c:foods/bread`; that is Refurbished's call. AuditRoles check 4
fails if any of these reaches a toast, jam or jelly tag through Pantrywork.

Two gaps tags cannot close. Refurbished's own recipes name exact item ids, so no
other mod's food works inside them. Bountiful Fares' coconut-halving recipe names
`bountifulfares:coconut`, so other mods' coconuts cannot be split. Both need
upstream changes.

### Named exception: `c:foods/milk` (deprecation shim, not taxonomy)

This is the one tag Pantrywork defines that is **not** part of its taxonomy, and
it breaks rule 3 (naming follows FD/NeoForge precedent) on purpose.

Farmer's Delight invented `c:foods/milk` in 1.2.4, deprecated it in 1.2.10 and
deleted it in 1.3.0 (Apr 2026), at the ecosystem's request — milk has no food
value, so it did not belong under `foods`. NeoForge's convention registry never
defined it; the sanctioned names are `c:drinks/milk` and `c:buckets/milk`.

Addons that still reference it are not merely missing an ingredient: an
undefined tag fails ingredient decoding, so **the entire recipe is dropped at
parse time**. Tags cannot be aliased, so defining the tag is the only available
fix. Four addon jars were opened to confirm this — Arbitrary Delight (16 refs),
Cultural Delights (4), Pineapple Delight (3), Nature's Delight (2) — none of
which defines the tag or has migrated.

**Contents: the milk bucket only.** Through the first cost-floor pass this was FD's own last
definition item-for-item (bucket + `farmersdelight:milk_bottle`). The review removed the bottle:
it is 1/4 bucket, 4x below the bucket Bountiful Fares' cocoa cake and cake override (3 milk each,
the only scanned readers) are balanced for, and no scanned FD jar defines the tag on a line where
BF exists. The tag stays defined, so every addon recipe that names it still parses; those recipes
now need buckets. On Fabric 1.21.10 FD Refabricated 3.4.2 still lists its own bottle there (FD's
call, merged at load).

```json
{ "values": [ "minecraft:milk_bucket" ] }
```

**It must NOT be `[{"id": "#c:drinks/milk"}]`**, tempting as that looks. At 0.6.0
`c:drinks/milk` resolved to **six** items, because Pantrywork itself referenced
`c:milk`/`c:milks` from it, including `croptopia:milk_bottle` (16 per bucket, a 16x
economic dilution) and `croptopia:soy_milk` (no cow required). 0.7.0 closed that
route (see the economic floor above), but `c:drinks/milk` is still a merged tag
that any mod can widen (FD's own bottle sits there), while the shim must stay the bucket. Nesting
would hand whatever lands there to third-party recipes written against a two-item
tag, which is the re-classification rule 2 forbids. Literal items also mean no tag reference, hence no cycle against the FD
versions whose `c:drinks/milk` still carries a required `#c:foods/milk` entry.

Rules for it: never joined to `#c:foods`, never referenced by a
`pantrywork:food_component/*` tag (dairy and liquid_base model milk through
`#c:buckets/milk`, `#c:drinks/milk`, `#c:milk` and `#c:milks`), and never widened
by Pantrywork. `tools/AuditRoles.ps1` enforces all three and fails the build
otherwise. Bountiful Fares adds its own `coconut_milk_bottle` to this tag; that is
BF's call, so the audit reports it as upstream widening instead of failing.

**Sunset:** this exists only until the addons migrate to `c:drinks/milk`. The
honest advice to those authors is to change one line — Pantrywork already
resolves `c:drinks/milk` fully, buckets included. Once packs depend on this shim
it can never be removed, so do not promote it as the primary fix.

### Footnote: Let's Do Vinery ships its `c:` tags at an unreadable path

TAXONOMY records Vinery as shipping "zero `c:` tags". That is right in effect but
wrong in cause: it ships twelve of them under `data/*/tags/items/` (PLURAL, the
1.21.2+ layout), and the 1.21.1 loader reads only the singular `tags/item`. They
are dead data on this line — which is why Vinery still needs its per-item module.
Re-check this if Vinery is ever added to a 26.x harness, where the plural path
does load and those tags would suddenly go live.
