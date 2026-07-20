# FoodTags — Project Handoff

> **BRANDING DECIDED 2026-07-19: the project is now “Pantrywork”**
> (mod id `pantrywork`) — this doc keeps the FoodTags working name as
> history; everything live uses Pantrywork.

> **STATUS UPDATE 2026-07-19 (later the same day):** v1 core is BUILT and
> LIVE-VERIFIED. Project scaffolded (NeoForge 21.1.241, not 21.1.72 —
> newer floor required by FD 1.3.2), tag data written, and all test
> suites green on a headless RCON dev server with Farmer's Delight +
> Croptopia + Pam's HC2 Food Core loaded: identity bridges, role tags,
> boot matrix (with/without mods), and cross-mod recipe resolution
> (vanilla+FD+Croptopia ingredients in one craft). Key design revision
> discovered during build: the big mods already ship `c:` tags in three
> incompatible dialects, so FoodTags is a *dialect bridge*, not a
> from-scratch taxonomy — see `docs/TAXONOMY.md`. Resume via `CLAUDE.md`;
> §4–6 below are superseded by TAXONOMY.md but kept for history.

A cross-mod food interoperability layer for Minecraft — the "ore dictionary"
that food mods never got. This doc is a kickoff/design snapshot for
starting the project in a new session: no code exists yet, this is the
spec to build from. Working name `FoodTags`; rename freely once you land on
branding (matches the SapperSquad pattern of Forgework/Gunsmith/PhytoForge/
Workstead/ReelRivals — pick something in that vein if you want, e.g.
something pantry/dictionary-flavored).

---

## 1. One-liner

Farmer's Delight, Pam's HarvestCraft 2, Croptopia, and the whole Delight-addon
swarm don't conflict with each other, but they also don't *interoperate* —
none of their cheese, bread, or raw meat can substitute for another mod's
equivalent in a recipe. This project adds a shared tag taxonomy (plus
per-mod compat datapacks) so any food mod's ingredients become
interchangeable in recipes, present and future, without needing the
original mod authors to do anything.

---

## 2. Why (evidence)

From food-mod market research done 2026-07-19
(`%USERPROFILE%\Documents\food-mod-research-2026-07.md` — full doc, keep
for reference) plus a live Reddit deep-dive the same day:

