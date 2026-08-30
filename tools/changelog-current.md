**0.5.0 - Two correctness fixes.** No new mods bridged; this one is about the bridges already there being right.

**Fixed: planting seeds are no longer food.** Croptopia files its seeds *inside* its produce tags, so referencing those tags pulled 13 seeds into `c:foods/vegetable` and the `garnish` role - meaning a lettuce seed could satisfy any recipe asking for a garnish. Produce is now enumerated item-by-item with the seeds dropped. Croptopia's vegetables and fruits still bridge exactly as before; only the seeds are gone.

Seeds are identified by the ecosystem's own `c:seeds` classification rather than by name, so plantable *foods* (Farm & Charm's onion) and edible seed foods (Croptopia's roasted pumpkin and sunflower seeds) correctly stay food.

**Fixed: a lone install could refuse to load.** Three references to convention tags (`c:foods/berry`, `c:buckets/milk`) were marked required. On Fabric without Fabric API - a setup the README explicitly invites - those tags are undefined, and a required reference to an undefined tag fails datapack loading outright. They are optional now, as every cross-mod reference should be.

Both fixes are now guarded by a new audit that resolves every tag the mod asserts and fails the build if either problem reappears.
