**0.2.0 - Let's Do series support, Minecraft 26.x, and a wider Fabric range.**

**Let's Do compat (new):** Vinery, Farm & Charm, and Meadow.
- *Meadow*: its cheese and salt recipes now accept Croptopia's, Pam's, and Farmer's Delight's equivalents; its cheeses and buffalo meat feed the role tags.
- *Farm & Charm*: introduced a third meat dialect (flat-underscored `c:raw_pork` vs Pam's `c:rawpork`) - every canonical meat tag now bridges all three, in both directions.
- *Vinery*: ships no common tags at all, so it gets a per-item module - grapes and cherries into `c:foods/fruit`, its juices and cider into `c:drinks`.

**Minecraft 26.x (new):** a Fabric build for 26.x, verified live on 26.1.2 (Farmer's Delight Refabricated + Croptopia 4.3.1, including a cross-mod craft) and on 26.2 (FD Refabricated).

**Fabric 1.21.x now covers 1.21.1 through 1.21.11**, verified live on 1.21.10 and 1.21.11.

**Fix:** seeds no longer cross bridges. Croptopia files its seeds inside its produce tags; without this a seed could have satisfied another mod's food recipe.

NeoForge stays on 1.21.1 - Farmer's Delight, Pam's HarvestCraft 2, and Croptopia's NeoForge builds have nothing newer to bridge yet.
