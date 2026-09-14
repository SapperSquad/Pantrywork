# Changelog

## 0.7.0 — 2026-09-13

**Four more mods, cooked eggs, and swaps that have to be fair.**

What you get: Create, Bountiful Fares, Fish of Thieves and Refurbished Furniture join the
bridges; cooked eggs and Brewin' & Chewin' preserves reach the recipes that want them; and the
shared flour, corn, salt and vegetable tags now hold the mods that were missing from them. What
you lose: some swaps older versions allowed, where the stand-in was much cheaper than what the
recipe was balanced for. Every one of them is listed below, with the reason.

### New

- **Create, Bountiful Fares, Fish of Thieves and Refurbished Furniture**, all from player
  feedback.
  - *Create*: its dough and wheat flour work in Pam's recipes. In Croptopia's recipes the dough
    needs Farm & Charm installed, and the flour needs Bountiful Fares, Farm & Charm or Pam's (see
    "How swaps are judged"). Farmer's Delight and its addons already took the dough.
  - *Refurbished Furniture*: its cheese, wheat flour, sea salt and dough carried no tags at all.
    They now join the cheese, flour, salt and dough tags the other mods read.
  - *Bountiful Fares*: its maize reaches the corn tags Croptopia and Farm & Charm read. Its
    oranges, lemons, plums, elderberries and walnuts reach Croptopia's per-fruit tags, and the
    other mods' corn and fruit reach Bountiful Fares' own `c:foods/<fruit>` tags in return.
  - *Fish of Thieves*: its fruit sat under tags no recipe reads, so it now joins the shared
    `c:fruits` pool. Banana, coconut, mango and pineapple also reach Croptopia's recipes for
    those fruits (Croptopia's pineapple chicken takes a Fish of Thieves pineapple). Its ten raw
    fish work in Pam's and Farm & Charm's fish recipes (the cooked ones join the cooked-fish
    tags too, which no recipe reads yet).
- **Cooked eggs.** Pam's fried egg, Bountiful Fares' cooked egg and Croptopia's sunny-side eggs
  join `c:foods/cooked_egg`, so Farmer's Delight's egg sandwich and bacon and eggs accept them.
  Each costs one egg, the same as FD's fried egg. Boiled and scrambled eggs stay out. All three
  also count as protein in role-tag recipes.
- **Brewin' & Chewin' preserves fill Pam's jelly slots.** Sweet berry jam, glow berry marmalade
  and apple jelly work where Pam's asks for that flavour of jelly. They cost more than Pam's
  jelly, so nothing gets cheaper.
- **Shared tag names are written directly.** 0.6.0 called `c:flour` and `c:crops/corn` already
  merged because several mods declare those names. That held only for the mods that declare
  them: Create's flour reached `c:flour` only through a Farm & Charm reference, Refurbished's
  flour carried no tag at all, and Bountiful Fares' maize reached no corn tag. Pantrywork now
  also writes into `c:flour`, `c:flours`, the corn tags, `c:salt`, `c:salts` and `c:vegetables`,
  adding only what a tag is missing. One example: Create's wheat flour now reaches `c:flour`
  without Farm & Charm, as long as Pam's or Bountiful Fares is installed. It also writes
  `c:cabbage`, `c:onions`, `c:tomatoes` and `c:rice`, which changes nothing in play: only
  Croptopia's recipes read those four, and Croptopia's own tags already held the same items.

### Fixed: bugs that were already shipping

- **Cheap milk in bucket recipes.** 0.6.0 put Croptopia's milk bottle (16 per bucket) and its
  soy milk (no milk at all) into `c:milk`, which Farm & Charm, Meadow and Pam's read as a full
  bucket; Meadow's cheese tart is one such recipe. It also put both, plus Pam's fresh milk (8 per
  bucket), into `c:drinks/milk`, which feeds Farmer's Delight's cake, pie crust, hot cocoa and
  custard, balanced for FD's 4-per-bucket bottle. All of those are out.
- **Blocks in food tags.** The melon block and the pumpkin block had been copied from Pam's tags
  into `c:foods/fruit` and `c:foods/vegetable`. Brewin' & Chewin's ripe cheese wheels, which are
  placeable blocks with no food value, had sat in every cheese tag and the dairy role since
  0.3.0. All out. Melon slices stay in `c:foods/fruit` and `c:fruits`, and B&C's cheese wedges still count as
  cheese everywhere.
- **Bridges that quietly needed a third mod.** The generator skipped any item a tag could already
  reach, even through another mod's reference. So Croptopia dough reached Pam's recipes only
  when Farm & Charm was installed, and Farm & Charm strawberries reached `c:fruits` only
  alongside Croptopia. It now skips only what a tag lists itself, and a test boot without Farm &
  Charm proves it. The same fix means that, without Pam's installed, Croptopia's any-fruit
  recipes also accept vanilla chorus fruit, glow berries and sweet berries, and on Minecraft 26.x
  Croptopia's vegetable recipe accepts carrots, potatoes and beetroot.
- **Largemouth Bass went missing in 0.6.0.** That generator run left out the 26.x jars. The bass
  is back in the fish bridges.

### How swaps are judged now

The rule behind the milk fix now covers every item Pantrywork adds to a tag that some recipe
reads, including items it adds through its own `c:foods/*` references.

- An item's **cost** is the cheapest way to make it with its own mod, in the natural unit of its
  kind (milk buckets, whole meat or fish, wheat, whole fruit, bread), counting how many one craft
  makes and small extras such as sugar, salt or a glass bottle.
- A tag's **floor** is worked out separately for each mod that defines the tag: the cheapest item
  that mod lists there itself.
- An added item may be up to 1.5x cheaper than each floor. If it is cheaper than that for some
  mod, but another mod that defines the tag already lists something as cheap, the item is added
  **only while that other mod is installed**: that mod's own recipes already accept an item that
  cheap. Otherwise it is not added at all.
- Those conditional entries ship as pack overlays declared in `pack.mcmeta`, which the game
  applies only while the named mod is loaded. There are 8 of them.

What the rule does not cover:

- **What a mod puts in its own tags.** Croptopia's 16-per-bucket bottle stays in Croptopia's own
  `c:milks`, and FD's bottle stays in FD's `c:drinks/milk`. That is those mods' call.
- **Role tags** (`pantrywork:food_component/*`). They describe what an ingredient does and have no
  price floor: `dairy` holds milk bottles and plant milk next to buckets, and `protein` holds FD's
  cooked cuts. A recipe written against a role tag accepts all of them.
- **Fabric without Fabric API.** That setup does not start. On Fabric, Pantrywork's data,
  conditional entries included, is loaded by Fabric API, so both Fabric files now declare it as a
  required dependency: without it Fabric Loader refuses to start and names the missing dependency.
- **Recipe changes in the other mods.** Costs come from the recipes in the mod versions
  Pantrywork was built against. The numbers and every judgment call are in
  `tools/cost-floors.json`.

### What stopped working (compared with 0.6.0)

Out entirely:

- **Milk and cheese.** Croptopia's milk bottle and soy milk in bucket-milk recipes (`c:milk`) and
  in Farmer's Delight's cake, pie crust, hot cocoa and custard (`c:drinks/milk`). Pam's fresh milk
  in those Farmer's Delight recipes. Farmer's Delight's milk bottle in `c:foods/milk`, the old tag
  name that Bountiful Fares' cocoa cake and its version of the vanilla cake still read: those two
  recipes now need a milk bucket (or BF's own coconut milk). Croptopia's cheese and butter in `c:cheese` and `c:butter` (Pam's, Meadow
  and Farm & Charm recipes), because they are made from its 16-per-bucket bottle; they still work
  in Croptopia's own tags and wherever `c:foods/cheese` or `c:foods/butter` is used.
- **Half-portion cuts as a whole animal.** Pam's whole-meat and raw-fish recipes no longer take
  Farmer's Delight bacon and cooked bacon, minced beef, chicken cuts, mutton chops, or raw cod and
  salmon slices; Farm & Charm bacon, chicken parts, or bacon and eggs; or Ocean's Delight's fugu
  and elder guardian slices. Farm & Charm's raw beef and raw fish recipes drop the same minced
  beef and raw slices. Farmer's Delight's cuts still work where Farm & Charm's own tags already
  hold cuts (its pork, chicken and cooked beef tags).
  Tag-only, no recipe affected: Pantrywork also stopped adding Farmer's Delight beef patties,
  cooked chicken cuts, cooked mutton chops and cooked cod and salmon slices, Farm & Charm's roasted
  chicken, Aquaculture's cooked fish fillets (an Atlantic halibut fillets into 14) and Ocean's
  Delight's cooked elder guardian slice to Pam's cooked-meat and cooked-fish tags and Farm &
  Charm's mutton and cooked-fish tags. No recipe in the supported mod versions reads those tags,
  so this changes nothing in play.
- **Farmer's Delight's own slots.** FD's dough, pasta, bread and cooked chicken tags no longer
  take Farm & Charm's dough, pasta, farmer's bread or roasted chicken, or Pam's pasta (Farm &
  Charm gets 12 yeast from one wheat and 5 dough from one flour). FD's meat and fish tags no
  longer take Meadow's cooked buffalo meat or Ocean's Delight's fugu and elder guardian slices
  (raw and cooked); both raw slices had also landed in FD's `safe_raw_fish`.
- **Everything else.** Pam's toast in Croptopia's toast recipes (Pam's toast is half a loaf plus
  butter; Croptopia's is a whole loaf). Pam's cooking oil as Croptopia's olive oil (4x cheaper).
  Croptopia's apple and melon juice in Pam's apple and melon juice recipes (one apple or one melon
  slice against Pam's two; the glass bottle comes back when the juice is used). Croptopia's ground
  pork in Pam's ground pork and ground meat recipes: Croptopia presses it from pork or from tofu,
  so its cheapest version holds no meat. Farmer's Delight's cabbage leaf as a whole vegetable in
  `c:foods/vegetable` (half a cabbage). And the non-food blocks under "Fixed".

Now kept only while another mod is installed (all unconditional in 0.6.0). The mod named is one
whose own recipes already accept something as cheap, so the swap always works in that mod's
recipes; what changes is the other mods' recipes when it is missing:

- Farmer's Delight's milk bottle in `c:milk` (Farm & Charm's and Meadow's bucket-milk recipes):
  only while Pam's HarvestCraft 2 is installed.
- Farmer's Delight's milk bottle and Pam's fresh milk in `c:milks` (Meadow's milk recipes): only
  while Croptopia is installed.
- Pam's cheese in `c:cheeses`: only while Croptopia is installed. Croptopia's recipes are the only
  ones that read that tag, so this changes nothing in play.
- Farmer's Delight's and Pam's dough in `c:doughs` (Croptopia's dough recipes): only while Farm &
  Charm is installed.
- Pam's dough in `c:foods/dough` (Farmer's Delight's dough recipes): only while Create is
  installed.

New in 0.7.0 and conditional from the start:

- Create's dough in `c:doughs` (Croptopia's dough recipes): only while Farm & Charm is installed.
- Create's wheat flour in `c:flour` (Croptopia's flour recipes): only while Bountiful Fares, Farm &
  Charm or Pam's is installed. With Farm & Charm it was already there through Farm & Charm's own
  `c:flours` reference; with Pam's or Bountiful Fares and no Farm & Charm it is new.
