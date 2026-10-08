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
| salt | (none) | `c:salts` | `c:salt` ← and a **fifth** spelling, `c:dusts/salt`, arrived with the newer FD addons (0.8.0) |
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
into each dialect tag (106 tag files in `src/generated/resources` as of 0.8.0, 16 of
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

## Per-mod module status (first verified live 2026-07-19; each row carries the release it landed in)

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
| Kaleidoscope Cookery 1.6.0 (0.8.0) | yes — 15 judged `c:` tags, FD-style, **two of them empty files** (see "Empty definers"); its oil lives behind its own `kaleidoscope_cookery:oil` | the headline: that oil tag is hand-authored here, since its wok checks the tag in code (`PotBlockEntity.onPlaceOil` → `ItemStack.is(TagMod.OIL)`), which gates all 225 of its wok recipes. `fried_egg` into `c:foods/cooked_egg` (it ships in the plural `c:foods/cooked_eggs`, which nothing reads); `raw_dough` into `c:doughs` (GATE farm_and_charm) and `c:foods/dough`; tomato/lettuce/chillies into the vegetable tags. It is also a *rescuer*: its cheap sashimi and its one-wheat millstone flour widen three gates. 1.21.1 only in practice (its Fabric branch is stale at 1.0.1) |
| Hearth and Harvest 1.3.4 (0.8.0) | yes — FD-style, incl. `c:dusts/salt`; its butter is tagged only **from 1.3.4** | oil into `c:cookingoil` and both oil tags of KC and Rustic Delight; butter into `c:butters`; its 1/32 salt is the cheapest in the set, so it is GATEd (Cook's Collection) in `c:salt`/`c:salts` and is itself the rescuer of `c:dusts/salt`; flour and corn meal GATE (Bountiful Fares or Farm & Charm) in `c:flour`; goat milk bottle gates exactly where FD's bottle does. NeoForge 1.21.1 only |
| Cultural Delights 0.18.1 (0.8.0) | yes — FD-style; **no oil item of its own** (the "CD oil" is Cook's Collection's, a hard dep since 0.18.0) | butter into `c:butters`; corn dough into `c:doughs` (GATE farm_and_charm); its vegetables and four 1/2 cuts into the vegetable tags (the cuts GATEd); it and Rustic Delight are what bring FD's cabbage leaf back into `c:foods/vegetable`. 0.18.1 dropped its `c:foods/milk` refs, so it is off the shim. NeoForge 1.21.1 only, and **≥ 21.1.247**, which `tools/neo-server-1211` cannot boot |
| Cook's Collection 0.6.1 (0.8.0) | yes — and it files its own `c:salt`/`c:salts` as literally `#c:dusts/salt` | its 4-sunflower oil is the dearest of the five and so PASSes both `c:cookingoil` and Croptopia's `c:olive_oils`; lemon into the fruit tags. Because its salt tags *are* the shared tag, it rescues anything that tag can hold — which is why the `c:salts` gate on Pam's salt widened to `cookscollection_or_croptopia` |
| Rustic Delight 1.7.1 (0.8.0) | yes — singular FD-style paths; its oil lives behind its own `rusticdelight:cooking_oil` (10 readers) | that oil tag is the second hand-authored foreign-namespace file. Nine whole bell peppers into the vegetable tags ungated, the nine slices and potato slices GATEd; calamari into the fish dialects; it repairs the two FD recipes it overrides and narrows (fried rice onion, baked cod stew tomato) via the new `c:foods/onion` and `c:foods/tomato` targets. **NeoForge 1.21.1 + Fabric 1.21.x + Fabric 26.x.** Its oil recipe, 9 of its 10 oil readers and its slice recipes sit behind its own config flags (default on), which the cost model cannot see |
| Hybrid Delights 1.3.1 (0.8.0) | **no** — ships only `c:tools/knife` | salt by name via `extra` into `c:salt`, `c:salts` and `c:dusts/salt`, unconditional (75 + 36 recipes). Its salt item exists only with Hybrid Aquatic installed; the entry is inert otherwise. Its own 11 salt recipes name exact ids, so the reverse direction needs its author. NeoForge + Fabric 1.21.1 |
| Oh The Biomes We've Gone 2.6.2 (0.8.0) | partial — generic only (`c:foods/berry`, `c:foods/fruit`, `c:foods/pie`, `c:foods/soup`, bare `c:crops`), and **no blueberry dialect at all** | the only **worldgen** mod in the table: it is here for the four fruits it grows, not for cooking. `blueberries` by name via `extra` into `c:fruits/blueberry` (5 Hearth and Harvest readers, plus Croptopia's 3 through Croptopia's own `#c:fruits/blueberry` ref) and into `c:blueberries` as belt and braces; its three other fruits ride the fruits union into `c:fruits`. `soul_fruit` denylisted (a blindness food — see rule 4). Its own pies name their fruit by id, so the reverse is impossible. Zero new floor rows were needed: its three judged tags are all moot. Modrinth lists Fabric builds too (2.6.2-Fabric on 1.21.1 — the same version read here — plus 4.2.2 on 1.21.10 and 4.3.x/4.4.x on 1.21.11, whose tags were **not** inspected), and **no 26.x build on any loader**, so the entries are inert on the two 26.x files. No Fabric harness carries BYG, so the Fabric side is proven by the data and by `tagtest-gates-s12.txt`, not by a Fabric boot |

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
both the strawberry and its seed). It also owns two **singular** tag names that
look like produce tags and are not: `c:strawberry` is
`[croptopia:strawberry_seed, #c:seeds/strawberry]` and `c:blueberry` is
`[croptopia:blueberry_seed, #c:seeds/blueberry]`. Both are seed tags with zero
recipe readers, so an injection into either would be a no-op *and* a seed in a
produce-shaped name — the generator reads them as sources where useful and never
emits into them. That is legitimate inside Croptopia, but
injecting a seed into another mod's food tag would let a seed satisfy a food
recipe — so `GenerateBridges.ps1` excludes planting seeds from every injection
(`Test-IsSeed`, three signals; see "Identifying a seed" below), and
`tools/tagtest-letsdo.txt`, `tools/tagtest-seedfix.txt` and
`tools/tagtest-kaleido.txt` assert it.

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

**Identifying a seed needs three signals, not one (third added 0.8.0).** A name
rule alone condemns `croptopia:roasted_pumpkin_seeds`, which is real food;
`c:seeds` membership alone condemns `farm_and_charm:onion`, which is plantable
*and* edible. `Test-IsSeed` — kept byte-identical in `GenerateBridges.ps1` and
`AuditRoles.ps1`, and the helpers it leans on live in `tools/CostFloor.ps1` so
the hard part cannot drift — is therefore:

1. A trailing `_seed`/`_sapling` is decisive on its own.
2. A trailing `_seeds` counts when the ecosystem also files the item under `c:seeds`.
3. **The item's own mod is the authority on its own item.** An item that the mod
   *that owns it* files in a planting tag, and in none of its own mod's food tags,
   is a planting seed.

Rule 3 is what the 0.8.0 blocker needed. `culturaldelights:corn_kernels` and
`hearthandharvest:corn_kernels` match neither name rule, yet each is in its own
mod's `c:seeds` and `c:seeds/corn` and in none of its own mod's food tags, while
those mods' own corn tags hold `corn_cob` and `corn`. Without rule 3 both reached
seven corn and grain tags through Croptopia's `c:corn → #c:seeds/corn`, and from
there `c:foods/vegetable`, canonical `c:foods` and the `garnish` role.

What counts as which kind of tag, measured from the jars rather than assumed:

- **Planting tags** (`Test-IsPlantingTag`): `c:seeds`, every `c:seeds/<crop>` leaf,
  and `minecraft:villager_plantable_seeds`.
- **Food-evidence tags** (`Test-IsFoodEvidenceTag`): any *other* tag in the `c:`
  convention namespace — with two deliberate exclusions. Bare **`c:crops`** is a
  mixed "plantable crop item" bag: Bountiful Fares' own file lists `maize_seeds`,
  `hoary_seeds`, `leek_seeds`, `lapisberry_seeds`, `sweet_berry_pips` and
  `tea_berries` beside its maize and leek, and Hearth and Harvest's lists cotton.
  (`c:crops/<crop>` *is* evidence: Cultural Delights' `c:crops/corn` is its corn
  cob, Rustic Delight's `c:crops/coffee` its coffee beans.) **`c:animal_foods`** is
  feed: Hearth and Harvest's own file is corn, corn kernels and universal feed —
  and without that exclusion its kernels would have been rescued and the blocker
  unfixed.
- **Not evidence at all**: anything outside the `c:` namespace. A mod's private
  tags (`hearthandharvest:crow_food`, `kaleidoscope_cookery:cookery_mod_seeds`,
  `diet:grains`, `sereneseasons:summer_crops`) and the vanilla feed tags
  (`minecraft:chicken_food`, `parrot_food`) are not statements about human food.
- **Whose filing counts** (`Add-OwnFiledEntries`): only a tag file's *direct* item
  entries, and only for items whose namespace the scanning jar owns (its `[[mods]]`
  ids plus every `assets/<ns>/lang` it ships). So Croptopia listing `#c:seeds/corn`,
  or any third mod naming someone else's item, can neither condemn nor rescue it.
  Vanilla items have no own-mod filing at all (no scanned jar ships
  `assets/minecraft/lang`, and the platform jar's mod id is `neoforge`), which is
  safe: every vanilla planting seed is already caught by rules 1 and 2.

Every documented plantable *food* still bridges, each saved by rule 3's second half
out of its own mod's files: `farm_and_charm:onion`, `farmersdelight:rice`,
`kaleidoscope_cookery:rice`, Hearth and Harvest's grapes and peanut, and Rustic
Delight's coffee beans. Croptopia's roasted pumpkin and sunflower seeds are in no
planting tag at all, so no rule sees them.

One honest limit: **the cost floor is not a substitute for this rule.** Hearth and
Harvest's kernels are 1/2 a corn, x2.00 against every 1-produce corn floor, so they
now fail on price too (they had no cost row at all before 0.8.0 and fell back to the
default of 1). Cultural Delights' are 2/3 of a corn — *exactly* x1.50, inside
tolerance — so for those the seed rule is the only guard. Both costs are recorded in
`tools/cost-floors.json` anyway, with the CORN KERNELS judgment that explains why it
was a blocker rather than cosmetic: Cultural Delights' cutting recipe takes 1 ×
`#c:crops/corn` and returns kernels, so kernels inside that tag were an
item-duplication loop; its crate recipe upgraded nine kernels into nine whole cobs;
and kernels satisfied food recipes. The generator now prints a per-category
`dropped seeds:` line, which is how two seeds shipped with nobody reading a line
about them.

Tags belonging to another mod are exempt from this rule. If Croptopia keeps a
seed in its own `c:fruits`, that is its call — the audit reports it as `upstream`
and moves on. What matters is that nothing of ours reaches it.

### What a bridge may add (0.7.0, extended 0.8.0)

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
with the gate closed the overlay tag simply does not exist. Proven live on the staged release jars:
open and closed on NeoForge 1.21.1 (0.8.0: twelve mod combinations, S1–S12 in `tagtest-gates.txt`), at
tag level on NeoForge 26.1.2 and 26.2 (`tagtest-neo26-gates`, 7 passed + 12 closed) and on Fabric
1.21.1, 1.21.10, 26.1.2 and 26.2 (`tagtest-fabric-gates`, 22 passed + 10 closed); the Fabric 1.21.11
harness has no Croptopia and its suite probes no overlay tag. On Fabric the overlays, like all mod
data, need Fabric API.

**The fourteen gates (0.8.0).** 0.7.0 shipped five overlays; the five new mods took it to fourteen,
and the directory numbering is re-cut whenever a gate set is added or removed — so a test suite must
assert the *tag id*, which carries the rescuer list, and never the overlay number.

| # | Rescuers (any one opens it) | What is gated |
|---|---|---|
| `_1` | bountifulfares, farm_and_charm | `c:flour` ← H&H flour + corn meal (1/2 wheat) |
| `_2` | bountifulfares, farm_and_charm, kaleidoscope_cookery, pamhc2foodcore | `c:flour` ← `create:wheat_flour` (2/3 wheat) |
| `_3` | cookscollection | `c:salt` + `c:salts` ← `hearthandharvest:salt` (1/32) |
| `_4` | cookscollection, croptopia | `c:salts` ← `pamhc2foodcore:saltitem` (1/8) |
| `_5` | create | `pantrywork:bridged/foods_dough` ← `pamhc2foodcore:doughitem` |
| `_6` | croptopia | `c:cheeses` ← Pam's cheese; `c:milks` ← FD bottle, H&H goat bottle, Pam's fresh milk |
| `_7` | croptopia, kaleidoscope_cookery | `c:vegetables` ← FD's cabbage leaf, CD's 4 cuts, RD's 9 pepper slices + potato slices |
| `_8` | culturaldelights, rusticdelight | `pantrywork:bridged/vegetable` ← FD's cabbage leaf |
| `_9` | farm_and_charm | `c:doughs` ← Create, CD, FD, KC and Pam's dough |
| `_10` | farmersdelight | `pantrywork:bridged/foods_raw_chicken` ← `farm_and_charm:chicken_parts` |
| `_11` | farmersdelight, rusticdelight | `pantrywork:bridged/raw_fishes` ← `kaleidoscope_cookery:sashimi` (1/3 fish) |
| `_12` | hearthandharvest | `c:dusts/salt` ← Croptopia salt, Pam's salt |
| `_13` | kaleidoscope_cookery | `c:raw_fishes` ← FD cod/salmon slice, CD raw calamari, RD calamari slice (all 1/2 fish) |
| `_14` | pamhc2foodcore | `c:milk` ← FD bottle, H&H goat bottle |

Thirteen of the fourteen get both an open and a closed proof at item level on the 1.21.1 release-jar
harness. The exception is `_5`: its only member is Pam's dough, and no release-jar scenario carries
Create *and* Pam's, so it is proven closed there and open only on the dev boot. Also dev-boot-only,
and said plainly rather than implied: the `bountifulfares` half of `_1` and `_2` (Bountiful Fares is
in no scenario), the `culturaldelights` half of `_8` and CD's four cuts in `_7` (Cultural Delights
0.18.1 requires NeoForge ≥ 21.1.247 and `tools/neo-server-1211` deliberately stays on 21.1.241, so
the release jar is still proven on the older build players run), and Hybrid Delights' three salt
bridges (its jar needs HAPI and Kotlin for Forge, and its salt item exists only alongside Hybrid
Aquatic).

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
classification, not a recipe slot. 0.8.0 added two more for the same reason — `c:foods/raw_chicken`
and `c:foods/raw_fish` — because Kaleidoscope Cookery now defines both at a whole-animal floor while
Pam's and Farm & Charm's dialect tags hold cuts below it. Membership was diffed item by item before
and after: nothing was lost, since NeoForge's own `c:foods/raw_fish` lists `minecraft:pufferfish`
directly and the `#c:rawfish` and `#c:fishes` references stayed live.

**Empty definers (0.8.0).** A mod can declare a tag with an empty `values` list purely so its own
reference to that tag resolves — Kaleidoscope Cookery ships `data/c/tags/item/doughs.json` and
`data/c/tags/item/foods/dough.json` exactly that way, so that its own `c:dough` reference loads. A
definer that lists nothing imposes no floor, so those get a `{"none": "<why>"}` row in
`cost-floors.json` (the same mechanism three other tags already used) rather than a code change in
`Test-FloorDefiners`. The conduit is real but harmless: KC's own `c:dough` reaches both tags, and its
dough costs 1.013 wheat.

**The seed convention (0.8.0, settled).** A planting seed costs its share of the produce it is
crafted from: one pumpkin makes four seeds, so `minecraft:pumpkin_seeds` is 1/4 of a pumpkin, and one
melon slice makes one melon seed, so `minecraft:melon_seeds` is 1. One rule everywhere — it is what
prices Kaleidoscope Cookery's own oil (its millstone takes any `c:seeds`, cheapest member pumpkin
seeds, so 1/4 olive) and Rustic Delight's (six pumpkin seeds into two bottles, bottle returned by FD's
pot, so 3/4). An earlier working note that "1 `c:seeds` = 1 olive" is **withdrawn**: it contradicted
this rule, and under it Pam's cooking oil would have been excluded from the wok tag instead of passing
at x0.50. Alongside it: **a route that starts at a mob drop is not costed as a cheaper route.** Cost
measures processing effort, not scarcity — the same reason the salt convention ignores how common
water is — so Kaleidoscope's oil is not 0 because pigs drop it to a kitchen knife. A whole mob drop is
still 1 unit (`minecraft:porkchop`, `meadow:raw_buffalo_meat`, `rusticdelight:calamari`).

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

