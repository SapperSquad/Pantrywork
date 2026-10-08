# Changelog

## 0.8.0 — 2026-10-06

**Six more mods, and the wok finally lights.**

What you get: Kaleidoscope Cookery, Hearth and Harvest, Cultural Delights (with Cook's
Collection), Rustic Delight and Hybrid Delights join the bridges — all five from one player
report — and Oh The Biomes We've Gone from a sixth report in the same thread. The headline is
Kaleidoscope Cookery's wok: it will not cook until it is primed with
oil, it decides what counts as oil by reading a tag, and that tag now holds five mods' oils.
Salt, butter, cabbage, onion, tomato, bell peppers and blueberries all travel further than they
did. What
you lose: nothing was taken out of a tag in this release. Two swaps gained a condition and
three conditions got easier to satisfy; every one of them is listed below, with the reason.

### New

- **Kaleidoscope Cookery, Hearth and Harvest, Cultural Delights + Cook's Collection, Rustic
  Delight and Hybrid Delights**, all from player feedback. All five are Farmer's Delight addons
  on NeoForge 1.21.1; Rustic Delight and Hybrid Delights also ship for Fabric 1.21.x (and Rustic
  Delight for Fabric 26.x), so their bridges are live on the Fabric files too — though no Fabric
  test harness carries any of the five, so the Fabric side is proven by the data and the
  NeoForge boots rather than by a Fabric boot.
- **The wok takes other mods' oil.** Kaleidoscope Cookery's pot has to be primed with cooking
  oil before it will cook anything, and its code decides what counts by checking the tag
  `#kaleidoscope_cookery:oil` rather than its own item id. Pantrywork now writes that tag, so
  Hearth and Harvest, Cook's Collection and Rustic Delight cooking oil, Croptopia olive oil
  and Pam's cooking oil all prime it. That is the gate in front of **all 225 of the wok's
  recipes** (198 pot, 27 flex pot). The Oil Can refill and the butter tea bag name
  Kaleidoscope's exact oil item, so those two still need its own oil.
- **Kaleidoscope's fried egg is a cooked egg again.** It was filed in `c:foods/cooked_eggs` —
  plural, and nothing anywhere reads it. It now joins `c:foods/cooked_egg` (singular, the tag
  that is actually read), so Farmer's Delight's egg sandwich and bacon and eggs and Cultural
  Delights' four egg recipes accept it. It costs 1.011 eggs against FD's fried egg at 1.
- **Kaleidoscope's dough travels.** Into Croptopia's 13 dough recipes (only while Farm & Charm
  is installed — see "How swaps are judged"), and into Farmer's Delight's `c:foods/dough`,
  which 11 recipes across seven mods read. Its flour, and other mods' dough going the other
  way, already worked.