- Pam's salt in `c:salts` and Farmer's Delight's cabbage leaf in `c:vegetables`: only while
  Croptopia is installed. Neither changes anything in play: Croptopia's own `c:salts` and
  `c:vegetables` already reach both items whenever it is installed, as they did in 0.6.0.

Where Croptopia is the condition, Croptopia Refabricated (Fabric 1.21.10) counts too. On
Minecraft 26.x, Farm & Charm, Pam's, Create and Bountiful Fares have no builds, so their
conditions never switch on there: Farmer's Delight's dough no longer works in Croptopia's dough
recipes on 26.x. FD's milk bottle still works in Croptopia's milk recipes there.

### Deliberately not bridged

- Refurbished Furniture's toast, bread slices and jams. One loaf makes six Refurbished toast, and
  its jam is a single berry with no sugar. In other mods' recipes they would undercut what those
  recipes were balanced around.
- Bountiful Fares' "Coconut", which is the palm tree's planting item, not food. Its edible Coconut
  Half has no match in any other mod.
- Items from mods Pantrywork has not examined. Bountiful Fares' tags list optional ids for mods
  such as Nature's Spirit and Atmospheric; those ids are no longer copied into other mods' tags.

### Can't be fixed with tags

- Refurbished Furniture's own recipes name its exact items, so no other mod's cheese, flour, toast
  or jam will work *inside* them. That needs a change in Refurbished Furniture.
