# Concoction! — evaluation, 2026-11-03

A player reported that **Concoction!** "has a ton of improperly tagged items and recipe
incompatibilities with other mods." This is what the jar actually says. Nothing here is
implemented; the jar is parked in `tools/work/jars-eval/`, outside every scan path, pending a
decision.

**Jar read:** `concoction-1.6.2-neoforge-1.21.1.jar`, SHA-1
`137c7d8a91aba578b48b45953ed4d75ae6267799`, from the Modrinth CDN (project `Jr4xc872`, version
`EtzHGnlL`). The SHA-1 matches Modrinth's own declared hash. CurseForge project id 1039618.
NeoForge, MC 1.21–1.21.1, no declared dependencies. 140 items, 121 blocks, 295 recipes,
107 tag files.

## The short version

The report is right that something is wrong, but both halves are misdiagnosed, and the two halves
need opposite answers.

| The claim | What the jar shows | Can Pantrywork fix it? |
|---|---|---|
| "improperly tagged items" | Structurally it is *correct* — `data/c/tags/item/` singular, no `replace: true`, and it files into the canonical `c:foods/*` axis, which many food mods never do. The real problem is that it is **absent from the dialect tags other mods read**. | **Yes** — this is exactly what Pantrywork does. |
| "recipe incompatibilities" | Measured: **591 of its ingredient slots name an exact item id** against only 315 tag reads, and 272 of those tag reads are its own pillow/carpet decoration tags. Its *food* recipes are almost entirely hard-coded to specific items. | **Mostly no.** A tag cannot reach a recipe that names an item id. |

There is also one genuine tagging bug that would bite Pantrywork directly, and a handful of
tags that are genuinely wrong but that a data pack structurally cannot repair.

## What Pantrywork could fix (the valuable half)

Concoction files its food into `c:foods/*` and into its own `c:crops/<x>` leaves, but it is
missing from the dialect tags that other mods' recipes actually read:

| Concoction has | It is missing from | Who reads the missing tag |
|---|---|---|
| `c:crops/tomato` | `c:tomatoes` | Croptopia recipes (C1-1) |
| `c:crops/onion` | `c:onions` | Croptopia recipes |
| `c:crops/cabbage` | `c:cabbage` | Croptopia recipes |
| `c:seeds/rice` only | `c:rice` | Croptopia recipes |
| `c:salts` | `c:salt`, `c:dusts/salt` | Cook's Collection, Hybrid Delights |
| `concoction:butters` (private) | `c:butter`, `c:butters` | Farm & Charm, Cultural Delights, Croptopia, Pam's |
| `concoction:oils` (private) | `c:cookingoil`, `kaleidoscope_cookery:oil` | Kaleidoscope Cookery's wok, Pam's |
| `c:bottles` + `c:foods/drink` | `c:milk`, `c:milks`, `c:drinks/milk` | its milk and cream bottles reach no dairy reader |

That is a clean bridge list of roughly ten to fourteen tags, all of them tags Pantrywork already
writes. Its oils are the most interesting: Kaleidoscope Cookery's wok will not cook until it is
primed with something in `#kaleidoscope_cookery:oil`, and Pantrywork already writes that tag.

Concoction's own recipes read 20 food-tag slots Pantrywork can feed — `c:salts` (11),
`c:foods/raw_meat` (5), `c:mushrooms` (3), `c:foods/raw_fish` (1). Small, but real.

## The one genuine bug — `concoction:rice`

`concoction:rice` is filed in `c:seeds` and `c:seeds/rice` and **in no Concoction food tag**,
while `concoction:cooked_rice` sits in `c:foods` and `c:foods/dish`. So the raw rice — which is
both the planted item and the cooking ingredient — is declared as a seed and nothing else.

This matters to us specifically. `Test-IsSeed`'s third rule drops an item that its own mod files
in a planting tag and in none of its own mod's food tags. Verified against the real predicates in
`tools/CostFloor.ps1`, **`concoction:rice` is the only one of its nine planting-tag items that
the rule would get wrong**; the other eight (`cabbage_seeds`, `corn_seeds`, `mint_seeds`,
`puffball_spores`, `reapper_seeds`, `spicy_pepper_seeds`, `sunflower_seeds`, `tomato_seeds`) are
genuinely seeds and are correctly dropped.

This is the mirror image of the 0.8.0 corn-kernel blocker: there the third rule saved us from
shipping two seeds as food, here it would cost us a real ingredient. **Do not change the rule** —
loosening it re-admits `culturaldelights:corn_kernels` and `hearthandharvest:corn_kernels`. If
Concoction is bridged, `concoction:rice` needs a hand judgment entry, recorded with this reason.

## What Pantrywork cannot fix, and must not claim to

A data pack can add tag members; it can never remove them. These are genuinely wrong and are
upstream's to fix:

- **`c:bowls` holds `concoction:boiled_noodles` and `concoction:cooked_rice`** — cooked food in a
  container tag. Anything reading `c:bowls` expecting empty bowls gets food.
- **`c:tableware` holds `minecraft:stick`.**
- **`c:bottles` holds `minecraft:experience_bottle` and `minecraft:ominous_bottle`.**
- **`concoction:dough` and `concoction:raw_noodles` are in canonical `c:foods`** (and in
  `c:foods/food_poisoning`) — raw intermediates presented as food.

Pantrywork reports this class as `upstream` and never fails the build on it, per its own rule
that re-classifying another mod's choices is out of bounds. The honest answer to the player on
this half is "report it to Concoction," not "Pantrywork will fix it."

## Recommendation

Worth bridging, with the scope stated honestly: Pantrywork can connect Concoction's produce,
salt, butter, oils and dairy to the rest of the pack, and can feed 20 of its own recipe slots.
It cannot make its 591 hard-coded ingredient slots accept other mods' food, and it cannot
un-tag anything. If it goes in, `concoction:rice` needs a judgment entry first.

Not folded into 0.9.0: that release is the Pam's work, and adding a fourth mod on a late report
would mean re-deriving floors and re-running the boot matrix for both at once.