### What changed for players (0.8.0 against 0.7.0)

Measured 2026-10-06 by diffing every tag entry Pantrywork writes, in `src/main` and
`src/generated` alike, against the 0.7.0 tree at `HEAD`.

**Nothing was removed.** No item left a base tag. The only entries that disappeared are structural:
the three hand references replaced by generated enumerations (`#c:rawchicken` and `#c:raw_chicken` in
`c:foods/raw_chicken`, `#c:raw_fishes` in `c:foods/raw_fish`) and the old gate tag ids, which were
renumbered and renamed when five overlays became fourteen.

**Two swaps gained a condition.** `farm_and_charm:chicken_parts` in `c:foods/raw_chicken` is now GATE
`farmersdelight` (1/3 meat; Kaleidoscope Cookery floors that tag at a whole chicken, FD's own cut at
1/2 rescues it). `kaleidoscope_cookery:sashimi` in `c:foods/raw_fish` is GATE
`farmersdelight_or_rusticdelight` (1/3 fish against whole-fish floors from NeoForge, Aquaculture and
Fish of Thieves).

**Three conditions got easier to satisfy** — strictly more installs now get the swap:
`create:wheat_flour` in `c:flour` gained `kaleidoscope_cookery`; `pamhc2foodcore:saltitem` in
`c:salts` gained `cookscollection`; `farmersdelight:cabbage_leaf` in `c:vegetables` gained
`kaleidoscope_cookery`.