- Bountiful Fares' coconut-splitting recipe names its own coconut, so other mods' coconuts can't
  be halved.

### Under the hood

- 57 → 88 generated tag files, 8 of them conditional, in 5 pack overlays. Costs and floors live in
  `tools/cost-floors.json`, the rule in `tools/CostFloor.ps1`.
- `AuditRoles.ps1` now also fails the build on non-food items, on any Pantrywork path that
  delivers an item below a floor without a condition that rescues it, on a floor declared for a
  mod whose jars never define that tag, on NeoForge and Fabric overlay conditions that disagree,
  on required item ids from optional mods, and on bridges that depend on a third mod.
  `GenerateBridges.ps1 -SelfTest` plants a seed, a sapling, a fruit pit, an unexamined mod's item
  and two too-cheap milks, then proves each is kept out or made conditional.
- Both Fabric files now declare Fabric API as a required dependency in `fabric.mod.json` (Fabric API
  is what loads mod data on Fabric). Without it Fabric Loader refuses to start and names the missing
  dependency.
- Verified on the NeoForge 1.21.1 dev server with every supported mod (13 suites, 391 checks, 7
  GameTests), with Farm & Charm removed, and with no food mods. The release jars were booted on
  dedicated servers: NeoForge 1.21.1 (alone, and in five mod combinations that switch the Pam's,
  Croptopia, Create and flour conditions on and off; the Farm & Charm condition was switched on the
  dev server, with and without Farm & Charm), NeoForge 26.1.2 and 26.2, and Fabric 1.21.1,
  1.21.10, 1.21.11, 26.1.2 and 26.2. Create and Bountiful Fares have no 26.x builds, and the four new mods were not booted on
  Fabric.

