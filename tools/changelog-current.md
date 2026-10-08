**0.8.0 - Six more mods, and the wok finally lights.**

**New: Kaleidoscope Cookery, Hearth and Harvest, Cultural Delights (+ Cook's Collection), Rustic Delight and Hybrid Delights**, all five from one player report. All five are Farmer's Delight addons on NeoForge 1.21.1; Rustic Delight and Hybrid Delights also ship for Fabric 1.21.x (and Rustic Delight for Fabric 26.x), so their bridges are live on the Fabric files too - though no Fabric test harness carries any of the five, so the Fabric side is proven by the data and the NeoForge boots rather than by a Fabric boot.

**The headline: the wok takes other mods' oil.** Kaleidoscope Cookery's pot has to be primed with cooking oil before it cooks anything, and its code decides what counts by reading a tag rather than its own item id. Pantrywork now writes that tag, so Hearth and Harvest, Cook's Collection and Rustic Delight cooking oil, Croptopia olive oil and Pam's cooking oil all prime it. That is the gate in front of **all 225 of the wok's recipes**.

**And a sixth mod: Oh The Biomes We've Gone.** From a later report in the same thread - "blueberries from Biomes You'll Go are incompatible with any other modded blueberry". That is exactly right, and the reason is that BYG files its blueberries in its own berry tag and in no blueberry tag at all. Pantrywork now puts them in the shared blueberry tag, which **Hearth and Harvest's five blueberry recipes read** (muffin, pie, jam, juice, crate) and which Croptopia's own blueberry tag references, so **Croptopia's three read it too** (jam, seed, scones). Eight recipes, from one missing tag entry. BYG's other three fruits - green apple, baobab fruit and yucca fruit - join the fruit tag in the same pass.

Two honest notes on it. The *reverse* is not possible: BYG's own blueberry pie names its berry by exact item id, so no datapack can let a Croptopia or Hearth and Harvest berry bake it - only BYG's author can. And **soul fruit is deliberately left out.** BYG files it as a fruit beside the other three, but eating it inflicts blindness, and the fair-swap check measures crafting effort, not what a food does to you. It stays out of the fruit tags, exactly like vanilla's golden apple and Create's honeyed apple. It remains in BYG's own fruit tag, because no datapack can remove a member - that is BYG's call to make, not ours.

**Also new:**
- **Kaleidoscope's fried egg is a cooked egg again.** It was filed under a plural tag name nothing reads. It now joins the real cooked-egg tag, so Farmer's Delight's egg sandwich and bacon and eggs, and Cultural Delights' four egg recipes, accept it.
- **Kaleidoscope's dough** works in Croptopia's 13 dough recipes (while Farm & Charm is installed) and in Farmer's Delight's dough tag, which 11 recipes across seven mods read.
- **Hybrid Delights' salt** carried no tags at all. It now works in 75 recipes (Pam's 17, Croptopia 45, Meadow 13).
- **A fifth salt spelling bridged.** Hearth and Harvest, Cultural Delights and Cook's Collection share a salt tag the older mods never heard of, read by 36 recipes. Hybrid Delights', Meadow's and Refurbished Furniture's salt now reach it; Croptopia's and Pam's reach it while Hearth and Harvest is installed.
- **Oils reach the other mods' oil slots.** Hearth and Harvest, Rustic Delight and Cook's Collection oil work in Pam's 16 cooking-oil recipes; Cook's Collection oil also in Croptopia's 25 olive-oil recipes; and Croptopia, Cook's Collection, Hearth and Harvest and Pam's oil in Rustic Delight's own oil tag (10 recipes).
- **Butter.** Hearth and Harvest's and Cultural Delights' butter join Croptopia's butter tag (15 recipes). This is *not* the fix for "Hearth and Harvest butter and Cultural Delights butter are not interchangeable" - see below.

**Fixed: gaps nobody reported.**
- **Cabbage and leafy greens never met.** Croptopia cabbage and Farm & Charm lettuce were invisible to 22 recipes across Farmer's Delight, Cultural Delights, Rustic Delight, Brewin' & Chewin' and Ocean's Delight. Both now reach both tags.
- **Onion and tomato.** Croptopia's and Farm & Charm's onion and tomato, and Kaleidoscope's tomato, now reach the 10 recipes that read those tags. Two of them are Farmer's Delight recipes that Rustic Delight narrows when installed - fried rice and baked cod stew work again.
- **Rustic Delight's nine whole bell peppers** join the vegetable tags, read by 23 recipes. Cultural Delights' vegetables ride in with them.

**How swaps are judged.** Unchanged: an item Pantrywork adds to a tag a recipe reads may be at most 1.5x cheaper than the cheapest thing each mod defining that tag already lists there. If only some of those mods accept something that cheap, the swap is kept only while one of them is installed. 0.8.0 settled two conventions: a planting seed costs its share of the produce it is made from (one pumpkin makes four seeds), and a route that starts at a mob drop is not a cheaper route - cost measures processing effort, not scarcity. Note: Rustic Delight's oil recipe, nine of the ten recipes reading its oil tag, and its slice recipes sit behind its own config flags (on by default), which the cost model has no concept of. **On Fabric, Fabric API is required:** without it Fabric Loader refuses to start and names the missing dependency.