- **Hybrid Delights' salt works where salt is asked for.** Its salt carried no tags at all. It
  now joins `c:salt` and `c:salts`, which is 75 recipes (Pam's 17, Croptopia 45, Meadow 13).
  Hybrid Delights makes salt from Hybrid Aquatic brine, so the item only exists when that mod
  is installed too; without it the entry is simply inert.
- **A fifth salt spelling bridged.** Hearth and Harvest, Cultural Delights and Cook's
  Collection share a salt tag the older mods never heard of (`c:dusts/salt`), read by 36
  recipes (Hearth and Harvest 25, Cultural Delights 7, Cook's Collection 4). Hybrid Delights'
  salt, Meadow's alpine salt and Refurbished Furniture's sea salt now reach it outright;
  Croptopia's and Pam's salt reach it only while Hearth and Harvest is installed, because
  Hearth and Harvest's own salt is cheaper than either of them.
- **Oils reach the other mods' oil slots.** Hearth and Harvest, Rustic Delight and Cook's
  Collection oil now work in Pam's 16 cooking-oil recipes. Cook's Collection oil — four
  sunflowers a bottle, the dearest of the five — also works in Croptopia's 25 olive-oil
  recipes. And Croptopia, Cook's Collection, Hearth and Harvest and Pam's oil all work in
  Rustic Delight's own oil tag, read by 10 recipes. The other oils stay out of Croptopia's
  olive oil: Hearth and Harvest's is 2x cheaper, Rustic Delight's 2.67x, Pam's 4x.
- **Butter.** Hearth and Harvest's and Cultural Delights' butter join Croptopia's `c:butters`,
  which 15 recipes read. (This is **not** the fix for "Hearth and Harvest butter and Cultural
  Delights butter are not interchangeable" — see "Can't be fixed with tags".)
- **Oh The Biomes We've Gone's blueberries**, from a sixth report in the same thread
  ("blueberries from Biomes You'll Go are incompatible with any other modded blueberry" — the
  mod renamed itself, the report is otherwise exactly right). BYG files its blueberries in its
  own `c:foods/berry` and in **no blueberry tag at all**, so no other mod could see them. They
  now join `c:fruits/blueberry`, which Hearth and Harvest's five blueberry recipes read
  (muffin, pie, cooking-pot jam, stomped juice, crate) and which Croptopia's own `c:blueberries`
  references, so Croptopia's three (jam, seed, scones) read it too — **eight recipes**. They
  also join `c:blueberries` directly and `c:fruits`, along with BYG's green apple, baobab fruit
  and yucca fruit. The `c:blueberries` entry is belt and braces, not a recipe fix: every
  Croptopia build that reads that tag also carries the `#c:fruits/blueberry` reference, so it
  unlocks nothing on its own — it only stops the bridge depending on Croptopia's own reference.
  Croptopia and Hearth and Harvest already interoperated both ways; nothing about that changed.
  BYG is a worldgen mod rather than a cooking mod, which is why it is counted on the roster for
  the four fruits it grows and nothing else.

### Also fixed: gaps nobody reported

Found while tracing the five mods above, and independent of them.

- **Cabbage and leafy greens never met.** `c:foods/cabbage` and `c:foods/leafy_green` are
  Farmer's Delight's tags and nothing connected them to Croptopia's or Farm & Charm's crops,
  so Croptopia cabbage and Farm & Charm lettuce were invisible to 22 recipes (Farmer's
  Delight 11, Cultural Delights 5, Rustic Delight 4, Brewin' & Chewin' 1, Ocean's Delight 1).
  Both now reach both tags.
- **Onion and tomato.** `c:foods/onion` and `c:foods/tomato` are new emit targets, so
  Croptopia's and Farm & Charm's onion and tomato, and Kaleidoscope's tomato, reach the 10
  recipes that read them. Two of those are Farmer's Delight's own: Rustic Delight overrides
  FD's fried rice and baked cod stew and narrows their onion and tomato slots to these two
  tags, so with Rustic Delight installed those two recipes used to refuse every onion and
  tomato but FD's. They work again.
- **Rustic Delight's bell peppers.** All nine whole peppers (black, blue, green, orange, pink,
  purple, red, white, yellow) join the vegetable tags, read by 23 recipes (Pam's 21,
  Kaleidoscope Cookery 2). Its pepper *slices* and potato slices are half a vegetable and are
  conditional — see below.
- Cultural Delights' vegetables ride in with them: cucumber, eggplant, white eggplant, smoked
  eggplant, smoked white eggplant, beans, pickle and corn cob.

### How swaps are judged

Unchanged from 0.7.0: an item Pantrywork adds to a tag some recipe reads may be at most 1.5x
cheaper than the cheapest thing each mod that defines that tag already lists there. Too cheap
for some of them but matched by another's own floor, and it ships only while that other mod is
installed, as a pack overlay the game applies conditionally. Too cheap for all of them, and it
is not added at all. The numbers and every judgment call are in `tools/cost-floors.json`.

0.8.0 settled two conventions the new mods forced:

- **A planting seed costs its share of the produce it is made from.** One pumpkin crafts into
  four seeds, so a pumpkin seed is a quarter of a pumpkin. That is what prices Kaleidoscope's
  own oil (its millstone takes any seed) and Rustic Delight's oil (six pumpkin seeds make two
  bottles, and Farmer's Delight's cooking pot gives the bottle back).
- **A route that starts at a mob drop is not a cheaper route.** Cost measures processing
  effort, not scarcity. Kaleidoscope's oil is not free because pigs drop it to a kitchen
  knife, the same way salt is not free because water is.

One consequence is worth saying plainly. Under those two rules Pam's cooking oil is exactly
half the cost of Kaleidoscope's, well inside tolerance, so it primes the wok. And Pam's oil
against Rustic Delight's own oil tag lands on exactly 1.5x — the edge of the tolerance, and a
pass. The rule has no mechanism for dropping something that passes, and inventing one to taste
would make every other number mean less, so it is in.

Rustic Delight's oil recipe, nine of the ten recipes that read its oil tag, and its potato and
bell-pepper slice recipes all sit behind Rustic Delight's own config flags (on by default).
The cost model has no concept of a config flag: turn those off and the items and recipes it
judged are simply not there.

### What changed (compared with 0.7.0)

**Nothing was removed.** No item left a tag in this release — checked entry by entry against
the 0.7.0 data. What follows is two swaps that gained a condition, three conditions that got
easier to satisfy, and two swaps that come back conditionally after 0.7.0 dropped them.

Now conditional, where they were not before:

- **Farm & Charm's chicken parts in `c:foods/raw_chicken`: only while Farmer's Delight is
  installed.** Kaleidoscope Cookery also defines that tag and lists the whole vanilla chicken
  in it, so a third of a chicken is 3x below its floor. Farmer's Delight's own cut is half a
  chicken, within tolerance, so FD's recipes already accept something that cheap. Eleven
  recipes read the tag (Kaleidoscope 6, Farmer's Delight 2, Cultural Delights 2, Rustic
  Delight 1), and Cultural Delights and Rustic Delight require Farmer's Delight anyway, so
  this only bites Kaleidoscope's six, with Farm & Charm installed and Farmer's Delight absent.
- **Kaleidoscope's sashimi in `c:foods/raw_fish`: only while Farmer's Delight or Rustic
  Delight is installed.** It is a third of a fish, against whole-fish floors from NeoForge,
  Aquaculture and Fish of Thieves; FD's and Rustic Delight's own half-fish cuts are the ones
  within tolerance of it.

Easier to satisfy than in 0.7.0 — strictly more installs get the swap:

- **Create's wheat flour in `c:flour`:** was Bountiful Fares, Farm & Charm or Pam's; now
  **also Kaleidoscope Cookery**, whose millstone turns one wheat into one flour.
- **Pam's salt in `c:salts`:** was Croptopia; now **Cook's Collection or Croptopia**. Cook's
  Collection files its own salt tags as the shared `c:dusts/salt`, so its recipes accept
  whatever lands there.
- **Farmer's Delight's cabbage leaf in `c:vegetables`:** was Croptopia; now **Croptopia or
  Kaleidoscope Cookery**, which floors that tag at half a vegetable through its own cabbage
  reference.

Back after 0.7.0 dropped them, conditionally:

- **Farmer's Delight's cabbage leaf in `c:foods/vegetable`, while Cultural Delights or Rustic
  Delight is installed.** 0.7.0 took it out entirely (half a cabbage against whole
  vegetables). Both new mods define that tag with their own half-vegetable cuts, so their
  recipes already accept a half portion.
- **Farmer's Delight's cod and salmon slices in Farm & Charm's `c:raw_fishes`, while
  Kaleidoscope Cookery is installed** — its own sashimi is a third of a fish. Cultural
  Delights' raw calamari and Rustic Delight's calamari slice ride the same condition.

New in 0.8.0 and conditional from the start:

- Hearth and Harvest's flour and corn meal in `c:flour`: only while Bountiful Fares or Farm &
  Charm is installed (half a wheat each; Croptopia's, Kaleidoscope's and Pam's floors are
  higher).
- Hearth and Harvest's salt in `c:salt` and `c:salts`: only while Cook's Collection is
  installed. Its salt is a thirty-second of a water bucket — the cheapest salt in the set —
  and Cook's Collection is the one mod whose own salt tags already reach it.
- Croptopia's and Pam's salt in `c:dusts/salt`: only while Hearth and Harvest is installed.
- Hearth and Harvest's goat milk bottle in `c:milk` (only while Pam's is installed) and in
  `c:milks` (only while Croptopia is installed) — the same two conditions Farmer's Delight's
  milk bottle already carries, for the same reason.
- Cultural Delights' corn dough and Kaleidoscope's dough in Croptopia's `c:doughs`: only while
  Farm & Charm is installed, joining Create's, Farmer's Delight's and Pam's dough there.
- Cultural Delights' four cuts (cucumber, eggplant, smoked eggplant, pickle), Rustic Delight's
  nine pepper slices and its potato slices in `c:vegetables`: only while Croptopia or
  Kaleidoscope Cookery is installed. Their whole-vegetable versions are unconditional.

Where Croptopia is the condition, Croptopia Refabricated counts too, and on Fabric the
Farmer's Delight conditions open for FD Refabricated, whose mod id is literally
`farmersdelight`. On Minecraft 26.x only Rustic Delight has a build at all, and only on Fabric;
no NeoForge 26.x build of any of the five exists, so on the two 26.x files almost nothing here
switches on. The payload is the same on all four files either way — an entry for a mod that is
not there is inert, which is the whole point of `required: false`.

### Can't be fixed with tags

- **Cultural Delights butter and Hearth and Harvest butter still are not interchangeable.**
  Both were already in `c:butter` before this release — that was never the problem. Their own
  recipes (five each) name the exact butter item instead of a tag, and no tag can change what
  a recipe asks for. Only those two authors can fix it. The Croptopia butter win above is a
  different thing and does not touch this one.
- The same goes for the other recipes in Refurbished Furniture, Hybrid Delights, Cultural
  Delights and Hearth and Harvest that name exact item ids. Hybrid Delights' eleven salt
  recipes are the clearest case: its salt now works in 75 other recipes, and nothing else
  works in its.
- Kaleidoscope Cookery's Oil Can refill and butter tea bag name its own oil item, so no other
  mod's oil refills the can.
- **Oh The Biomes We've Gone's own blueberry pie** names its berry by exact item id, so a
  Croptopia or Hearth and Harvest blueberry cannot bake it. The bridge runs outward only.

### Bugs found in the other mods

Listed here because they affect anyone running these mods together, and because none of them
is Pantrywork's to fix.

- **Kaleidoscope Cookery's wok eats the bottle.** Priming the pot shrinks the held stack by
  one with no container return, so a bottled oil (Hearth and Harvest, Cook's Collection,
  Rustic Delight) loses its glass bottle. Farmer's Delight's own cooking pot does return
  containers on the same kind of operation, which makes this easy to file as a bug rather
  than a design choice.
- **Cook's Collection ships a recipe that cannot load.** Its Brewin' & Chewin' compat pizza
  names `farmersdelight:dough`, an id Farmer's Delight renamed after 1.20. The recipe is
  gated on Brewin' & Chewin' being present, so it fails only when both mods are installed —
  and then it is not quiet about it: the recipe manager logs a parsing error with a stack
  trace on every load ("Parsing error loading recipe brewinandchewin:pizza_from_dough"),
  and the pizza is missing.
- **Kaleidoscope Cookery logs a tag error without Quark.** Its own item tag and its Carry On
  tag list its Quark-only furniture by id, not optionally, so a game without Quark reports
  missing references on load. Harmless, but it is the kind of line that makes a log look
  broken.

### Deliberately not bridged

- **The reverse direction for Rustic Delight's fish and cookies.** Outward they do travel: its
  calamari joins `c:fishes`, `c:rawfish` and `c:raw_fishes`, its cooked calamari `c:cookedfish`
  and `c:cooked_fishes`, and its three cookies `c:cookies`, so other mods' fish and cookie
  recipes take them. What is *not* bridged is the other direction. Nine of Rustic Delight's own
  calamari recipes name the item by id; the other three read `c:foods/raw_calamari`, which is a
  squid tag rather than a fish tag; and its three cookie recipes are crafted from its own
  flavour tags, not from a cookie tag. So no other mod's fish or cookie can stand in, and
  nothing a datapack writes changes that. A full Rustic Delight module would be the fix for
  what remains; low value against the churn, and revisit if anyone asks.
- Kaleidoscope's cooked eggs stay out of `c:eggs`, which is the *raw* egg slot in 59 recipes
  across twelve mods — 40 of them outside Kaleidoscope itself, which reads that tag 19 times.
  (Kaleidoscope puts its own fried egg and a turtle egg in there; that is its call, inside its
  own mod.)
- Nothing is written to `c:foods/cooked_eggs`, the plural tag with no readers, or to
  `c:cooking_oil`, which has two readers and already points at Rustic Delight's tag.
- Kaleidoscope's own oil stays out of the other mods' oil tags: against Croptopia's olive oil
  it is 8x cheap, and Rustic Delight's tag floors three times above it.

### Under the hood

- 88 → 106 generated tag files, 16 of them conditional, in 14 pack overlays (8 in 5 overlays
  at 0.7.0). The generator's verdicts went from 11 GATE / 45 EXCLUDE / 7 rescued PASS to
  **42 GATE / 66 EXCLUDE / 11 rescued PASS**. `tools/cost-floors.json` gained 9 judged tags
  (`c:dusts/salt`, `c:foods/cabbage`, `c:foods/leafy_green`, `c:foods/onion`, `c:foods/tomato`,
  `kaleidoscope_cookery:oil`, `rusticdelight:cooking_oil`, `c:fruits/blueberry`,
  `c:blueberries`), 46 cost floors across 37 tags and 55
  item costs — 196 floors and 186 costs in all — every one derived from a jar's own recipes, and
  none removed.
- Two tag files are hand-authored into another mod's namespace —
  `data/kaleidoscope_cookery/tags/item/oil.json` and
  `data/rusticdelight/tags/item/cooking_oil.json` — because those two mods read a tag of their
  own rather than a shared one. Every id in them is optional. The precedent is the Origins
  meat tag Pantrywork has always shipped.
- `c:foods/raw_chicken` and `c:foods/raw_fish` no longer reference the dialect tags directly;
  they point at generated, judged item lists instead, the same treatment `c:drinks/milk` and
  `c:foods/dough` already had. A tag reference cannot subtract members, and both dialects now
  hold cuts below those tags' floors. Membership was diffed item by item: pufferfish and every
  other fish still arrive, through NeoForge's own definition and the two dialect references
  that stayed.
- **The seed rule gained a third signal, and it caught two items that would otherwise have
  shipped as corn.** Cultural Delights' and Hearth and Harvest's corn kernels are planting
  seeds: each sits in its own mod's `c:seeds` and `c:seeds/corn` (Hearth and Harvest's also in
  `minecraft:villager_plantable_seeds`) and in none of its own mod's food tags, while those
  mods' own corn tags hold a corn cob and an ear of corn instead. Neither name matched the two
  older rules, so both were reaching seven corn and grain tags through Croptopia's `c:corn`,
  and from there `c:foods/vegetable`, canonical `c:foods` and the garnish role. The new rule:
  an item that its **own** mod files in a planting tag (`c:seeds`, a `c:seeds/<crop>` leaf or
  `minecraft:villager_plantable_seeds`) and in none of its own mod's food tags is a planting
  seed. Authority rests with the mod that owns the item, so a third mod listing someone else's
  item can neither condemn nor rescue it. Two `c:` tags are deliberately **not** food evidence:
  bare `c:crops`, which is a mixed plantable-crop bag (Bountiful Fares files six seeds in its
  own, beside its maize), and `c:animal_foods`, which is feed — Hearth and Harvest's is corn,
  corn kernels and universal feed, and without that exclusion the fix would not have worked.
  Every plantable *food* still bridges, saved by the same rule out of its own mod's files:
  Farm & Charm's onion, Farmer's Delight's and Kaleidoscope's rice, Hearth and Harvest's
  grapes and peanut, Rustic Delight's coffee beans.
  Worth saying rather than implying: **the cost floor would not have caught this alone.**
  Hearth and Harvest's kernels are half a corn, which fails the floor at 2x, and they had no
  cost row at all until now; Cultural Delights' are two thirds of a corn, which is exactly
  1.5x and passes. For those, the seed rule is the only guard. And it mattered rather than
  being cosmetic: Cultural Delights' cutting recipe takes one corn out of that tag and returns
  kernels, so kernels inside it were an item-duplication loop on a cutting board; its crate
  recipe upgraded nine kernels into nine whole corn cobs; and kernels satisfied food recipes.
  Both kernels do **remain** in Croptopia's own `c:corn` and `c:grain`, because Croptopia's tag
  references the seed tag and a datapack cannot subtract a member — the audit reports that as
  upstream, and no Pantrywork path reaches it. The generator now prints a per-category
  "dropped seeds" line, which is how two seeds got in with nobody reading a line about them.