## 0.6.0 — 2026-08-30

**Ten more dialect bridges, and life support for a tag Farmer's Delight deleted.**

- **New: `c:foods/milk` deprecation shim.** FD invented that tag, then deleted it
  in 1.21.1-1.3.0; addons still referencing it don't just miss an ingredient —
  an undefined tag fails ingredient decoding and Minecraft drops the whole
  recipe. Counted first-hand across four addon jars: Arbitrary Delight 16
  recipes, Cultural Delights 4, Pineapple Delight 3, Nature's Delight 2.
  Restored with FD's own final contents, item-for-item: milk bucket + milk
  bottle. Explicitly **not** `#c:drinks/milk`, which resolves to six items here
  (Pantrywork's own bridges widen it) and would let a 16-per-bucket Croptopia
  bottle or cowless soy milk satisfy recipes written against a two-item tag.
  Contained by an `AuditRoles.ps1` check: never joined to `#c:foods`, never
  referenced by a role tag, never widened. Documented in TAXONOMY.md as a named
  exception with a sunset note — the real fix is for those addons to move to
  `c:drinks/milk`, which Pantrywork already resolves fully.
- **Ten more dialect collisions bridged**, found by auditing every `c:` tag the
  supported mods define: the cereal family (Croptopia `grain/<crop>`, Farm &
  Charm `grains/<crop>s`, FD `crops/grain` — none could see the others), the
  apple and melon juice spellings, `c:toasts`/`c:toast`, `c:ground_pork` vs
  `c:groundmeats/groundpork`, FD's cookies into `c:cookies`, and F&C's isolated
  `c:flours`. 38 → 57 generated bridge files.
  - Deliberately left alone: `c:caramel`, `c:flour`, `c:grain`, `c:bread`,
    `c:egg` and `c:crops/corn` are each declared by two or more mods already, so
    they merge at load and need no bridge.

## 0.5.0 — 2026-08-29

**Two correctness fixes.** No new mods bridged; this one is about the bridges
already there being right.

- **Fixed: planting seeds are no longer food.** Croptopia files its seeds
  *inside* its produce tags, so referencing those tags pulled 13 seeds into
  `c:foods/vegetable` and the `garnish` role — a lettuce seed satisfied any
  recipe asking for a garnish. Produce is now enumerated item-by-item with the
  seeds dropped. Croptopia's vegetables and fruits still bridge exactly as
  before; only the seeds are gone.
  - Seeds are identified by the ecosystem's own `c:seeds` classification rather
    than by name, so plantable *foods* (Farm & Charm's onion) and edible seed
    foods (Croptopia's roasted pumpkin and sunflower seeds) correctly stay food.
- **Fixed: a lone install could refuse to load.** Three references to
  convention tags (`c:foods/berry`, `c:buckets/milk`) were marked required. On
  Fabric without Fabric API — a setup the README explicitly invites — those tags
  are undefined, and a required reference to an undefined tag fails datapack
  loading outright. Now optional, as every cross-mod reference should be.
- **New: `tools/AuditRoles.ps1`** resolves every tag this mod asserts and fails
  the build on either problem, so neither can come back. Its `-Minimal` mode
  audits the no-Fabric-API case that the previous test matrix never covered.

## 0.4.0 — 2026-08-22

**NeoForge comes to Minecraft 26.x.**

- **New artifact: `-neoforge-mc26`**, a data-only NeoForge jar for Minecraft
  26.1–26.2 (no-code FML loading; the `PantryworkTagKeys` class stays
  1.21.1-line-only until the 26.x rename churn is worth chasing). Verified
  live on NeoForge 26.1.2.94 — the exact build All the Mods 11 ships —
  solo and alongside ATM11's own food mods (Croptopia 4.3.1 + Aquaculture
  2.9.2), and on NeoForge 26.2.0.64 solo and with Croptopia's 26.2 build.
- **Aquaculture 2.9.x's new Largemouth Bass** joins the generated fish
  bridges (`c:fishes`, `c:raw_fishes`, `c:rawfish`).
- **Croptopia 4.3.x re-verified on 26.x, both loaders.** Its new foods ride
  the fruit/vegetable umbrella tags through the forward bridges; its 26.x
  port dropped its own `c:fishes` definition, so on 26.x that dialect tag
  now exists purely through Pantrywork's generated union.
- **Fabric 26.2 coverage deepened**: Croptopia reached 26.2 (it was
  FD-only there at 0.2.0), and the cross-mod smoothie craft is now
  verified on 26.2 as well. FD Refabricated bumped to 3.6.17 in the
  harnesses (no tag drift).
- **Vanilla 26.1/26.2 audited for new foods: none exist** (26.1's Golden
  Dandelion is mob feed, not player food; 26.2 added no edibles), so the
  taxonomy needed no vanilla additions. Data formats 101.1 and 107.1 both
  parse the payload unchanged — confirmed by the live boots.
- Build/tooling: `neoJar26` Gradle task, NeoForge 26.1.2/26.2 RCON test
  harnesses (`tools/neo-server-*`), `GenerateBridges.ps1 -ExtraJarDirs`
  for unioning 26.x-only compat jars into the bridges.

## 0.3.0 — 2026-08-09

**Aquaculture 2 and Brewin' & Chewin' support.**

- **Aquaculture 2**: its 27 fish already use the official `c:foods/raw_fish`
  dialect, so they now flow into the other mods' fish tags too — a Pam's,
  Ocean's Delight, or Farm & Charm recipe that wants fish will accept any
  Aquaculture catch, and its cooked fillet counts as a protein everywhere.
- **Brewin' & Chewin'**: its four ripe cheeses join the shared cheese pool
  (so they work in any mod's cheese recipe, and vice versa), its sixteen
  fermented drinks join `c:drinks`, and its soups were already canonical.
- Under the hood, the reverse-bridge generator now follows food that a mod
  files behind its *own* namespaced tags (like Brewin's), not just `c:`
  tags — so future mods that do the same are handled automatically.

## 0.2.0 — 2026-08-08

**Let's Do series support, Minecraft 26.x, and a wider Fabric range.**

- **New: Let's Do compat** — Vinery, Farm & Charm, and Meadow.
  - *Meadow* is the headline: its cheese and salt recipes now accept
    Croptopia's, Pam's, and Farmer's Delight's equivalents, and its cheeses
    and buffalo meat feed the role tags.
  - *Farm & Charm* introduced a third meat dialect (flat-underscored
    `c:raw_pork` vs Pam's `c:rawpork`); every canonical meat tag now bridges
    all three, both directions.
  - *Vinery* ships no common tags at all, so it gets a per-item module:
    grapes and cherries into `c:foods/fruit`, its juices and cider into
    `c:drinks`.
- **Fix: seeds no longer cross bridges.** Croptopia files its seeds inside
  its produce tags; without this, a seed could have satisfied another mod's
  food recipe.

- **New: Fabric jar for Minecraft 26.x** (`-fabric-mc26`), verified live on
  26.1.2 (Farmer's Delight Refabricated 3.6.15 + Croptopia 4.3.1, including
  a cross-mod craft) and on 26.2 (FD Refabricated). 26.x kept the
  `data/c/tags/item` layout and both mods kept their tag dialects, so the
  bridges port unchanged.
- **Fabric 1.21.x range widened to 1.21.1–1.21.11**, verified live on
  1.21.10 (FD Refabricated + Croptopia Refabricated) and 1.21.11 (FD
  Refabricated). The in-jar range is now explicit (`>=1.21.1 <1.22`).
- NeoForge stays 1.21.1-only: Farmer's Delight, Pam's HarvestCraft 2, and
  Croptopia's NeoForge builds have nothing newer to bridge yet.

## 0.1.0 — 2026-07-20

Initial release. NeoForge 1.21.1 (21.1.241+) and Fabric 1.21.1.

- Identity layer: extends the official `c:foods/*` convention (cheese,
  butter, dough merges, cooked_rice, raw/cooked meat parent joins) and
  bridges Croptopia's and Pam's HarvestCraft 2's tag dialects into it.
- Role layer: `pantrywork:food_component/{protein,starch,dairy,garnish,liquid_base,sweetener}`
  as tags-of-tags over the identity layer.
- Reverse bridges (generated): 24 dialect tags gain other mods' equivalent
  items, so Croptopia/Pam's own recipes accept foreign ingredients.
- Compat modules: Farmer's Delight, Croptopia, Pam's HC2 Food Core,
  Ocean's Delight (full identity module), End's Delight (parent joins),
  Origins (carnivore/vegetarian diet tag).
- `PantryworkTagKeys` API class for downstream mods (NeoForge jar).
- Ships for **both NeoForge and Fabric** on 1.21.1 — the Fabric jar is
  data-only (no code, no Fabric API dependency), verified live against
  Farmer's Delight Refabricated + Croptopia Fabric. *(Corrected 2026-09-13:
  on Fabric, mod data is loaded by Fabric API, so Fabric API has always been
  needed. From 0.7.0 the Fabric files declare it, and without it Fabric Loader
  refuses to start and names the missing dependency.)*
- All data entries for other mods are optional — any subset of supported
  mods works.
