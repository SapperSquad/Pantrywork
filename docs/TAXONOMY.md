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
| flour | (none) | `c:flour` | `c:flour` ← natural collision, already interops |
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
into each dialect tag (24 files in `src/generated/resources`, report in
`tools/work/bridges-report.txt`; rerun after any compat-jar update). Its
category map was chosen from what the mods' recipes actually consume
(488 Croptopia + 200 Pam's recipes scanned). A blacklist keeps items the
target mods plausibly excluded on purpose (pufferfish, golden foods) out
of every injection. Verified live 2026-07-19: Croptopia's grilled cheese
crafts with Pam's cheese; Pam's grilled-cheese-and-ham crafts from four
mods' ingredients (skillet + vanilla bread + Croptopia butter/cheese +
FD bacon), tool remainders intact.

Bonus finding from the recipe scan: several categories already interop
with no bridge at all because the mods coincidentally picked identical
tag names that merge at load (`c:flour`, `c:salt`/`c:salts` pairs both
defined by both mods, `c:tomatoes`, `c:onions`, `c:rice`, `c:vegetables`,
`c:fruits` parents). Pantrywork leaves those alone.

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
pantrywork:food_component/dairy        #c:buckets/milk + drinks/milk + cheese + butter
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
| Brewin' & Chewin' 4.5.0 | yes, but into its **own `brewinandchewin:` namespaced tags** (cheese wedges/wheels, `fermented_drinks`) | ripe cheeses → `c:foods/cheese`, 16 drinks → `c:drinks`; soups already canonical |

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

**Contents are FD's own last definition, item-for-item:**

```json
{ "values": [ "minecraft:milk_bucket", { "id": "farmersdelight:milk_bottle", "required": false } ] }
```

**It must NOT be `[{"id": "#c:drinks/milk"}]`**, tempting as that looks. Here
`c:drinks/milk` resolves to **six** items, because Pantrywork itself bridges
`c:milk`/`c:milks` into it and generates reverse bridges back into those. Nesting
would hand all six to third-party recipes written against a two-item tag —
including `croptopia:milk_bottle` (16 per bucket, a 16x economic dilution) and
`croptopia:soy_milk` (no cow required). That is the re-classification rule 2
forbids. Literal items also mean no tag reference, hence no cycle against the FD
versions whose `c:drinks/milk` still carries a required `#c:foods/milk` entry.

Rules for it: never joined to `#c:foods`, never referenced by a
`pantrywork:food_component/*` tag (dairy and liquid_base already model milk
correctly via separate `#c:buckets/milk` + `#c:drinks/milk` refs), and never
widened. `tools/AuditRoles.ps1` enforces all three and fails the build otherwise.

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
