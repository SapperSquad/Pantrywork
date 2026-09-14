**0.7.0 - Four more mods, cooked eggs, and swaps that have to be fair.**

**New: Create, Bountiful Fares, Fish of Thieves and Refurbished Furniture**, all from player feedback.
- **Create:** its dough and wheat flour work in Pam's recipes. In Croptopia's recipes the dough needs Farm & Charm installed, and the flour needs Bountiful Fares, Farm & Charm or Pam's.
- **Refurbished Furniture:** its cheese, wheat flour, sea salt and dough carried no tags at all. They now work wherever another mod asks for cheese, flour, salt or dough.
- **Bountiful Fares:** maize counts as corn for Croptopia and Farm & Charm. Its oranges, lemons, plums, elderberries and walnuts work in Croptopia's recipes for those, and the other mods' versions work in Bountiful Fares' recipes.
- **Fish of Thieves:** its fruit now joins the shared fruit pool, and banana, coconut, mango and pineapple work in Croptopia's recipes for those fruits. Its raw fish work in Pam's and Farm & Charm's fish recipes.

**New: cooked eggs.** Pam's fried egg, Bountiful Fares' cooked egg and Croptopia's sunny-side eggs work in Farmer's Delight's egg sandwich and bacon and eggs. Each costs one egg, the same as FD's fried egg.

**New:** Brewin' & Chewin' sweet berry jam, glow berry marmalade and apple jelly fill Pam's matching jelly slots. The shared flour, corn, salt and vegetable tags now also hold the mods that were missing from them (for example, Create's wheat flour now reaches the shared flour tag without Farm & Charm, as long as Pam's or Bountiful Fares is installed).

**Fixed (these shipped in 0.6.0 or earlier):**
- **Cheap milk in bucket recipes.** Croptopia's milk bottle (16 per bucket) and soy milk were accepted by recipes written for a full milk bucket, and Farmer's Delight's cake, pie crust, hot cocoa and custard also took Pam's fresh milk. Both are fixed; the one exception, Farmer's Delight's bottle in bucket recipes while Pam's is installed, is listed below.
- **Blocks in food tags.** The melon and pumpkin blocks sat in the fruit and vegetable tags, and Brewin' & Chewin's cheese wheels (placeable blocks, not food) in every cheese tag. All removed; melon slices and B&C cheese wedges stay.
- **Bridges that quietly needed a third mod.** Croptopia dough only worked in Pam's recipes when Farm & Charm was installed. It now works without it. The same fix means that without Pam's, Croptopia's any-fruit recipes also accept vanilla chorus fruit, glow berries and sweet berries, and on Minecraft 26.x its vegetable recipe accepts carrots, potatoes and beetroot.
- **Largemouth Bass** went missing from the fish bridges in 0.6.0. It's back.

**How swaps are judged now.** Every item Pantrywork adds to a tag that a recipe reads may be at most 1.5x cheaper than the cheapest item each mod that defines that tag lists there itself. Cost means the cheapest way to make it with its own mod: milk in buckets, meat and fish in whole animals, and so on. If it is cheaper than that for one mod, but another mod that defines the tag already accepts something as cheap, the swap is kept only while that other mod is installed. This covers what Pantrywork adds, not what each mod puts in its own tags, and the role tags (`pantrywork:food_component/*`) have no price floor. **On Fabric, Fabric API is required:** without it Fabric Loader refuses to start and names the missing dependency.

**Out entirely, compared with 0.6.0:**
- **Milk and cheese:** Croptopia's milk bottle and soy milk in bucket-milk recipes and in Farmer's Delight's cake, pie crust, hot cocoa and custard; Pam's fresh milk in those FD recipes; Farmer's Delight's milk bottle in the old `c:foods/milk` tag (Bountiful Fares' cocoa cake and its version of the vanilla cake now need a bucket or BF's own coconut milk); Croptopia's cheese and butter in Pam's, Meadow and Farm & Charm cheese and butter slots.
- **Half-portion cuts as a whole animal** in Pam's and Farm & Charm's meat and fish recipes: Farmer's Delight bacon and cooked bacon, minced beef, chicken cuts, mutton chops and raw cod and salmon slices; Farm & Charm bacon, chicken parts and bacon and eggs; Ocean's Delight fugu and elder guardian slices.
- **In Farmer's Delight's own slots:** Farm & Charm's dough, pasta, farmer's bread and roasted chicken, Pam's pasta, Meadow's cooked buffalo meat, and Ocean's Delight's fugu and elder guardian slices.
- **Everything else:** Pam's toast in Croptopia recipes; Pam's cooking oil as olive oil; Croptopia's apple and melon juice in Pam's apple and melon juice recipes (one apple or one melon slice against Pam's two); Croptopia's ground pork in Pam's ground pork and meatloaf recipes (Croptopia can press it from tofu; it still counts as meat for Origins); Farmer's Delight's cabbage leaf as a whole vegetable (`c:foods/vegetable`).

**Now only while another mod is installed:**
- Farmer's Delight's milk bottle in Farm & Charm's and Meadow's bucket-milk recipes: while Pam's is installed.
- Farmer's Delight's milk bottle and Pam's fresh milk in Meadow's plural milk recipes: while Croptopia is installed (they always work in Croptopia's own recipes). Pam's cheese in the plural cheese tag is conditional on Croptopia too, but only Croptopia's recipes read that tag, so nothing changes in play.
- Farmer's Delight's and Pam's dough in Croptopia's dough recipes: while Farm & Charm is installed.
- Pam's dough in Farmer's Delight's dough recipes: while Create is installed.
- New in 0.7.0: Create's dough in Croptopia's dough recipes (while Farm & Charm is installed) and Create's flour in Croptopia's flour recipes (while Bountiful Fares or Pam's is installed; with Farm & Charm it already worked in 0.6.0).
- Croptopia Refabricated counts as Croptopia. On Minecraft 26.x, Farm & Charm, Pam's, Create and Bountiful Fares have no builds, so Farmer's Delight's dough no longer works in Croptopia's dough recipes there.

**Deliberately not bridged:** Refurbished Furniture's toast and jams. One loaf makes six Refurbished toast and its jam is one berry with no sugar, so they would undercut other mods' recipes. Bountiful Fares' "Coconut" is the palm tree's planting item, not food.

**Needs a change in those mods:** Refurbished Furniture's own recipes ask for its exact items, so other mods' food can't work inside them. Bountiful Fares' coconut-halving recipe asks for its own coconut.