- **`create:chocolate_glazed_berries` is out of Croptopia's fruit tag**, for consistency with
  its sibling `create:honeyed_apple`: a candied treat has no business in another mod's
  raw-fruit ingredient slot. It does still appear in the garnish role, through Create's own
  berry tag — Create's classification of its own item, which is not ours to overrule — and the
  test suite asserts that openly rather than leaving it to be discovered.
- **`biomeswevegone:soul_fruit` is out of the fruit tags**, on the same reasoning and for a
  reason the cost check cannot see: it is a blindness food. By price it is a gathered drop, so
  it costs exactly the 1 produce the fruit floor wants and passes at 1.00x. The denylist is
  what keeps it out, exactly as it does for vanilla's golden apple and Create's honeyed apple.
  Bridges widen ingredient pools; they do not re-litigate another mod's own exclusions, and no
  other mod put a debuff food in its fruit slots. It stays in BYG's own `c:foods/fruit`, which
  is BYG's call and unreachable by any datapack, and BYG's own blueberry and green-apple pies
  name their fruit by id, so nothing of BYG's own behaves differently either way.
- `AuditRoles.ps1` and the generator now resolve the NeoForge platform jar from
  `gradle.properties` instead of guessing; they had been reading two different builds. No
  generated output changed.
- Verified on the NeoForge 1.21.1 dev server with every supported mod (15 suites, including a
  new 160-check suite for the five new mods), with Farm & Charm removed, with no food mods,
  and with 7 GameTests. The release jars were booted on dedicated servers 22 times: NeoForge
  1.21.1 alone and in eleven mod combinations that switch the conditions above on and off,
  NeoForge 26.1.2 and 26.2, and Fabric 1.21.1, 1.21.10, 1.21.11, 26.1.2 and 26.2 — plus one
  boot proving a Fabric install without Fabric API refuses to start and says why.