**What changed, compared with 0.7.0. Nothing was removed** - no item left a tag in this release.

*Now conditional where they were not:*
- Farm & Charm's chicken parts in the raw-chicken tag: while Farmer's Delight is installed. Kaleidoscope Cookery also defines that tag and lists a whole chicken, so a third of a chicken is 3x below its floor; Farmer's Delight's own half-chicken cut is what rescues it.
- Kaleidoscope's sashimi in the raw-fish tag: while Farmer's Delight or Rustic Delight is installed (a third of a fish, against whole-fish floors).

*Easier to satisfy than before (strictly more installs get the swap):*
- Create's wheat flour in Croptopia's flour recipes: was Bountiful Fares, Farm & Charm or Pam's; now also Kaleidoscope Cookery.
- Pam's salt in the plural salt tag: was Croptopia; now Cook's Collection or Croptopia.
- Farmer's Delight's cabbage leaf in the vegetables tag: was Croptopia; now Croptopia or Kaleidoscope Cookery.

*Back after 0.7.0 dropped them, conditionally:*
- Farmer's Delight's cabbage leaf as a whole vegetable, while Cultural Delights or Rustic Delight is installed - both define that tag with their own half-vegetable cuts.
- Farmer's Delight's cod and salmon slices in Farm & Charm's fish tag, while Kaleidoscope Cookery is installed, along with Cultural Delights' and Rustic Delight's calamari.

*New and conditional from the start:* Hearth and Harvest's flour and corn meal (Bountiful Fares or Farm & Charm); its salt (Cook's Collection); its goat milk bottle (Pam's, and Croptopia for the plural tag); Croptopia's and Pam's salt in the new shared salt tag (Hearth and Harvest); Cultural Delights' and Kaleidoscope's dough in Croptopia's dough recipes (Farm & Charm); and Cultural Delights' four cuts plus Rustic Delight's nine pepper slices and potato slices in the vegetables tag (Croptopia or Kaleidoscope Cookery). Their whole-vegetable versions are unconditional. Croptopia Refabricated counts as Croptopia; on Fabric the Farmer's Delight conditions open for FD Refabricated. On Minecraft 26.x only Rustic Delight has a build at all, and only on Fabric, so on the 26.x files almost nothing here switches on - an entry for a mod that is not installed is simply inert.

**Proven on the development boot only, not on a dedicated server with the release jar** - said plainly rather than glossed: the Bountiful Fares half of the two flour conditions (no dedicated-server scenario carries Bountiful Fares); the Create condition in its *open* state (no release scenario loads Create and Pam's together); Hybrid Delights' three salt bridges (its jar needs HAPI and Kotlin for Forge, and its salt item exists only alongside Hybrid Aquatic); and Cultural Delights' half of the cabbage-leaf condition plus its four cuts, because Cultural Delights requires NeoForge 21.1.247 while the dedicated 1.21.1 test server deliberately stays on 21.1.241, so Rustic Delight stands in for it there.

**Can't be fixed with tags:**
- **Cultural Delights butter and Hearth and Harvest butter still are not interchangeable.** Both were already in the same tag before this release - that was never the problem. Their own recipes (five each) name the exact butter item instead of a tag, and no tag changes what a recipe asks for. Only those two authors can fix it; the Croptopia butter win above is a separate thing.
- Same for the other recipes in Refurbished Furniture, Hybrid Delights, Cultural Delights and Hearth and Harvest that name exact item ids. Hybrid Delights is the clearest case: its salt now works in 75 other recipes, and nothing else works in its own eleven.
- Kaleidoscope Cookery's Oil Can refill and butter tea bag name its own oil item.

**Bugs found in the other mods** (none of them Pantrywork's to fix, all worth reporting):
- Kaleidoscope Cookery's wok consumes the held item with no container return, so bottled oils lose their glass bottle. Farmer's Delight's own cooking pot does return containers.
- Cook's Collection ships a Brewin' & Chewin' compat recipe naming a Farmer's Delight item id that stopped existing after 1.20. With both mods installed it does not fail silently: the recipe manager logs a parsing error with a stack trace on every load, and the pizza is missing.
- Kaleidoscope Cookery's own tags list its Quark-only furniture as required ids, so a game without Quark logs missing references.

**Deliberately not bridged:** the *reverse* direction for Rustic Delight's fish and cookies. Outward they do travel - its calamari joins the three raw-fish tags, its cooked calamari the two cooked-fish tags and its three cookies the shared cookie tag, so other mods' recipes take them. What is not bridged is the other way round, and no datapack can do it: its own calamari recipes name the item by id or read a squid tag, and its three cookie recipes are crafted from its own flavour tags rather than from a cookie tag. Cooked eggs stay out of the raw-egg tag, which 59 recipes across twelve mods read as a *raw* egg slot (40 of them outside Kaleidoscope itself). Kaleidoscope's own oil stays out of the other mods' oil tags - it is 8x cheaper than Croptopia's olive oil and 3x cheaper than Rustic Delight's.
