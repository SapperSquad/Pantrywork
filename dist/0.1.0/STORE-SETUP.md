# Pantrywork 0.1.0 — store setup crib sheet

Everything in this folder is the frozen 0.1.0 release package. When creating
the projects, work through this top to bottom. (Live source of truth for
future releases: ../../PUBLISHING.md.)

## Project creation (Modrinth first)

- Name: **Pantrywork** · suggested slug: `pantrywork`
- Summary (short-description field):
  > The ore dictionary that food mods never got. Bridges Farmer's Delight,
  > Croptopia, and Pam's HarvestCraft 2 into one shared tag vocabulary, so
  > any mod's cheese works in any other's recipe.
- Description body: paste the "Project description" section from
  `../../PUBLISHING.md` (starts at "# One cheese. Every recipe.").
- Categories: `library`, `utility`, `food` (library first — pack makers are
  the audience; food/farming alone buries it)
- License: MIT
- Environment: **Client side: Optional · Server side: Required** — all content
  is tags/recipes, which live on the logical server and auto-sync to joining
  players. Multiplayer: install on the server only, clients need nothing.
  Singleplayer: install like any mod (the integrated server picks it up).
  Never "client required" — that would wrongly tell multiplayer players they
  must install it.
- Loaders: NeoForge + Fabric · Game version: 1.21.1
- Environment/links: source + issues can point at the SapperSquad GitHub
  once the repo is pushed (not created yet — optional for launch)

## Art (this folder, `art/`)

- `icon-512.png` → project icon
- `banner-1920x640.png` → gallery, feature/banner slot
- `gallery-1-one-tag.png` → "Three dialects. One vocabulary."
- `gallery-2-four-mod-craft.png` → "Four mods. One sandwich." (lead image)
- `gallery-3-role-tags.png` → "Write one recipe. Support them all."

## Files to upload

Use `tools\publish.ps1` (see its header) once these are set:

```
setx MODRINTH_PROJECT_ID "<base62 id from the new project>"
setx MODRINTH_TOKEN "<create at modrinth.com/settings/pats — needs 'Create versions' scope>"
# CurseForge optional at launch (Modrinth-only is how Reel Rivals started):
setx CURSEFORGE_PROJECT_ID "<numeric id>"
setx CURSEFORGE_TOKEN "<from legacy.curseforge.com/account/api-tokens>"
```

| Version | File | Loader |
|---|---|---|
| `0.1.0+mc1.21.1` | `pantrywork-0.1.0.jar` | NeoForge |
| `0.1.0+mc1.21.1-fabric` | `pantrywork-0.1.0-fabric.jar` | Fabric |

Changelog body for both uploads: `../../tools/changelog-current.md`.
Do NOT list Fabric API as a dependency — the Fabric jar doesn't need it.