**Two swaps 0.7.0 excluded came back, conditionally.** `farmersdelight:cabbage_leaf` in
`c:foods/vegetable` is GATE `culturaldelights_or_rusticdelight` (both floor that tag at 1/2 with their
own cuts), and `farmersdelight:cod_slice` / `:salmon_slice` in `c:raw_fishes` are GATE
`kaleidoscope_cookery` (its sashimi is 1/3).

**Everything else is addition**, listed in `CHANGELOG.md` 0.8.0 and in `tools/work/bridges-report.txt`
with ratios.

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
- `create:chocolate_glazed_berries` (0.8.0): the same item class, and it arrived by
  the same kind of route — Create files it in its own `c:foods/berry`, Rustic
  Delight's `c:foods/fruit` references `#c:foods/berry`, and the fruits union picked
  it up. **Denied in a fruit-only scope**, not the general one: `$fruitDeny` over
  `c:fruits`, `c:fruits/*`, `c:foods/fruit` and `pantrywork:bridged/fruit`. The
  reason is rule 2 — `pantrywork:food_component/garnish` references
  `#c:foods/berry` for Hearth and Harvest's five real berries, so a general-scope
  denial would fail the build on Create's own classification of its own item inside
  one of *our* role tags. The harm this guards against is a candied treat in another
  mod's raw-fruit ingredient slot. Disclosed rather than hidden: Create's glazed
  berries do still appear in the garnish role, and `tools/tagtest-kaleido.txt`
  asserts that as an `if` line with the reasoning beside it.