- **Four of those conditions are proven on the dev boot only**, and that is worth stating
  rather than glossing. No dedicated-server scenario carries Bountiful Fares, so the Bountiful
  Fares half of the two `c:flour` conditions is exercised only there; no release scenario loads
  Create and Pam's together, so the Create condition is proven *open* only there; Hybrid
  Delights' three salt bridges are dev-boot-only too (its jar needs HAPI and Kotlin for Forge,
  and its salt item exists only alongside Hybrid Aquatic); and Cultural Delights cannot boot on
  the dedicated 1.21.1 test server at all, because it requires NeoForge 21.1.247 and that
  server deliberately stays on 21.1.241 — so Cultural Delights' half of the cabbage-leaf
  condition and its four cuts are dev-boot proofs, with Rustic Delight standing in for it on
  the release matrix.

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
    Croptopia's and Pam's equivalents, and its cheeses
    and buffalo meat feed the role tags.
    *Corrected 2026-10-07: this said "Croptopia's, Pam's, and Farmer's
    Delight's equivalents". Farmer's Delight ships neither cheese nor salt —
    re-checked item by item against `FarmersDelight-1.21.1-1.3.2.jar`, whose
    only cheese-ish entry is `sweet_berry_cheesecake` and which has no salt at
    all. The bridge itself was never wrong; the sentence was.*
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
