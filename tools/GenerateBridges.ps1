# GenerateBridges.ps1 - reverse-bridge generator.
#
# Forward bridging (canonical c:foods/* tags absorbing dialect tags) is
# hand-authored in src/main/resources as optional TAG references. This
# script handles the reverse direction, which must be ITEM-level entries
# to avoid tag reference cycles: for each category, every mod's dialect
# tag gains the other sources' member items as optional entries, so e.g.
# a Croptopia recipe requiring #c:cheeses accepts Pam's cheese.
#
# Output (all under src/generated/resources):
#   data/c/tags/item/<dialect>.json              ungated entries (PASS)
#   data/pantrywork/tags/item/bridged/<name>.json enumerations for canonical tags
#   pantrywork_gate_<n>/data/pantrywork/tags/item/gated/<mods>/...  GATEd entries, one
#       overlay directory per gate set, applied only while one of <mods> is loaded
#       (tag id pantrywork:gated/<mods joined by _or_>/c/<target> or .../bridged/<name>)
#   pack.mcmeta                                  declares those overlays for NeoForge
#       ("neoforge:overlays") and Fabric ("fabric:overlays")
# Report: tools/work/bridges-report.txt
# Rerun whenever a compat jar in tools/work/jars changes. ALWAYS pass
# -ExtraJarDirs tools\work\jars-26x (0.6.0 shipped without Aquaculture 2.9.x's
# largemouth bass because a run left it out).
#
# -ExtraJarDirs: additional jar directories to union in (e.g. tools\work\jars-26x
# so 26.x-only items - Croptopia 4.3.x foods, Aquaculture 2.9.x fish - join the
# bridges; on older MC lines those entries are required=false and just skip).
# tools\work\jars-12110 (Fabric 1.21.10/1.21.11 harness jars) is always scanned on top.
#
# -SelfTest: regression proof for rules that no CURRENT upstream tag exercises
# (fishofthieves:mango_pit and the FoT seeds sit only in c:seeds, so deleting the
# blacklist entry or the seed rule changes no real output). Plants those ids plus a
# "_sapling" name, an unvetted namespace, a too-cheap milk (must be EXCLUDED) and a
# quarter-bucket milk (must be GATED on Pam's in c:milk) into the tags, generates
# into a TEMP directory (src/generated and the report are never touched), and exits
# nonzero if any plant leaks, a gate or exclusion is wrong in the written files or
# pack.mcmeta, or the plants never reached a union at all (a vacuous pass).
#
# COST FLOORS. Every entry this script writes is judged by tools/CostFloor.ps1 against
# the data in tools/cost-floors.json (item costs; each tag's floor per defining mod):
#   PASS    -> the ungated file
#   GATE    -> an overlay applied only while a rescuing mod is loaded
#   EXCLUDE -> dropped, logged in the report with every floor ratio
# An emit target with no cost-floors.json entry, an item with no cost, or a scanned
# jar that defines a judged tag without a declared floor STOPS the run (nothing is
# written): stale floors must be fixed, never guessed. The gate mechanism (pack
# overlays, not conditions inside tag files, which every loader ignores) was proven
# live on NeoForge 1.21.1/26.1.2/26.2 and Fabric 1.21.1/1.21.11/26.2 on 2026-09-13.
param([string[]]$ExtraJarDirs = @(), [switch]$SelfTest)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
. (Join-Path $PSScriptRoot 'CostFloor.ps1')
$root = Split-Path $PSScriptRoot -Parent
# powershell -File passes "a,b" as ONE string: split it
$ExtraJarDirs = @($ExtraJarDirs | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$jarsDir = Join-Path $root "tools\work\jars"
$genRoot = Join-Path $root "src\generated\resources"
$reportFile = Join-Path $root "tools\work\bridges-report.txt"
if ($SelfTest) {
  $selfTestDir = Join-Path ([IO.Path]::GetTempPath()) ("pantrywork-selftest-" + [guid]::NewGuid().ToString('N'))
  $genRoot = Join-Path $selfTestDir "resources"
  $reportFile = Join-Path $selfTestDir "report.txt"
  New-Item -ItemType Directory -Force $genRoot | Out-Null
}
$outDir = Join-Path $genRoot "data\c\tags\item"
$bridgedDir = Join-Path $genRoot "data\pantrywork\tags\item\bridged"

$costData = Read-CostData $root
if ($costData.problems.Count) { "cost-floors.json is inconsistent:"; $costData.problems | ForEach-Object { "  $_" }; exit 1 }

# --- gather every item-tag definition from all sources ---
$tagEntries = @{}   # tagPath -> [System.Collections.ArrayList] of entry ids (strings, '#'-prefixed for tag refs)
function Add-TagFile($tagPath, $json) {
  $parsed = ConvertFrom-Json $json
  if (-not $tagEntries.ContainsKey($tagPath)) { $tagEntries[$tagPath] = New-Object System.Collections.ArrayList }
  foreach ($v in $parsed.values) {
    $id = if ($v -is [string]) { $v } else { $v.id }
    [void]$tagEntries[$tagPath].Add($id)
  }
}
# "ns:path" -> set of mod ids whose jar ships that tag file (the tag's defining mods)
$definers = @{}

# Namespaces we have actually opened and examined: every mod that ships
# assets/<ns>/lang inside a scanned jar, plus vanilla. Upstream tags routinely
# list optional ids for mods nobody here has looked at (Bountiful Fares'
# c:coconuts names natures_spirit:coconut and wilderwild:coconut; its
# c:foods/oranges names atmospheric:blood_orange). That is the mod's own call
# inside its own tag - but copying those ids into OTHER mods' tags would vouch
# for items we never checked are food, not seeds, not blocks, and not cheap.
# Only vetted namespaces cross a bridge; the rest are dropped and logged
# ("dropped unvetted") in the report.
$vettedNs = New-Object System.Collections.Generic.HashSet[string]
[void]$vettedNs.Add('minecraft')
function Test-IsUnvetted($id) { return -not $vettedNs.Contains(($id -split ':')[0]) }

$neoforgeJar = Get-ChildItem "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\net.neoforged\neoforge\21.1.241" -Recurse -Filter "neoforge-21.1.241-universal.jar" | Select-Object -First 1 -ExpandProperty FullName
$sources = @($neoforgeJar) + (Get-ChildItem $jarsDir -Filter "*.jar" | ForEach-Object FullName)
# tools/work/jars-12110 (the Fabric 1.21.10 / 1.21.11 harness compat jars: Croptopia Refabricated,
# FD Refabricated 3.4.2 and 3.6.13) is ALWAYS scanned, so the documented command
# (-ExtraJarDirs tools\work\jars-26x) cannot silently leave it out. It is how the Croptopia
# Refabricated mod id reaches definer coverage (review CF-2: the Fabric croptopia gate never
# opened on 1.21.10 and no scanned jar could have caught it).
$scanDirs = @()
foreach ($d in (@($ExtraJarDirs) + @('tools\work\jars-12110'))) {
  $dir = if ([IO.Path]::IsPathRooted($d)) { $d } else { Join-Path $root $d }
  $full = [IO.Path]::GetFullPath($dir).TrimEnd('\')
  if ($scanDirs -contains $full) { continue }
  if ($d -eq 'tools\work\jars-12110' -and -not (Test-Path $full)) { continue }
  $scanDirs += $full
  $sources += (Get-ChildItem $full -Filter "*.jar" | ForEach-Object FullName)
}
foreach ($jar in $sources) {
  $zip = [IO.Compression.ZipFile]::OpenRead($jar)
  $modIds = @(Get-JarModIds $zip)
  # definers use the canonical id (an alias such as croptopia-refabricated counts as croptopia)
  $primaryMod = if ($modIds.Count) { Resolve-ModAlias $costData $modIds[0] } else { [IO.Path]::GetFileNameWithoutExtension($jar) }
  foreach ($e in $zip.Entries) {
    if ($e.FullName -match '^assets/([^/]+)/lang/[^/]+\.json$') { [void]$vettedNs.Add($matches[1]) }
  }
  # c: tags keyed by bare path ("foods/cheese"); every other namespace keyed
  # "ns:path" ("brewinandchewin:foods/cheese_wedge") so a food mod that files
  # its items behind its own tag (not a c: tag) can still be followed by a
  # canonical tag that references it. minecraft: tags are skipped as noise.
  foreach ($e in ($zip.Entries | Where-Object { $_.FullName -match '^data/[^/]+/tags/item/.+\.json$' })) {
    $ns = ($e.FullName -split '/')[1]
    if ($ns -eq 'minecraft') { continue }
    $r = New-Object IO.StreamReader($e.Open()); $json = $r.ReadToEnd(); $r.Close()
    $path = $e.FullName -replace "^data/$ns/tags/item/",'' -replace '\.json$',''
    $key = if ($ns -eq 'c') { $path } else { "${ns}:$path" }
    Add-TagFile $key $json
    $tid = "${ns}:$path"
    if (-not $definers.ContainsKey($tid)) { $definers[$tid] = New-Object System.Collections.Generic.HashSet[string] }
    [void]$definers[$tid].Add($primaryMod)
  }
  $zip.Dispose()
}
# our hand-authored canonical tags participate in resolution too
Get-ChildItem (Join-Path $root "src\main\resources\data\c\tags\item") -Recurse -Filter "*.json" | ForEach-Object {
  $rel = $_.FullName.Substring((Join-Path $root "src\main\resources\data\c\tags\item").Length + 1) -replace '\\','/' -replace '\.json$',''
  Add-TagFile $rel (Get-Content $_.FullName -Raw)
}

# --- transitive resolution: tagPath -> set of item ids ---
function Resolve-Tag($tagPath, $visited) {
  $items = New-Object System.Collections.Generic.HashSet[string]
  if ($visited.Contains($tagPath) -or -not $tagEntries.ContainsKey($tagPath)) { return ,$items }
  [void]$visited.Add($tagPath)
  foreach ($id in $tagEntries[$tagPath]) {
    if ($id.StartsWith('#')) {
      $ref = $id.Substring(1)
      # c: tags are keyed by bare path; every other namespace keeps its "ns:path"
      # key, so both a "#c:foods/cheese" and a "#brewinandchewin:foods/cheese_wedge"
      # reference resolve to the items behind them.
      $key = if ($ref.StartsWith('c:')) { $ref.Substring(2) } else { $ref }
      foreach ($i in (Resolve-Tag $key $visited)) { [void]$items.Add($i) }
    } else {
      [void]$items.Add($id)
    }
  }
  return ,$items
}

# Never injected anywhere, and never enumerated into pantrywork:bridged/*.
#   - Items the target mods plausibly excluded on purpose (poison food,
#     golden-tier items). Principle: bridges widen ingredient pools, they don't
#     re-litigate another mod's exclusions.
#   - Non-food BLOCK items that upstream produce tags file next to the food:
#     Pam's c:fruits/melon holds the melon BLOCK and c:vegetables/pumpkin the
#     pumpkin BLOCK. Legitimate inside Pam's own tags; copied into
#     c:foods/fruit / c:foods/vegetable (0.6.0 did exactly that) they are bugs.
#   - bountifulfares:coconut is the palm SAPLING block item, with no food
#     component. BF files it in its own c:coconuts and Croptopia's c:fruits pulls
#     that in upstream (a datapack cannot subtract it) - we never spread it
#     further. BF's edible coconut_half has no counterpart in any other mod.
#   - create:honeyed_apple: a processed treat Create files as c:foods/fruit, same
#     precedent as golden_apple - not a raw fruit for another mod's recipe.
#   - fishofthieves:mango_pit: a planting seed that Test-IsSeed misses (FoT files
#     it under c:seeds, but the name is neither "_seed" nor "_seeds").
#   - Brewin' & Chewin' ripe cheese WHEELS: food-less BlockItems (BnCItems builds
#     them as new BlockItem(..., stacksTo(16)) with no .food()). 0.1.0-0.7.0 copied
#     them into c:cheese / c:cheeses and reached c:foods/cheese through a hand ref.
#     The wedges cut from them are the food and still cross.
$blacklist = @('minecraft:pufferfish', 'minecraft:golden_apple',
               'minecraft:enchanted_golden_apple', 'minecraft:golden_carrot',
               'minecraft:melon', 'minecraft:pumpkin',
               'bountifulfares:coconut', 'create:honeyed_apple',
               'fishofthieves:mango_pit',
               'brewinandchewin:flaxen_cheese_wheel', 'brewinandchewin:scarlet_cheese_wheel')

# Croptopia files its seeds INTO its produce tags (c:vegetables holds both
# lettuce and lettuce_seed). That is fine inside Croptopia, but a seed in a food
# tag would let a seed satisfy a food recipe. Seeds never cross a bridge.
#
# Identify planting seeds by what the ecosystem TAGS them as, not by their name:
# a name rule on "_seeds" wrongly condemns croptopia:roasted_pumpkin_seeds and
# roasted_sunflower_seeds, which are real edible foods. c:seeds is the mods' own
# classification and gets this right. The name pattern is kept only for saplings
# and singular "_seed", which no mod uses for a food item.
$seedSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($seedTag in @('seeds', 'seeds/', 'villager_plantable_seeds')) {
  foreach ($i in (Resolve-Tag $seedTag (New-Object System.Collections.Generic.HashSet[string]))) { [void]$seedSet.Add($i) }
}
# Neither signal is sufficient alone, so combine them:
#   - name ending "_seed"/"_sapling" is unambiguous; no mod ships food named that.
#   - "_seeds" is ambiguous (roasted_pumpkin_seeds is food), so it only counts as
#     a seed when the ecosystem ALSO files it under c:seeds.
#   - c:seeds membership alone is not sufficient either: plantable foods such as
#     farm_and_charm:onion and vanilla potato/carrot live there and must stay.
$blacklistPattern = '_seed$|_sapling$'
function Test-IsSeed($id) {
  if ($id -match $blacklistPattern) { return $true }
  if ($id -match '_seeds$' -and $seedSet.Contains($id)) { return $true }
  return $false
}

# -SelfTest plants: each of the first four is caught by exactly one rule - the
# blacklist (mango_pit), the c:seeds half of Test-IsSeed (pineapple_seeds), the name
# half (a vetted-namespace "_sapling"), and the vetted-namespace filter (an unscanned
# mod). The two milk plants exercise the cost floor: a 1/100-bucket milk no defining
# mod rescues (EXCLUDE everywhere) and a 1/4-bucket milk that only Pam's 1/8 fresh
# milk rescues in c:milk (GATE pamhc2foodcore) and only Croptopia in c:milks.
$selfTestPlants = @('fishofthieves:mango_pit', 'fishofthieves:pineapple_seeds', 'croptopia:selftest_sapling', 'selftestunvetted:fake_fruit', 'croptopia:selftest_milk_drop')
$selfTestGatePlant = 'farmersdelight:selftest_quarter_milk'
if ($SelfTest) {
  foreach ($k in @('fruits', 'fruits/mango', 'fruits/pineapple')) {
    if (-not $tagEntries.ContainsKey($k)) { $tagEntries[$k] = New-Object System.Collections.ArrayList }
    foreach ($p in $selfTestPlants[0..3]) { [void]$tagEntries[$k].Add($p) }
  }
  # exercise the c:seeds half even if Fish of Thieves ever stops filing it there
  [void]$seedSet.Add('fishofthieves:pineapple_seeds')
  # planted into c:drinks/milk: a source of the milk union but not an emit target, so
  # the plants are candidates for c:milk / c:milks rather than "already listed there"
  [void]$tagEntries['drinks/milk'].Add('croptopia:selftest_milk_drop')
  [void]$tagEntries['drinks/milk'].Add($selfTestGatePlant)
  $costData.items['croptopia:selftest_milk_drop'] = @{ cost = 0.01; unit = 'milk_bucket'; why = 'self-test plant' }
  $costData.items[$selfTestGatePlant] = @{ cost = 0.25; unit = 'milk_bucket'; why = 'self-test plant' }
}

# --- categories: dialect tags that mean the same thing.
# 'emit' lists the tags that receive injections: other mods' dialect tags, plus the
# c:foods/<name> tags Bountiful Fares defines as ITS dialect (c:foods/corn,
# c:foods/oranges, ...). Emits are ITEM entries only, never tag references to other
# mods' tags, so the one-directional rule holds: our hand-authored canonical tags
# reference dialect tags, and nothing we write makes a dialect tag reference back.
# (The only refs we emit point at our own pantrywork:gated/* item lists.)
# 'extra' names items that sit in no tag the category reads (a mod that tags
# nothing, or a fruit only filed under a generic parent).
#
# What each emit target may receive is decided by the cost floors in
# tools/cost-floors.json, not here. The reasons behind the numbers (yields read from
# the jars' recipes) live next to each item there; the tricky ones:
#   - Milk splits by container class: bucket 1, Farmer's Delight bottle 1/4, Pam's
#     fresh milk 1/8, Croptopia bottle 1/16, soy milk no milk at all.
#   - Farmer's Delight's knife makes 2 per whole item (porkchop -> 2 bacon, beef -> 2
#     minced_beef, chicken -> 2 chicken_cuts, mutton -> 2 mutton_chops, cod/salmon -> 2
#     slices, the cooked items -> 2 cooked cuts; bacon, patty and cuts then cook 1:1).
#     Farm & Charm's mincer makes 2 bacon / 3 chicken_parts per animal, but minced_beef
#     and lamb_ham 1:1. Ocean's Delight cuts 6 fugu slices per pufferfish and 9 elder
#     guardian slices per slab.
#   - Aquaculture 2.7.21 fillets (FishWeightHandler.registerFishData, weight config off
#     by default): atlantic_halibut 14, pacific_halibut 12, capitaine/arapaima/tuna 10,
#     atlantic_cod/catfish 6, gar/bayad/minecraft:cod 4, muskellunge/tambaqui/
#     red_grouper 3, most others 2, and exactly 1 for atlantic_herring, boulti,
#     synodontis, bluegill, perch and piranha. The cheapest fillet is 1/14 of a fish.
#   - Pam's toast is half a bread + half a butter (skillet -> 2) against Croptopia's
#     whole-bread toast: out of Croptopia's c:toasts (SapperSquad, 2026-09-13).
#   - Refurbished's toast (6 per bread), bread_slice and jams are in no category at
#     all, so no rule is needed to keep them out.
$categories = @(
  @{ name='cheese';         tags=@('cheeses','cheese','foods/cheese');                extra=@('refurbished_furniture:cheese');      emit=@('cheeses','cheese') },
  @{ name='dough';          tags=@('doughs','dough','foods/dough');                   extra=@('refurbished_furniture:dough');       emit=@('doughs','dough') },
  @{ name='butter';         tags=@('butters','butter','foods/butter');                emit=@('butters','butter') },
  @{ name='milk';           tags=@('milks','milk','drinks/milk');                     emit=@('milks','milk') },
  @{ name='salt';           tags=@('salts','salt');                                   extra=@('refurbished_furniture:sea_salt');    emit=@('salts','salt') },
  @{ name='oil';            tags=@('olive_oils','cookingoil');                        emit=@('olive_oils','cookingoil') },
  @{ name='stock';          tags=@('stock');  extra=@('farmersdelight:bone_broth');   emit=@('stock') },
  @{ name='pasta';          tags=@('pasta','foods/pasta');                            emit=@('pasta') },
  # Three dialects collide on the meats: FD/official `foods/raw_pork`, Pam's
  # concatenated `rawpork`, and Let's Do Farm & Charm's flat-underscored
  # `raw_pork`. All three names get the union, judged against each tag's own floor:
  # Pam's lists whole vanilla items only; Farm & Charm's c:raw_pork / raw_chicken /
  # cooked_pork / cooked_beef / cooked_chicken already hold its own cuts and dishes.
  @{ name='raw_pork';       tags=@('rawpork','raw_pork','foods/raw_pork');            emit=@('rawpork','raw_pork') },
  @{ name='raw_beef';       tags=@('rawbeef','raw_beef','beef_replacements','foods/raw_beef');   emit=@('rawbeef','raw_beef','beef_replacements') },
  @{ name='raw_chicken';    tags=@('rawchicken','raw_chicken','chicken_replacements','foods/raw_chicken'); emit=@('rawchicken','raw_chicken','chicken_replacements') },
  @{ name='raw_mutton';     tags=@('rawmutton','raw_mutton','foods/raw_mutton');      emit=@('rawmutton','raw_mutton') },
  @{ name='raw_bacon';      tags=@('raw_bacon','foods/raw_bacon');                    emit=@('raw_bacon') },
  @{ name='cooked_pork';    tags=@('cookedpork','cooked_pork','foods/cooked_pork');   emit=@('cookedpork','cooked_pork') },
  @{ name='cooked_beef';    tags=@('cookedbeef','cooked_beef','foods/cooked_beef');   emit=@('cookedbeef','cooked_beef') },
  @{ name='cooked_chicken'; tags=@('cookedchicken','cooked_chicken','foods/cooked_chicken'); emit=@('cookedchicken','cooked_chicken') },
  @{ name='cooked_mutton';  tags=@('cookedmutton','cooked_mutton','foods/cooked_mutton'); emit=@('cookedmutton','cooked_mutton') },
  @{ name='raw_fish';       tags=@('rawfish','fishes','raw_fishes','foods/raw_fish'); emit=@('rawfish','fishes','raw_fishes') },
  @{ name='cooked_fish';    tags=@('cookedfish','cooked_fishes','foods/cooked_fish'); emit=@('cookedfish','cooked_fishes') },
  @{ name='tomato';         tags=@('tomatoes','crops/tomato','foods/tomato');         emit=@('tomatoes','crops/tomato') },
  @{ name='onion';          tags=@('onions','crops/onion','foods/onion');             emit=@('onions','crops/onion') },
  @{ name='cabbage';        tags=@('cabbage','crops/cabbage','foods/cabbage');        emit=@('cabbage','crops/cabbage') },
  @{ name='strawberry';     tags=@('strawberries','strawberry');                      emit=@('strawberries','strawberry') },

  # --- collisions found by auditing every c: tag the bundled mods define ---
  # Note what is deliberately ABSENT as an emit target: c:caramel, c:bread and
  # c:egg are declared by two or more mods with the same members, so they merge
  # at load and need no bridge. c:flour and c:crops/corn used to be on this list
  # too; since 0.7.0 they ARE emitted, because Create's and Refurbished's flour
  # and Bountiful Fares' maize reach them through no mod's own reference (Create
  # flour only reached c:flour when Farm & Charm happened to be installed).
  #
  # Cereals: Croptopia files them under grain/<crop>, Farm & Charm under
  # grains/<crop>s, Farmer's Delight under crops/grain. All three mean cereal.
  @{ name='grain';          tags=@('grain','grains','crops/grain');                   emit=@('grain','grains','crops/grain') },
  @{ name='barley';         tags=@('barley','grain/barley','grains/barleys');         emit=@('grain/barley','grains/barleys') },
  @{ name='oat';            tags=@('oat','grain/oat','grains/oats');                  emit=@('grain/oat','grains/oats') },
  # Bountiful Fares files maize ONLY under c:foods/corn, a name no consumer reads.
  # foods/corn joins both the union and the emits: maize reaches c:crops/corn (and,
  # through Croptopia's own refs, c:corn and c:grain), and Croptopia/F&C corn
  # reaches BF's recipes. croptopia:corn_seed rides in via c:corn and is dropped by
  # Test-IsSeed; bountifulfares:maize_seeds is in no corn tag.
  @{ name='corn';           tags=@('corn','crops/corn','grain/corn','grains/corn','foods/corn'); emit=@('grain/corn','grains/corn','crops/corn','foods/corn') },
  # Croptopia writes snake_case where Pam's concatenates - same juice, two names.
  @{ name='apple_juice';    tags=@('apple_juices','juices/apple_juice','juices/applejuice'); emit=@('juices/apple_juice','juices/applejuice') },
  @{ name='melon_juice';    tags=@('melon_juices','juices/melon_juice','juices/melonjuice'); emit=@('juices/melon_juice','juices/melonjuice') },
  # Croptopia c:toasts vs Pam's c:toast; Croptopia c:ground_pork vs Pam's nested tag.
  @{ name='toast';          tags=@('toast','toasts','toast/toast');                   emit=@('toast','toasts') },
  @{ name='ground_pork';    tags=@('ground_pork','groundmeats/groundpork');           emit=@('ground_pork','groundmeats/groundpork') },
  # We already pull c:cookies into c:foods/cookie; this is the return direction.
  @{ name='cookie';         tags=@('cookies','cookies/cookie','foods/cookie');        emit=@('cookies') },
  # Croptopia, Pam's and BF each declare c:flour directly, but Create's flour lives
  # in c:flours and Refurbished's in no tag at all. Farm & Charm's c:flour ->
  # #c:flours ref was the only link, so without F&C Create's never reached a Pam's or
  # Croptopia recipe. Both names are emitted.
  @{ name='flour';          tags=@('flour','flours','flour/flour');                   extra=@('refurbished_furniture:wheat_flour'); emit=@('flours','flour') },
  @{ name='rice_grain';     tags=@('rice','crops/rice');                              emit=@('rice') },
  @{ name='vegetables';     tags=@('vegetables','foods/vegetable');                   emit=@('vegetables') },
  @{ name='fruits';         tags=@('fruits','foods/fruit');                           emit=@('fruits') },

  # --- per-fruit leaf tags (0.7.0) ---
  # Croptopia's c:<fruit>s tags reference c:fruits/<fruit>, so emitting into the
  # leaf reaches every Croptopia recipe for that fruit. Bountiful Fares names the
  # same fruits c:foods/<fruit>s. Fish of Thieves files its fruit only under the
  # generic c:foods/fruit + c:fruits/sweet, so its per-fruit members are named via
  # 'extra' - and ONLY whole fruit: half_pineapple (a portion) and raw_mango
  # (unripe) stay generic-fruit only; mango_pit is a seed (blacklisted).
  @{ name='banana';         tags=@('bananas','fruits/banana','crops/banana');         extra=@('fishofthieves:banana');  emit=@('fruits/banana') },
  @{ name='coconut';        tags=@('coconuts','fruits/coconut','crops/coconut');      extra=@('fishofthieves:coconut'); emit=@('fruits/coconut') },
  @{ name='mango';          tags=@('mangos','fruits/mango','crops/mango');            extra=@('fishofthieves:mango');   emit=@('fruits/mango') },
  @{ name='pineapple';      tags=@('pineapples','fruits/pineapple','crops/pineapple'); extra=@('fishofthieves:pineapple','fishofthieves:crownless_pineapple'); emit=@('fruits/pineapple') },
  @{ name='orange';         tags=@('oranges','fruits/orange','foods/oranges');        emit=@('fruits/orange','foods/oranges') },
  @{ name='lemon';          tags=@('lemons','fruits/lemon','foods/lemons');           emit=@('fruits/lemon','foods/lemons') },
  @{ name='plum';           tags=@('plums','fruits/plum','foods/plums');              emit=@('fruits/plum','foods/plums') },
  @{ name='elderberry';     tags=@('elderberries','fruits/elderberry','foods/elderberries'); emit=@('fruits/elderberry','foods/elderberries') },
  # A walnut is a nut to Croptopia (c:nuts/walnut) - follow that, not a fruit tag.
  @{ name='walnut';         tags=@('walnuts','nuts/walnut','foods/walnuts');          emit=@('nuts/walnut','foods/walnuts') },

  # --- Brewin' & Chewin' preserves into Pam's per-flavour jelly slots (0.7.0) ---
  # B&C's preserves are untagged. They cost MORE than Pam's jelly (3 fruit + sugar
  # in a cooking pot, bottle returned, vs Pam's juice-of-2 + sugar), so this is the
  # safe direction. Refurbished's jams (1 berry in a frying pan, no sugar) are
  # never added anywhere.
  @{ name='sweetberry_jelly'; tags=@('jellies/sweetberryjelly'); extra=@('brewinandchewin:sweet_berry_jam');      emit=@('jellies/sweetberryjelly') },
  @{ name='glowberry_jelly';  tags=@('jellies/glowberryjelly');  extra=@('brewinandchewin:glow_berry_marmalade'); emit=@('jellies/glowberryjelly') },
  @{ name='apple_jelly';      tags=@('jellies/applejelly');      extra=@('brewinandchewin:apple_jelly');          emit=@('jellies/applejelly') }
)

# --- forward sanitization -------------------------------------------------
# Some canonical tags cannot simply reference the dialect tags they bridge, because
# a datapack tag reference cannot subtract members:
#   - produce tags that mix planting seeds in with the food (Croptopia's c:vegetables
#     holds lettuce AND lettuce_seed), and Pam's melon/pumpkin blocks;
#   - dialect tags holding items below the canonical tag's cost floor (Croptopia's
#     1/16 bottle in c:milks, Farm & Charm's 1/15-wheat dough in c:doughs, its 1/45-
#     wheat farmers_bread in c:bread, its 1/9-chicken roasted_chicken in c:cooked_chicken).
# For these we enumerate item-by-item into `pantrywork:bridged/<name>`, judged
# against the canonical tag named in 'judgeAs', and the hand-authored canonical file
# references `#pantrywork:bridged/<name>`. The same enumeration drops blacklisted
# blocks and unvetted namespaces.
#
# Cost of doing it this way: an item added by a future version of the upstream mod
# is not picked up until this generator is re-run (and needs a cost in
# cost-floors.json before it can be). That is the accepted trade - a stale entry is
# invisible, a seed or a too-cheap item in a food recipe is a bug. The hand-authored
# canonical files must NOT also reference these source tags, or what was dropped
# comes straight back in through that reference.
#
# Why `pantrywork:bridged/<name>` and not the canonical file itself: two files at the
# same path inside one jar cannot merge the way two datapacks can - Gradle rightly
# refuses to package a duplicate - and the canonical file stays hand-authored.
# The role tags (pantrywork:food_component/*) reference the dialect tags directly
# where they need the full membership (starch -> #c:pasta, #c:bread): a role is our
# own classification, not a recipe slot with a floor.
$forwardSanitized = @(
  @{ target = 'vegetable';            sources = @('vegetables');                     judgeAs = 'c:foods/vegetable' },
  @{ target = 'fruit';                sources = @('fruits', 'strawberries');         judgeAs = 'c:foods/fruit' },
  @{ target = 'drinks_milk';          sources = @('milk', 'milks');                  judgeAs = 'c:drinks/milk' },
  # Refurbished's dough is in no upstream tag (the dough category names it via 'extra'),
  # so it is named here too, or c:foods/dough would lose it with the old #c:doughs ref
  @{ target = 'foods_dough';          sources = @('doughs', 'dough');                judgeAs = 'c:foods/dough'; extra = @('refurbished_furniture:dough') },
  @{ target = 'foods_pasta';          sources = @('pasta');                          judgeAs = 'c:foods/pasta' },
  @{ target = 'foods_bread';          sources = @('bread');                          judgeAs = 'c:foods/bread' },
  @{ target = 'foods_cooked_chicken'; sources = @('cookedchicken', 'cooked_chicken'); judgeAs = 'c:foods/cooked_chicken' }
)

# ============================================================================
# Plan everything in memory first; nothing on disk changes unless the plan is clean.
# ============================================================================
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$report = New-Object Text.StringBuilder
$verdictLog = New-Object System.Collections.ArrayList
$problems = New-Object System.Collections.ArrayList
$planFiles = [ordered]@{}      # path relative to $genRoot -> @{ items = [...]; refs = [...] }
$gateSets = @{}                # gate key -> sorted gate mod ids
$unvettedTotal = New-Object System.Collections.Generic.HashSet[string]

# Judges candidate items for one target. Returns pass (ids), gated (key -> ids), and
# writes GATE / EXCLUDE / rescued-PASS lines into the report.
function Split-ByVerdict([string]$judgeTag, $candidates, [string]$label) {
  $res = @{ pass = New-Object System.Collections.ArrayList; gated = [ordered]@{} }
  foreach ($x in ($candidates | Sort-Object)) {
    $v = Get-CostVerdict $costData $judgeTag $x
    switch ($v.verdict) {
      'PASS'     { [void]$res.pass.Add($x); if ($v.detail -match 'rescued|rescues') { [void]$verdictLog.Add("PASS     $label <- $x : $($v.detail)") } }
      'MOOT'     { [void]$res.pass.Add($x) }
      'GATE'     {
        $key = Get-GateKey $v.gates
        $gateSets[$key] = $v.gates
        if (-not $res.gated.Contains($key)) { $res.gated[$key] = New-Object System.Collections.ArrayList }
        [void]$res.gated[$key].Add($x)
        [void]$verdictLog.Add("GATE     $label <- $x [only with $($v.gates -join ' or ')] : $($v.detail)")
      }
      'EXCLUDE'  { [void]$verdictLog.Add("EXCLUDE  $label <- $x : $($v.detail)") }
      default    { [void]$problems.Add("$($v.verdict): $label <- $x : $($v.detail)") }
    }
  }
  return $res
}

# Adds a base file plus one overlay file per gate set to the plan.
function Add-PlannedTag([string]$baseRel, [string]$gatedPathPrefix, $split) {
  $refs = @()
  foreach ($key in $split.gated.Keys) {
    # The tag id carries the gate key (tag ids are global: two gate sets on one target need
    # distinct ids). The overlay DIRECTORY gets a short numbered name once every gate set
    # is known - "<gate:key>" is resolved in the write loop.
    $refs += "#pantrywork:gated/$key/$gatedPathPrefix"
    $overlayRel = "<gate:$key>\data\pantrywork\tags\item\gated\$key\$($gatedPathPrefix -replace '/','\').json"
    $planFiles[$overlayRel] = @{ items = @($split.gated[$key]); refs = @() }
  }
  if ($split.pass.Count -eq 0 -and $refs.Count -eq 0) { return $false }
  $planFiles[$baseRel] = @{ items = @($split.pass); refs = $refs }
  return $true
}

foreach ($cat in $categories) {
  $union = New-Object System.Collections.Generic.HashSet[string]
  foreach ($t in $cat.tags) {
    foreach ($i in (Resolve-Tag $t (New-Object System.Collections.Generic.HashSet[string]))) { [void]$union.Add($i) }
  }
  if ($cat.extra) { foreach ($i in $cat.extra) { [void]$union.Add($i) } }
  $blocked = @($blacklist | Where-Object { $union.Contains($_) })
  foreach ($b in $blacklist) { [void]$union.Remove($b) }
  foreach ($s in @($union | Where-Object { Test-IsSeed $_ })) { [void]$union.Remove($s) }
  $unvetted = @($union | Where-Object { Test-IsUnvetted $_ } | Sort-Object)
  foreach ($u in $unvetted) { [void]$union.Remove($u); [void]$unvettedTotal.Add($u) }
  [void]$report.AppendLine("[$($cat.name)] union: $(($union | Sort-Object) -join ', ')")
  if ($blocked.Count) { [void]$report.AppendLine("  blacklisted: $($blocked -join ', ')") }
  if ($unvetted.Count) { [void]$report.AppendLine("  dropped unvetted: $($unvetted -join ', ')") }
  foreach ($t in $cat.emit) {
    if (-not $tagEntries.ContainsKey($t)) { [void]$report.AppendLine("  $t : tag not defined by any source, skipped"); continue }
    # Skip only items the target tag lists DIRECTLY. Skipping everything the tag
    # merely reaches (0.6.0 did) made a bridge depend on a third mod's reference:
    # croptopia:dough reached Pam's c:dough only through Farm & Charm's
    # c:dough -> #c:doughs, so uninstalling F&C silently broke Croptopia dough in
    # Pam's recipes. A duplicate entry costs nothing (tag loading de-duplicates).
    $direct = New-Object System.Collections.Generic.HashSet[string]
    foreach ($x in $tagEntries[$t]) { if (-not $x.StartsWith('#')) { [void]$direct.Add($x) } }
    $candidates = @($union | Where-Object { -not $direct.Contains($_) })
    if ($candidates.Count -eq 0) { [void]$report.AppendLine("  c:$t : nothing to inject"); continue }
    $split = Split-ByVerdict "c:$t" $candidates "c:$t"
    $gatedIds = @(); foreach ($k in $split.gated.Keys) { $gatedIds += $split.gated[$k] }
    $excluded = @($candidates | Where-Object { $split.pass -notcontains $_ -and $gatedIds -notcontains $_ } | Sort-Object)
    if ($excluded.Count) { [void]$report.AppendLine("  c:$t : EXCLUDED below the cost floor: $($excluded -join ', ')") }
    $wrote = Add-PlannedTag "data\c\tags\item\$($t -replace '/','\').json" "c/$t" $split
    if (-not $wrote) { [void]$report.AppendLine("  c:$t : nothing to inject"); continue }
    if ($split.pass.Count) { [void]$report.AppendLine("  c:$t += $(($split.pass | Sort-Object) -join ', ')") }
    foreach ($k in $split.gated.Keys) { [void]$report.AppendLine("  c:$t += (GATED, only with $($gateSets[$k] -join ' or ')) $($split.gated[$k] -join ', ')") }
  }
  [void]$report.AppendLine("")
}

[void]$report.AppendLine("=== forward-sanitized (pantrywork:bridged/*) ===")
foreach ($fs in $forwardSanitized) {
  $members = New-Object System.Collections.Generic.HashSet[string]
  foreach ($s in $fs.sources) {
    foreach ($i in (Resolve-Tag $s (New-Object System.Collections.Generic.HashSet[string]))) { [void]$members.Add($i) }
  }
  if ($fs.extra) { foreach ($i in $fs.extra) { [void]$members.Add($i) } }
  $dropped = @($members | Where-Object { Test-IsSeed $_ } | Sort-Object)
  foreach ($d in $dropped) { [void]$members.Remove($d) }
  $blocked = @($blacklist | Where-Object { $members.Contains($_) })
  foreach ($b in $blacklist) { [void]$members.Remove($b) }
  $unvetted = @($members | Where-Object { Test-IsUnvetted $_ } | Sort-Object)
  foreach ($u in $unvetted) { [void]$members.Remove($u); [void]$unvettedTotal.Add($u) }
  if ($members.Count -eq 0) { [void]$report.AppendLine("  pantrywork:bridged/$($fs.target) : no members resolved, skipped"); continue }
  $label = "pantrywork:bridged/$($fs.target) ($($fs.judgeAs))"
  $split = Split-ByVerdict $fs.judgeAs @($members) $label
  $gatedIds = @(); foreach ($k in $split.gated.Keys) { $gatedIds += $split.gated[$k] }
  $excluded = @($members | Where-Object { $split.pass -notcontains $_ -and $gatedIds -notcontains $_ } | Sort-Object)
  [void](Add-PlannedTag "data\pantrywork\tags\item\bridged\$($fs.target).json" "bridged/$($fs.target)" $split)
  [void]$report.AppendLine("  pantrywork:bridged/$($fs.target) <- $($split.pass.Count) items from $($fs.sources -join ', ') (judged as $($fs.judgeAs)); dropped $($dropped.Count) seed(s): $($dropped -join ', ')")
  if ($blocked.Count) { [void]$report.AppendLine("    blacklisted: $($blocked -join ', ')") }
  if ($unvetted.Count) { [void]$report.AppendLine("    dropped unvetted: $($unvetted -join ', ')") }
  if ($excluded.Count) { [void]$report.AppendLine("    EXCLUDED below the cost floor: $($excluded -join ', ')") }
  foreach ($k in $split.gated.Keys) { [void]$report.AppendLine("    GATED, only with $($gateSets[$k] -join ' or '): $($split.gated[$k] -join ', ')") }
}
[void]$report.AppendLine("")

# --- defining-mod coverage: a scanned jar that defines a judged tag must have a floor ---
[void]$report.AppendLine("=== defining mods per judged tag (scanned jars) ===")
foreach ($tid in ($costData.tags.Keys | Sort-Object)) {
  $t = $costData.tags[$tid]
  if ($t.moot) { continue }
  $mods = if ($definers.ContainsKey($tid)) { @($definers[$tid] | Sort-Object) } else { @() }
  foreach ($p in (Test-DefinerCoverage $costData $tid $mods)) { [void]$problems.Add("STALE FLOORS: $p") }
  foreach ($p in (Test-FloorDefiners $costData $tid $mods)) { [void]$problems.Add("FICTIONAL FLOOR: $p") }
  $undetected = @($t.floors.Keys | Where-Object { $mods -notcontains $_ })
  $note = if ($undetected.Count) { "   (declared but in no scanned jar: $($undetected -join ', '))" } else { '' }
  [void]$report.AppendLine("  ${tid}: $($mods -join ', ')$note")
}
[void]$report.AppendLine("")

# --- pack.mcmeta: one conditional overlay per gate set, for both loaders ---
# Overlay directories are numbered in sorted gate-key order (pantrywork_gate_1, _2, ...).
# Naming them after every mod id AND repeating that key in the tag path pushed generated
# paths past Windows' 260-character MAX_PATH as soon as the tree was copied one level
# deeper than the repo. pack.mcmeta shows each directory's mods next to its name.
$gateKeys = @($gateSets.Keys | Sort-Object)
$dirOf = @{}; $gateIndex = 0
foreach ($key in $gateKeys) { $gateIndex++; $dirOf[$key] = "pantrywork_gate_$gateIndex" }
$neoEntries = @(); $fabEntries = @()
foreach ($key in $gateKeys) {
  $mods = @($gateSets[$key])
  $dir = $dirOf[$key]
  if ($dir -notmatch '^[-_a-zA-Z0-9.]+$') { [void]$problems.Add("overlay directory name '$dir' is not a legal pack overlay name"); continue }
  # Each loader's condition names the canonical rescuers plus that loader's aliases (modAliases in
  # cost-floors.json): on Fabric a croptopia gate must also open for croptopia-refabricated.
  $neoMods = @(Get-LoaderModIds $costData $mods 'neoforge')
  $fabMods = @(Get-LoaderModIds $costData $mods 'fabric')
  $neoParts = @($neoMods | ForEach-Object { '{ "type": "neoforge:mod_loaded", "modid": "' + $_ + '" }' })
  $fabValues = (@($fabMods | ForEach-Object { '"' + $_ + '"' }) -join ', ')
  $neoCond = if ($neoMods.Count -eq 1) { $neoParts[0] } else { '{ "type": "neoforge:or", "values": [ ' + ($neoParts -join ', ') + ' ] }' }
  $fabCond = if ($fabMods.Count -eq 1) { '{ "condition": "fabric:all_mods_loaded", "values": [' + $fabValues + '] }' } else { '{ "condition": "fabric:any_mods_loaded", "values": [' + $fabValues + '] }' }
  $neoEntries += "      {`n        ""neoforge:conditions"": [ $neoCond ],`n        ""formats"": [48, 1000],`n        ""min_format"": 48,`n        ""max_format"": 1000,`n        ""directory"": ""$dir""`n      }"
  $fabEntries += "      {`n        ""directory"": ""$dir"",`n        ""condition"": $fabCond`n      }"
}
# The "pack" section is mandatory: Fabric reads a jar's own pack.mcmeta whenever one
# exists, and vanilla drops a pack whose metadata has no "pack" section. The vanilla
# "overlays" key is unconditional and must never be used here.
$mcmeta = "{`n  ""pack"": {`n    ""description"": ""Pantrywork"",`n    ""pack_format"": 48,`n    ""supported_formats"": [48, 1000],`n    ""min_format"": 48,`n    ""max_format"": 1000`n  },`n" +
          "  ""neoforge:overlays"": {`n    ""entries"": [`n$($neoEntries -join ",`n")`n    ]`n  },`n" +
          "  ""fabric:overlays"": {`n    ""entries"": [`n$($fabEntries -join ",`n")`n    ]`n  }`n}`n"

[void]$report.AppendLine("=== COST-FLOOR VERDICTS (tolerance $($costData.tolerance)x; ratio = floor / cost; every GATE and EXCLUDE, and every PASS that needed a rescue) ===")
foreach ($l in ($verdictLog | Sort-Object -Unique)) { [void]$report.AppendLine("  $l") }
if ($gateKeys.Count -eq 0) { [void]$report.AppendLine("  overlays: none") }
foreach ($key in $gateKeys) { [void]$report.AppendLine("  overlay $($dirOf[$key]) (tags pantrywork:gated/$key/...) applies while any of these is loaded: $($gateSets[$key] -join ', ')") }
[void]$report.AppendLine("")
[void]$report.AppendLine("=== vetted namespaces (assets/<ns>/lang in a scanned jar, + minecraft) ===")
[void]$report.AppendLine("  $(($vettedNs | Sort-Object) -join ', ')")
[void]$report.AppendLine("  dropped unvetted (all categories): $(if ($unvettedTotal.Count) { ($unvettedTotal | Sort-Object) -join ', ' } else { 'none' })")

if ($problems.Count) {
  "GENERATION STOPPED - nothing was written ($($problems.Count) problem(s)):"
  $problems | Sort-Object -Unique | ForEach-Object { "  $_" }
  if ($SelfTest) { Remove-Item $selfTestDir -Recurse -Force }
  exit 1
}

# --- write the plan ---
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
if (Test-Path $bridgedDir) { Remove-Item $bridgedDir -Recurse -Force }
Get-ChildItem $genRoot -Directory -Filter 'pantrywork_gate_*' -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.FullName -Recurse -Force }
foreach ($rel in $planFiles.Keys) {
  $f = $planFiles[$rel]
  $lines = @($f.items | Sort-Object | ForEach-Object { "    { ""id"": ""$_"", ""required"": false }" })
  $lines += @($f.refs | Sort-Object | ForEach-Object { "    { ""id"": ""$_"", ""required"": false }" })
  $outRel = $rel
  if ($rel -match '^<gate:([^>]+)>(.*)$') { $outRel = $dirOf[$matches[1]] + $matches[2] }
  $full = Join-Path $genRoot $outRel
  New-Item -ItemType Directory -Force (Split-Path $full) | Out-Null
  [IO.File]::WriteAllText($full, "{`n  ""values"": [`n$($lines -join ",`n")`n  ]`n}`n", $utf8NoBom)
}
[IO.File]::WriteAllText((Join-Path $genRoot 'pack.mcmeta'), $mcmeta, $utf8NoBom)
[IO.File]::WriteAllText($reportFile, $report.ToString(), $utf8NoBom)
"Wrote $($planFiles.Count) tag files ($(@($planFiles.Keys | Where-Object { $_ -like '<gate:*' }).Count) gated, in $($gateKeys.Count) overlays) + pack.mcmeta to $genRoot"
"Verdicts: $(@($verdictLog | Where-Object { $_ -like 'GATE*' }).Count) GATE, $(@($verdictLog | Where-Object { $_ -like 'EXCLUDE*' }).Count) EXCLUDE, $(@($verdictLog | Where-Object { $_ -like 'PASS*' }).Count) rescued PASS"
"Report: $reportFile"