- `biomeswevegone:soul_fruit` (0.8.0): **a new reason, not covered by the block,
  treat or seed cases above — a debuff food.** Eating it inflicts blindness. BYG
  files it in its own `c:foods/fruit` beside its three ordinary fruits, and the
  fruits union would otherwise carry it into Croptopia's `c:fruits`. The cost floor
  cannot see this at all: soul fruit is a gathered drop, so it costs exactly the 1
  produce the `c:fruits` floor wants and passes at x1.00. (Read out of the jar
  rather than assumed: `BWGItems` builds its `FoodProperties` with a
  `MobEffectInstance` of `MobEffects.BLINDNESS`, and `BWGMiscConfig$SOUL_FRUIT`
  exposes `ALLOW_SOUL_FRUIT_BLINDNESS`, `SOUL_FRUIT_BLINDNESS` and
  `SOUL_FRUIT_BLINDNESS_RANGE` — so a player *can* configure the debuff away, the
  same blind spot the cost model has for Rustic Delight's config flags. The
  denylist is written for the default.) Denied in the same
  fruit-only scope as the glazed berries, on the same precedent as
  `minecraft:golden_apple` and `create:honeyed_apple`: a bridge widens an ingredient
  pool, it does not re-litigate another mod's exclusions, and no other mod put a
  debuff food in its fruit slots. It stays in BYG's own `c:foods/fruit` — a datapack
  cannot subtract a member, and that tag is BYG's to define. BYG's own blueberry and
  green-apple pies name their fruit by exact item id, so nothing of BYG's behaves
  differently either way. `tools/tagtest-gates-s12.txt` asserts all three facts on a
  release jar: out of `c:fruits`, out of `pantrywork:bridged/fruit`, in
  `c:foods/fruit`.
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