- A food-mod dev confirmed directly in a Reddit thread that food mods
  "don't conflict, at least" but there's no compat layer between them —
  unlike ores/ingots, which already share the `c:` common-tag namespace
  across NeoForge and Fabric. ([Flavored mod launch thread](https://www.reddit.com/r/feedthebeast/comments/1u11coz/my_food_mod_flavored_is_finally_out_for_neoforge/),
  1mo old, 254 votes/40 comments — see `Phantom_thief_france`'s comment)
- Modrinth probe (2026-07-19) found effectively zero existing coverage:
  queries for "food tags api," "common tags food," "food ingredient tag,"
  "culinary tags" all returned 0-1 hits, and the one hit
  (`CoreExtensions-Food-API`) has 0 downloads and isn't this.
- 33 of Modrinth's top-100 food mods are Farmer's Delight ecosystem
  members — the market has calcified around FD, and new standalone food
  mods get dismissed as "just a Farmer's Delight clone" on launch (see the
  Flavored thread again). A compat/interop layer sidesteps that entirely:
  it doesn't compete with FD for content, it makes *every* installed food
  mod (including FD) more valuable together.
- Confirmed mechanism already exists and is proven at scale: NeoForge and
  Fabric unified on a shared `c:` ("common") tag namespace post-1.20.5
  specifically so recipes can target `c:ingots/iron` instead of a
  mod-specific item. Food has never gotten the same treatment. (See
  [NeoForged tags docs](https://docs.neoforged.net/docs/1.21.1/resources/server/tags/)
  and the [NeoForge/Fabric tag-unification PR](https://github.com/neoforged/NeoForge/pull/135).)

---

## 3. Tech stack (proposed — confirm at project start)

| | |
|---|---|
| Minecraft | 1.21.1 (see §3.1 for reasoning) |
| Modloader | NeoForge, matching [[phytoforge-project]]/[[forgework-project]]/[[gunsmith-project]] dev environment |
| Java | 21 (same pin as PhytoForge — see its `CLAUDE.md`) |
| Build | Gradle (NeoGradle/`net.neoforged.moddev`) |
| Mod ID | `foodtags` (placeholder, pick alongside real project name) |
| Package root | `com.foodtags` (placeholder) |

### 3.1 Version/loader decision

Two research findings pull in the same direction: (1) food is the
worst-maintained category on the newer 26.x versions (10% of food mods
updated), so the mods this project needs to support — FD, Pam's
HarvestCraft 2, Croptopia, the Delight swarm, Let's Do series — mostly
still live on **1.21.1**; (2) 1.21.1 is separately confirmed as the
largest actively-maintained mod catalog overall. Target 1.21.1 NeoForge
first to match both the install base and your existing dev setup.

**Multi-loader is cheaper than usual for this project specifically** —
because the deliverable is mostly JSON tag data plus light conditional
loading, not gameplay code, a Fabric build later reuses almost all of the
data files (`c:` tags are already loader-shared by convention). Worth
revisiting once v1 proves out on NeoForge.

---

## 4. Core design: two independent tag axes

This is the actual design insight, not just "add tags to things."

**Axis 1 — Identity tags**: what the item *is*. Lets a recipe accept "any
cheese" instead of hardcoding Farmer's Delight's cheese specifically.

```
c:cheese
c:dough
c:flour
c:raw_meat/beef
c:raw_meat/pork
c:raw_meat/poultry
c:raw_meat/generic        (catch-all for anything not more specifically tagged)
c:cooked_meat/generic
c:fruit/citrus
c:fruit/berry
c:fruit/generic
c:vegetable/root
c:vegetable/leafy
c:vegetable/gourd
c:dairy/milk
c:dairy/cream
c:dairy/butter
c:sweetener
c:spice
c:herb
```

**Axis 2 — Role tags**: what the item *does* in a dish. This is the
higher-leverage axis — it lets someone author one generic recipe that
pulls from any compatible item across every installed mod, forever,
without ever touching that recipe again when a new food mod ships.

```
c:food_component/protein
c:food_component/starch
c:food_component/dairy
c:food_component/garnish
c:food_component/liquid_base
c:food_component/sweetener
```

Both axes coexist on the same item — Farmer's Delight's bacon would carry
both `c:cooked_meat/generic` (identity) and `c:food_component/protein`
(role).

**Payoff example**: a "Universal Sandwich" recipe defined once as
`bread + #c:food_component/protein + #c:food_component/dairy` automatically
accepts Farmer's Delight's bread and bacon, Pam's cheese, and a Let's Do
Bakery topping — no per-mod compat entry, and it keeps working when a new
food mod ships next month and tags its items against this convention.

---

## 5. Architecture

- **Per-mod compat modules, not one monolith.** Each supported mod gets
  its own small datapack of tag assignments, loaded only if that mod is
  present. NeoForge and Fabric both support mod-presence-gated data
  loading (conditional recipes/tags) — use that instead of a hard
  dependency, so FoodTags works whether the player has one supported mod
  or all of them.
- **Scripted tag assignment via KubeJS**, not hand-tagging thousands of
  items one at a time. Loop over each target mod's registered items,
  match on naming/registry patterns (e.g. anything under
  `farmersdelight:` ending in `_cheese`), bulk-assign tags. Faster to
  write, faster to extend when a mod updates its item list.
- **No upstream cooperation required for v1.** Tags are additive, same as
  the old ore dictionary — you can tag Pam's HarvestCraft 2's cheese
  without Pam's HarvestCraft 2's author doing anything. That's why this
  is buildable solo and cheaply. Longer-term, if the taxonomy proves
  useful, getting other food-mod authors to tag their *own* new items
  against `c:food_component/*` directly (the way `c:` itself got adopted)
  is the real win condition — but that's a stretch goal, not a blocker.

---

## 6. Target mods for v1 compat modules (priority order)

Based on the download/relevance data in the market research doc:

1. **Farmer's Delight** (+ Refabricated) — the ecosystem hub; get this
   right first since every other mod's players likely also have this.
2. **Pam's HarvestCraft 2 — Food Core** — biggest "quantity" mod, huge
   item surface, good stress test for the naming-pattern scripting
   approach.
3. **Croptopia** — 250+ foods, similar shape to Pam's.
4. **The Delight-addon swarm** (Nether's/End's/Ocean's/Ender's/Chef's
   Delight, Delightful, Farmer's Respite) — these already assume FD is
   present, so tagging them is mostly free once FD's compat module
   exists.
5. **The [Let's Do] series** (Vinery, Bakery, Farm & Charm, HerbalBrews) —
   lower priority; more special-purpose items (wine, tea) that don't map
   as cleanly onto the protein/starch/dairy role axis. Worth doing but
   not blocking v1.

---

## 7. Explicitly out of scope for v1

A deeper **shared food-mechanics API** (nutrition/saturation value
unification, so a downstream mod could reason generically about "anything
tagged spicy" or "anything role-tagged protein has X saturation") is a
separate, larger project — closer to what AppleCore used to provide before
it went dead in 2020. That's a natural sequel once the tag layer proves
out and something needs to build mechanics (e.g. a "Cravings" rotating
desired-food mod, also identified in the research doc) across the whole
ecosystem rather than just one mod's own content. Don't scope-creep v1
into it.

---

## 8. Open decisions for the next session

- Final mod ID / package name / project branding.
- Confirm NeoForge 1.21.1 vs. also targeting 26.x day one (leaning
  1.21.1-first per §3.1, but worth a quick re-check of current mod
  update activity before committing).
- Whether to ship as a pure datapack (zero Java, just JSON tag files +
  KubeJS scripts) vs. a proper mod with a `CommonTags` Java API other
  modders can compile against. Pure datapack is faster to ship and
  publish; a real API mod is more durable and matches the ore-dictionary
  analogy more closely (third-party mods could soft-depend on it). Could
  do datapack-only for v1 and promote to a real API mod once there's
  proven demand.
- Whether the role-axis tag names (`c:food_component/*`) should instead
  live under a project-specific namespace (e.g. `foodtags:component/*`)
  until/unless the convention gets broader adoption, vs. going straight
  for `c:` and hoping it gets picked up the way ingot tags did.

---

## 9. Sources

- Full market research: `%USERPROFILE%\Documents\food-mod-research-2026-07.md`
- [Flavored mod launch thread](https://www.reddit.com/r/feedthebeast/comments/1u11coz/my_food_mod_flavored_is_finally_out_for_neoforge/) — confirms no existing compat layer
- [NeoForged Tags docs](https://docs.neoforged.net/docs/1.21.1/resources/server/tags/)
- [NeoForge/Fabric common-tag unification PR](https://github.com/neoforged/NeoForge/pull/135)
- [Fabric API mirror PR](https://github.com/FabricMC/fabric-api/pull/3310)