if ($SelfTest) {
  $problems = New-Object System.Collections.ArrayList
  $reportText = [IO.File]::ReadAllText($reportFile)
  function Read-Rel($rel) { $p = Join-Path $genRoot $rel; if (Test-Path $p) { return [IO.File]::ReadAllText($p) } else { return $null } }
  # 1. nothing planted may reach ANY emitted file
  foreach ($f in Get-ChildItem $genRoot -Recurse -File) {
    $txt = [IO.File]::ReadAllText($f.FullName)
    foreach ($p in $selfTestPlants) {
      if ($txt.Contains("""$p""")) { [void]$problems.Add("LEAK: $p in $($f.FullName.Substring($genRoot.Length + 1))") }
    }
  }
  # 2. the plants must actually have been seen, or a pass proves nothing: the blacklist
  #    and vetted-namespace filters log per category, the seed rule per bridged/* file,
  #    the cost floor in the verdict section
  if ($reportText -notmatch 'blacklisted: [^\r\n]*fishofthieves:mango_pit') { [void]$problems.Add("VACUOUS: mango_pit never reached a union (report has no 'blacklisted' line for it)") }
  if ($reportText -notmatch 'dropped unvetted: [^\r\n]*selftestunvetted:fake_fruit') { [void]$problems.Add("VACUOUS: the unvetted plant never reached a union") }
  if ($reportText -notmatch 'bridged/fruit <- [^\r\n]*croptopia:selftest_sapling') { [void]$problems.Add("VACUOUS: the sapling plant was not dropped as a seed from bridged/fruit") }
  if ($reportText -notmatch 'bridged/fruit <- [^\r\n]*fishofthieves:pineapple_seeds') { [void]$problems.Add("VACUOUS: pineapple_seeds was not dropped as a seed from bridged/fruit") }
  if ($reportText -notmatch 'EXCLUDE  c:milk <- croptopia:selftest_milk_drop') { [void]$problems.Add("VACUOUS: the 1/100-bucket milk plant was never judged EXCLUDE in c:milk") }
  if ($reportText -notmatch 'GATE     c:milk <- farmersdelight:selftest_quarter_milk \[only with pamhc2foodcore\]') { [void]$problems.Add("VACUOUS/WRONG: the 1/4-bucket milk plant was not judged GATE pamhc2foodcore in c:milk") }
  # review CF-3: a dual-route item costed on its plant route (croptopia:ground_pork, 0 meat)
  if ($reportText -notmatch 'EXCLUDE  c:groundmeats/groundpork <- croptopia:ground_pork') { [void]$problems.Add("VACUOUS/WRONG: croptopia:ground_pork was not judged EXCLUDE in c:groundmeats/groundpork") }
  # 3. exclusions and gates hold in the WRITTEN files (base file vs overlay)
  $mustNot = @(
    @{ rel = 'data\c\tags\item\milk.json';        ids = @('croptopia:milk_bottle', 'croptopia:soy_milk', 'farmersdelight:milk_bottle', $selfTestGatePlant) },
    @{ rel = 'data\c\tags\item\milks.json';       ids = @('farmersdelight:milk_bottle', 'pamhc2foodcore:freshmilkitem', $selfTestGatePlant) },
    @{ rel = 'data\pantrywork\tags\item\bridged\drinks_milk.json'; ids = @('croptopia:milk_bottle', 'croptopia:soy_milk', 'pamhc2foodcore:freshmilkitem') },
    @{ rel = 'data\c\tags\item\cheese.json';      ids = @('croptopia:cheese', 'brewinandchewin:flaxen_cheese_wheel', 'brewinandchewin:scarlet_cheese_wheel') },
    @{ rel = 'data\c\tags\item\rawpork.json';     ids = @('farmersdelight:bacon') }
  )
  foreach ($c in $mustNot) {
    $txt = Read-Rel $c.rel
    if ($null -eq $txt) { [void]$problems.Add("MISSING: $($c.rel) was not generated"); continue }
    foreach ($id in $c.ids) { if ($txt.Contains("""$id""")) { [void]$problems.Add("NOT GATED/EXCLUDED: $id is in the ungated $($c.rel)") } }
  }
  # an EXCLUDE may not survive in ANY file for that target, gated overlays included
  foreach ($x in @(@{ t = 'toasts'; id = 'pamhc2foodcore:toastitem' }, @{ t = 'olive_oils'; id = 'pamhc2foodcore:cookingoilitem' }, @{ t = 'groundmeats/groundpork'; id = 'croptopia:ground_pork' })) {
    foreach ($f in Get-ChildItem $genRoot -Recurse -File -Filter "$(Split-Path $x.t -Leaf)*.json") {
      if ([IO.File]::ReadAllText($f.FullName).Contains("""$($x.id)""")) { [void]$problems.Add("DILUTION: $($x.id) in $($f.FullName.Substring($genRoot.Length + 1))") }
    }
    foreach ($f in Get-ChildItem $genRoot -Recurse -File | Where-Object { $_.FullName -match "gated\\[^\\]+\\c\\$($x.t -replace '/', '\\')\.json$" }) {
      if ([IO.File]::ReadAllText($f.FullName).Contains("""$($x.id)""")) { [void]$problems.Add("DILUTION (gated): $($x.id) in $($f.FullName.Substring($genRoot.Length + 1))") }
    }
  }
  # the Pam's-only overlay is found by its declared condition, never by guessing its number
  $pm = ConvertFrom-Json (Read-Rel 'pack.mcmeta')
  $pamDir = @($pm.'fabric:overlays'.entries | Where-Object { (@($_.condition.values) -join ',') -eq 'pamhc2foodcore' } | ForEach-Object { $_.directory })
  $milkBase = Read-Rel 'data\c\tags\item\milk.json'
  if ($milkBase -and -not $milkBase.Contains('"#pantrywork:gated/pamhc2foodcore/c/milk"')) { [void]$problems.Add("GATE REF MISSING: milk.json does not reference #pantrywork:gated/pamhc2foodcore/c/milk") }
  if ($pamDir.Count -ne 1) { [void]$problems.Add("pack.mcmeta: expected exactly one fabric overlay conditioned on pamhc2foodcore alone, found $($pamDir.Count)"); $pamDir = @('pantrywork_gate_missing') }
  $milkGate = Read-Rel "$($pamDir[0])\data\pantrywork\tags\item\gated\pamhc2foodcore\c\milk.json"
  if ($null -eq $milkGate) { [void]$problems.Add("GATE FILE MISSING: $($pamDir[0])/data/pantrywork/tags/item/gated/pamhc2foodcore/c/milk.json") }
  else { foreach ($id in @('farmersdelight:milk_bottle', $selfTestGatePlant)) { if (-not $milkGate.Contains("""$id""")) { [void]$problems.Add("GATE FILE: $id missing from the pamhc2foodcore c:milk overlay") } } }
  # 4. pack.mcmeta declares every overlay directory on disk, for both loaders, with matching mods
  if (-not $pm.pack -or $pm.pack.pack_format -ne 48) { [void]$problems.Add("pack.mcmeta: missing or wrong 'pack' section") }
  if ($pm.PSObject.Properties.Name -contains 'overlays') { [void]$problems.Add("pack.mcmeta: uses the unconditional vanilla 'overlays' key") }
  $onDisk = @(Get-ChildItem $genRoot -Directory -Filter 'pantrywork_gate_*' | ForEach-Object Name | Sort-Object)
  $neoDirs = @($pm.'neoforge:overlays'.entries | ForEach-Object directory | Sort-Object)
  $fabDirs = @($pm.'fabric:overlays'.entries | ForEach-Object directory | Sort-Object)
  if (($onDisk -join ',') -ne ($neoDirs -join ',') -or ($onDisk -join ',') -ne ($fabDirs -join ',')) { [void]$problems.Add("pack.mcmeta overlays differ from disk: disk [$($onDisk -join ',')] neoforge [$($neoDirs -join ',')] fabric [$($fabDirs -join ',')]") }
  $neoPam = @($pm.'neoforge:overlays'.entries | Where-Object { $_.directory -eq $pamDir[0] })
  if ($neoPam.Count -ne 1 -or $neoPam[0].'neoforge:conditions'[0].type -ne 'neoforge:mod_loaded' -or $neoPam[0].'neoforge:conditions'[0].modid -ne 'pamhc2foodcore') { [void]$problems.Add("pack.mcmeta: neoforge overlay for pamhc2foodcore is missing or has the wrong condition") }
  $fabPam = @($pm.'fabric:overlays'.entries | Where-Object { $_.directory -eq $pamDir[0] })
  if ($fabPam.Count -ne 1 -or (@($fabPam[0].condition.values) -join ',') -ne 'pamhc2foodcore') { [void]$problems.Add("pack.mcmeta: fabric overlay for pamhc2foodcore is missing or has the wrong condition") }
  # 5. review CF-2: each Fabric condition names the NeoForge rescuers plus their Fabric aliases
  #    (croptopia -> croptopia-refabricated), with any_mods_loaded when it names more than one id;
  #    NeoForge conditions never name a Fabric-only alias. Non-vacuous: some gate names the alias.
  $sawAlias = $false
  foreach ($en in $pm.'neoforge:overlays'.entries) {
    $c = $en.'neoforge:conditions'[0]
    $neoIds = @(if ($c.type -eq 'neoforge:mod_loaded') { $c.modid } else { $c.values | ForEach-Object { $_.modid } })
    $fe = @($pm.'fabric:overlays'.entries | Where-Object { $_.directory -eq $en.directory })
    if ($fe.Count -ne 1) { continue }
    $want = @(Get-LoaderModIds $costData $neoIds 'fabric' | Sort-Object)
    $got = @($fe[0].condition.values | Sort-Object)
    if (($want -join ',') -ne ($got -join ',')) { [void]$problems.Add("pack.mcmeta: fabric overlay $($en.directory) names [$($got -join ',')], expected [$($want -join ',')]") }
    if ($got.Count -gt 1 -and $fe[0].condition.condition -ne 'fabric:any_mods_loaded') { [void]$problems.Add("pack.mcmeta: fabric overlay $($en.directory) names $($got.Count) mods with $($fe[0].condition.condition), expected fabric:any_mods_loaded") }
    if ($got -contains 'croptopia-refabricated') { $sawAlias = $true }
    if ($neoIds -contains 'croptopia-refabricated') { [void]$problems.Add("pack.mcmeta: neoforge overlay $($en.directory) names the Fabric-only alias croptopia-refabricated") }
  }
  if (-not $sawAlias) { [void]$problems.Add("VACUOUS: no fabric overlay names croptopia-refabricated (the croptopia gate would never open on Fabric 1.21.10)") }
  Remove-Item $selfTestDir -Recurse -Force
  if ($problems.Count) { "SELF-TEST FAILED ($($problems.Count))"; $problems | ForEach-Object { "  $_" }; exit 1 }
  "SELF-TEST PASSED: $($selfTestPlants.Count) planted ids reached the unions and none leaked; the cost-floor plants were EXCLUDED and GATED as derived; exclusions and gates hold in the written files and pack.mcmeta"
  exit 0
}