### Writing into another mod's namespace (0.8.0)

Pantrywork ships three tag files whose namespace is not `c:` or `pantrywork:`:

```
data/origins/tags/item/meat.json                     (since 0.1.0)
data/kaleidoscope_cookery/tags/item/oil.json         (0.8.0)
data/rusticdelight/tags/item/cooking_oil.json        (0.8.0)
```

This looks like it breaks rule 2 ("never re-classify another mod's own tag choices"). It does not, and
the distinction is worth stating because it will come up again.

- **It adds, it never subtracts or replaces.** A datapack tag file with `replace: false` semantics
  (the default) merges with the mod's own definition. Kaleidoscope's own oil and Rustic Delight's own
  oil stay exactly where they are; the file only widens the pool their *own* code or recipes already
  consume.
- **It is only legitimate where the mod reads a tag of its own instead of a shared one.** Kaleidoscope
  Cookery's wok decides what counts as oil in code, `ItemStack.is(TagMod.OIL)` against
  `#kaleidoscope_cookery:oil`, with exact-id fallbacks only for its own shovel and oil can. Rustic
  Delight's fried-food recipes read `#rusticdelight:cooking_oil`. There is no shared `c:` tag either of
  them consults, so bridging *into* the shared vocabulary would change nothing: the only door is the
  mod's own tag. If a mod reads a `c:` tag, that is where the bridge goes, every time.
