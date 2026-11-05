# Pantrywork on Forge 1.20.1 — measurement and design

**Status: GREENLIT 2026-11-04 by SapperSquad, after the measurement below disproved the reason
the port had been refused since 2026-08-29.** Ships as a fifth file on the existing Modrinth /
CurseForge pages (`0.10.0+mc1.20.1-forge`), alongside the four 0.9.0 files — SapperSquad's call.

## Why the old refusal was wrong

`PUBLISHING.md` carried a paste-ready answer saying a 1.20.1 build was impossible because
"1.20.1 has no food tags to extend — the documented `forge:` crop set is beetroot, carrot,
nether_wart, potato, wheat". That is the crop set the **platform** documents. It is not what the
**food mods** ship. The mods extended `forge:` themselves on 1.20.1, exactly as they later
extended `c:`.

The old answer even flagged its own gap ("nobody has proven that *no* 1.20.1 Forge mod reads `c:`
tags") and that gap is precisely where it was wrong. The project's standing rule — **measure the
jars, do not quote the docs** — would have caught it. It is the one claim that never got measured.

Proof, from the mod that defines the convention everything else follows:

| Farmer's Delight branch | tag class | namespace |
|---|---|---|
| `1.20` | `ForgeTags.java` (+ `CommonTags.java`) | **`forge`** |
| `1.21` | `ForgeTags.java` **deleted**; `CommonTags.java` | **`c`** |

FD 1.20 declares **64** `forge:` tags, including `forge:crops/{cabbage,onion,rice,tomato}`,
`forge:vegetables/*`, `forge:milk`, `forge:milk/milk_bottle`, `forge:dough`, `forge:pasta`,
`forge:grain`, `forge:raw_fishes/*`, `forge:cooked_fishes/*`, the four raw and four cooked meats,
`forge:eggs`, `forge:berries`, `forge:bread`, `forge:salad_ingredients`. That is the same
two-level `<family>` + `<family>/<leaf>` shape Pantrywork bridges today.

**So 1.20.1 is a port, not an invention.**

## The measurement (19 jars, `tools/work/jars-1201`)

Downloaded 2026-11-04 from Modrinth. Scanned as data only.

| Measure | Result |
|---|---|
| `forge:` item-tag files | **957** |
| `c:` item-tag files | 58 — almost all Let's Do (F&C 35, Meadow 13, Vinery 6) + FoT 4, which dual-publish |
| Distinct **food** tag paths under `forge:` | **336** |
| Distinct food tag paths under `c:` | 32 |
| Path form | `data/<ns>/tags/items/` (**plural**) — all 1541 files |

Per-jar `forge:` tag counts worth knowing: Pam's Food Extended **393**, Pam's Food Core **196**,
Hearth and Harvest 88, Farmer's Delight 67, Create 42, Rustic Delight 38, Farm & Charm 35,
Kaleidoscope Cookery 34, Aquaculture 18, Meadow 15.

Pam's speaks the **same concatenated dialect** under `forge:` that it speaks under `c:` on 1.21 —
`forge:cheese/cheese`, `forge:cheese/silkentofu`, `forge:milk/freshmilk`, `forge:berries/*`,
`forge:citrusfruits/lemon`. Farm & Charm dual-publishes its underscored dialect into both
namespaces. So the dialect map transfers nearly 1:1.

## The job exists on 1.20.1 — same collisions

| Family | Shared-namespace spellings | Cross-refs between them |
|---|---|---|
| cheese | 7 | **2** |
| milk | 7 | 5 |
| onion | 4 | **0** |
| tomato | 8 | (FD-only `forge:vegetables/tomato`) |

- **Hearth and Harvest files its cheese in `forge:foods/cheese`, which nothing references.** Its
  cheese slices are invisible to Pam's and Meadow's cheese recipes. This is the canonical
  Pantrywork fix.
- `forge:vegetables/onion` is Farmer's Delight-only; Farm & Charm's onion reaches
  `forge:crops/onion` but not the vegetable family.
- **`forge:cheese/silkentofu` and `forge:butter/silkentofu` exist on 1.20.1**, so the tofu-as-dairy
  cost-floor hazard — the one 0.9.0 just fixed on the fish side — is present here too, and the
  existing judgments in `tools/cost-floors.json` largely carry over.

## Design

Mirror the 1.21 payload, changing exactly three things:

1. **Namespace** `c:` → `forge:` for the identity layer. Canonical becomes **`forge:foods/*`**,
   which is not invented: Hearth and Harvest already uses `forge:foods/cheese`.
2. **Path** `tags/item/` → `tags/items/` (plural). This is a silent killer in both directions —
   a plural path on 1.21 is dead, a singular path on 1.20.1 is dead.
3. **Role layer** keeps its own namespace (`pantrywork:food_component/*`) unchanged — it is ours,
   so it is version-independent.

The generator (`tools/GenerateBridges.ps1`) should take a target-platform switch rather than being
forked, so one source of truth emits both payloads. The cost floors must be **re-derived against
the 1.20.1 recipes**, not copied: the mods are at different versions (FD 1.3.4 not 1.3.2, Pam's
1.0.5/1.0.1, Cultural Delights 0.16.7 not 0.18.1) and the recipe ratios can differ.

## Roster gaps on 1.20.1

- **Croptopia** and **Refurbished Furniture** did not resolve on Modrinth's API (only addons
  surface). Fetch from CurseForge before building — Croptopia matters, it is one of the four
  dialects.
- **Bountiful Fares** is Fabric-only on 1.20.1 (7 versions, 0 forge).
- **Pam's HC2 Crops and Trees have no 1.20.1 build at all** — the two modules 0.9.0 just added are
  1.21-only, so the 1.20.1 roster is smaller than 24.
- Pam's Food Core / Food Extended ship as `1.20.4` files tagged for 1.20–1.20.4, which **includes
  1.20.1**. Those are the right jars.

## Open before the first build

- Fetch the two missing jars, then re-run the scan so the dialect map is complete.
- Decide the canonical set: mirror all of `c:foods/*`, or only the families the 1.20.1 roster
  actually populates.
- A 1.20.1 Forge test harness (the existing ones are 1.21.1 NeoForge, 26.x and Fabric).
