# Changelog

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
  Farmer's Delight Refabricated + Croptopia Fabric.
- All data entries for other mods are optional — any subset of supported
  mods works.