- **Every id in them is `required: false`**, like every other cross-mod reference, so the files are
  inert without the mod they name and cannot fail a datapack load.
- **They are judged by the same cost floor.** Both tags are declared in `cost-floors.json` with the
  owning mod's own cheapest member as the floor, and `AuditRoles.ps1` check 7 walks them like any
  other judged tag — it is what keeps Kaleidoscope's 1/4 oil out of Rustic Delight's tag (x3.00) and
  what accepted Pam's at exactly x1.50 there.
- **They are hand-authored, not generated**, because the generator's emit path hardcodes the `c:`
  namespace and the build ships only `src/generated/resources/data`. The accepted cost: a future
  Rustic Delight, Pam's or Cook's oil is not picked up until someone edits the file.

What stays forbidden is unchanged: never *remove* from another mod's tag (a datapack cannot), never
re-file another mod's item under a different identity, and never add an item that fails that tag's
own floor.

### The shared salt dialect: `c:dusts/salt` (0.8.0)

The newer Farmer's Delight addons settled on a salt tag none of the older mods had heard of. Measured
from the jars: `c:dusts/salt` is defined by Cook's Collection (its own salt), Cultural Delights (the
same id, `required: false` — Cook's is CD's hard dep) and Hearth and Harvest (its own), and read by 36
recipes (Hearth and Harvest 25, Cultural Delights 7, Cook's Collection 4). Declared floors:
Cook's 1/4, Cultural Delights 1/4, Hearth and Harvest 1/32.

- **Unconditional** (x1.00 against Cook's and CD, x0.125 against H&H): `hybrid_delights:salt`,
  `meadow:alpine_salt`, `refurbished_furniture:sea_salt`.
- **GATE `hearthandharvest`**: `croptopia:salt` (1/16, x4.00 against Cook's and CD) and
  `pamhc2foodcore:saltitem` (1/8, x2.00 against both).
- Nothing was dropped, and no `pantrywork:bridged/*` enumeration was needed.

The trap, resolved by measurement rather than argument: Cook's Collection's own `c:salt` and
`c:salts` are *literally* `#c:dusts/salt`, so both gated entries are also reachable from those two
tags, and a naive reading says the gate leaks. It does not. The only route in is through Cook's own
reference, so `cookscollection` is on the path's mod list, and Cook's chased floor in `c:salt` and
`c:salts` is Hearth and Harvest's 1/32 — the cheapest salt in the scanned set — so Cook's rescues
anything `c:dusts/salt` can hold. In play the gate is honest for the same reason: the overlay applies
only while Hearth and Harvest is loaded, and H&H's own 1/32 salt is natively in `c:dusts/salt` then,
so Croptopia's 1/16 and Pam's 1/8 dilute nothing that is not already there upstream. The same chase is
what widened the `c:salts` gate on Pam's salt from `croptopia` to `cookscollection_or_croptopia`; it
is the one floor row where the chase reaches a mod the judged item does not imply, and it is recorded
as a judgment in `cost-floors.json`.

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
which defines the tag or has migrated. **Update 0.8.0:** Cultural Delights 0.18.1,
the build now in the scanned set, dropped all four of its `c:foods/milk`
references, so it no longer needs the shim. The other three addons still do, and
none of them is in the scanned set, so the shim stays exactly as it is.

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
wrong in cause, and the earlier wording of this footnote ("twelve of them") was
wrong in detail. Re-counted out of `letsdo-vinery-neoforge-1.5.3.jar` on
2026-10-07: it ships **9** files under the PLURAL `data/*/tags/items/` path (the
1.21.2+ layout) — **6 of them `c:`** (`berries`, `grapes`, `milk`, `seeds`,
`stripped_logs`, `stripped_wood`), plus two `candlelight:` and one `create:` — while
its **36** item-tag files under the singular `data/*/tags/item/` are all
`minecraft:` and `vinery:`. The 1.21.1 loader reads only the singular path, so not
one of those six `c:` tags loads here. They are dead data on this line — which is
why Vinery still needs its per-item module. Re-check this if Vinery is ever added
to a 26.x harness, where the plural path does load and `c:berries`, `c:grapes`,
`c:milk` and `c:seeds` would suddenly go live (`c:seeds` in particular feeds the
seed rule).
