# Pantrywork

**The ore dictionary that food mods never got.**

Farmer's Delight, Croptopia, Pam's HarvestCraft 2 and Farm & Charm all ship
common (`c:`) item tags, in four naming dialects that never reference each
other. Pantrywork bridges them into the official NeoForge/Farmer's Delight
`c:foods/*` convention and adds a role layer on top, so one mod's cheese,
dough, flour, milk or meat works in another mod's recipes, as long as it
costs about the same.

- **Identity tags** (`c:foods/*`): extends the built-in convention;
  bridges Croptopia's plural dialect (`c:cheeses`), Pam's concatenated
  dialect (`c:rawpork`) and Farm & Charm's underscored dialect
  (`c:raw_pork`) into canonical names (`c:foods/cheese`,
  `c:foods/raw_pork`). Reverse bridges make the mods' own recipes accept
  foreign ingredients too.
- **Role tags** (`pantrywork:food_component/{protein,starch,dairy,garnish,liquid_base,sweetener}`):
  what an ingredient *does* in a dish, defined as tags-of-tags over the
  identity layer. Author one recipe against
  `#pantrywork:food_component/protein` and it accepts vanilla steak, FD
  bacon, and anything future mods tag. Roles have no price floor: `dairy`
  holds milk bottles and plant milk next to buckets. `PantryworkTagKeys`
  ships the constants for compile-time use (NeoForge jar).
- **No food mod required**: every cross-mod reference is optional; works
  with any subset of the supported mods installed, or none.
- **Fair swaps**: an item Pantrywork adds to a recipe tag may be at most
  1.5x cheaper than the cheapest item each mod that defines that tag lists
  there itself. If only some of those mods already accept something that
  cheap, the swap is added only while one of them is installed (conditional
  pack overlays in `pack.mcmeta`). So a 16-per-bucket milk bottle never
  fills a bucket recipe, and a bacon strip never counts as a whole porkchop
  in Pam's recipes. The check covers what Pantrywork adds, not what each mod
  lists in its own tags. Items that would undercut other mods' recipes
  (Refurbished Furniture's toast and jams) stay out on purpose.
  [CHANGELOG.md](CHANGELOG.md) 0.7.0 lists every older swap this removed or
  made conditional, with the reason.

**Both loaders**: NeoForge on 1.21.1 (21.1.241+) and on 26.1–26.2, and
Fabric on 1.21.1–1.21.11 and 26.1–26.2. The Fabric and NeoForge-26 jars are
pure data (no code). On Fabric, Fabric API is required: the Fabric jars
declare it, and without it Fabric Loader refuses to start and names the
missing dependency.

Supported so far: Farmer's Delight (+ Refabricated on Fabric), Croptopia
(+ Croptopia Refabricated on Fabric 1.21.10), Pam's HarvestCraft 2 Food Core,
Ocean's Delight, End's Delight, the **[Let's Do] series** (Vinery, Farm &
Charm, Meadow), **Aquaculture 2**, **Brewin' & Chewin'**, **Create**,
**Bountiful Fares**, **Fish of Thieves**, **Refurbished Furniture**, and
Origins (carnivore/vegetarian diet tags).

Verified live, never inferred: RCON test suites plus 7 GameTests
(`gradlew runGameTestServer`) green on NeoForge 1.21.1 with every compat
mod loaded, and boots with none loaded and with Farm & Charm removed. The
release jars were booted on real servers: NeoForge 1.21.1 (alone, and in
five mod combinations that switch the Pam's, Croptopia, Create and flour
conditions on and off; the Farm & Charm condition was switched on the dev
server, with and without Farm & Charm),
NeoForge 26.1.2 and 26.2, and Fabric 1.21.1, 1.21.10, 1.21.11, 26.1.2 and
26.2. The NeoForge 26.1.2 boots use 26.1.2.94, the exact build All the Mods
11 ships, alongside ATM11's own Croptopia and Aquaculture 2. Highlights:
Pam's grilled-cheese-and-ham crafted with Farm & Charm butter, a Brewin' &
Chewin' cheese wedge and vanilla bread and porkchop (and refused with
Croptopia's cheaper cheese), Farmer's Delight's egg sandwich from Pam's and
Bountiful Fares eggs (NeoForge 1.21.1), Croptopia's pineapple chicken from a
Fish of Thieves pineapple (NeoForge 26.2), and Croptopia's banana smoothie
made with Farmer's Delight milk (Fabric 1.21.1, 1.21.10, 26.1.2 and 26.2, and
NeoForge 1.21.1).

Docs: [docs/TAXONOMY.md](docs/TAXONOMY.md) (tag design and the cost floor) ·
[CLAUDE.md](CLAUDE.md) (build/test harness) ·
[PUBLISHING.md](PUBLISHING.md) (release kit)

Status: live on Modrinth ([`pantrywork`](https://modrinth.com/mod/pantrywork))
and CurseForge. Formerly developed under the working name "FoodTags".

## License

The source code in this repository is MIT-licensed - see [LICENSE](LICENSE).
The brand assets in [promo/](promo/) (banner, icon, gallery art) and the
store-page copy in [PUBLISHING.md](PUBLISHING.md) are (c) SapperSquad, all
rights reserved - see [promo/LICENSE](promo/LICENSE). Store listings on
Modrinth/CurseForge are published All Rights Reserved by policy.
