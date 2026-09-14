# AuditRoles.ps1 - ground-truth audit of what the role tags actually resolve to.
#
# Loads every item tag definition visible at runtime (NeoForge jar + every compat
# jar in tools/work/jars + Pantrywork's own hand-authored and generated data, the
# gated pack overlays included), resolves each tag transitively, and reports:
#   1. any member that violates the "seeds never cross a bridge" invariant
#   2. any tag reference that is REQUIRED but defined by nobody (a hard datapack
#      load failure for whoever is missing it)
#   3. c:foods/milk shim containment (widening, joins to #c:foods, role refs)
#   4. NON-FOOD items (blocks, saplings, pits, processed treats, cheese wheels,
#      dilution-class items) that reach a tag through an entry PANTRYWORK authored
#   5. DILUTION: a hand-kept table of known too-cheap (tag, item) pairs, independent of
#      the cost data, so an edit to cost-floors.json that "fixes" a number is still caught
#   6. THIRD-MOD DEPENDENCE: a bridge that only resolves while some third mod's own
#      tag reference happens to be installed (the 0.6.0 generator-skip bug)
#   7. COST FLOOR: every item any Pantrywork path delivers into a judged tag is judged
#      with tools/cost-floors.json (the same rule GenerateBridges.ps1 applies). EXCLUDE
#      fails; GATE fails unless EVERY Pantrywork path to it is conditional on a
#      rescuing mod; an unknown cost, an undeclared defining mod, a declared floor whose mod
#      defines the tag in no scanned jar (any MC line), a Pantrywork entry in a tag
#      cost-floors.json does not know, or overlays whose NeoForge and Fabric declarations do
#      not name the same rescuers (plus each loader's modAliases) also fail.
#
# Gated entries: tools/GenerateBridges.ps1 writes GATEd items into pack overlays
# (src/generated/resources/pantrywork_gate_<n>/...) declared in pack.mcmeta. Checks
# 1-6 see an overlay only when one of its mods is among the scanned jars (never in
# -Minimal), exactly as the game would. Check 7 walks every overlay and proves the gate.
#
# Check 2 also covers bare REQUIRED item ids from optional mods: an unresolvable
# required item fails the whole merged tag on 1.21.1, other mods' entries included.
#
# Exits nonzero when any check fails, so it can gate a release.
# Run:  powershell -File tools\AuditRoles.ps1
#
# -Minimal simulates the worst-case install: Pantrywork ALONE, with no compat
# mods and no platform convention tags. Any cross-mod/convention tag reference we
# mark REQUIRED is undefined there, and a required reference to an undefined tag is a
# hard datapack load failure - a world that will not load. Run both modes.
param([switch]$Minimal)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
. (Join-Path $PSScriptRoot 'CostFloor.ps1')
$root = Split-Path $PSScriptRoot -Parent
$jarsDir = Join-Path $root "tools\work\jars"
$genRoot = Join-Path $root "src\generated\resources"
$costData = Read-CostData $root

# tagKey -> list of entries; entry = @{ id=<string>; required=<bool>; src=<string>; gate=<string[] or $null> }
# src is the jar file name the entry came from, or 'pantrywork' for anything in
# src/main or src/generated. Provenance is what lets the checks below tell OUR
# widening (a bug) from another mod's own classification (not ours to undo - a
# datapack cannot subtract a member, and re-classifying is against rule 2).
# gate is the overlay's mod list for entries that live in a pantrywork_gate_* overlay.
$tags = @{}
function Add-TagJson($key, $json, $src, $gate) {
  if (-not $tags.ContainsKey($key)) { $tags[$key] = New-Object System.Collections.ArrayList }
  $parsed = ConvertFrom-Json $json
  foreach ($v in $parsed.values) {
    if ($v -is [string]) { [void]$tags[$key].Add(@{ id = $v; required = $true; src = $src; gate = $gate }) }
    else {
      $req = $true
      if ($null -ne $v.required) { $req = [bool]$v.required }
      [void]$tags[$key].Add(@{ id = $v.id; required = $req; src = $src; gate = $gate })
    }
  }
}
function Key($ns, $path) { if ($ns -eq 'c') { return $path } else { return "${ns}:$path" } }
function TagId($key) { if ($key -like '*:*') { return $key } else { return "c:$key" } }

# src -> namespaces that source's mod owns (assets/<ns>/lang in the jar; the same
# "vetted namespace" signal GenerateBridges.ps1 uses); src -> primary mod id
$ownedNs = @{}
$srcMod = @{ 'pantrywork' = 'pantrywork' }
$definers = @{}    # tag id -> set of mod ids whose scanned jar ships the tag file
$loadedMods = New-Object System.Collections.Generic.HashSet[string]

$neoJar = Get-ChildItem "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\net.neoforged\neoforge" -Recurse -Filter "neoforge-*-universal.jar" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
$sources = @()
if (-not $Minimal) {
  if ($neoJar) { $sources += $neoJar }
  if (Test-Path $jarsDir) { $sources += (Get-ChildItem $jarsDir -Filter "*.jar" | ForEach-Object FullName) }
}
foreach ($jar in $sources) {
  $src = Split-Path $jar -Leaf
  $ownedNs[$src] = New-Object System.Collections.Generic.HashSet[string]
  $zip = [IO.Compression.ZipFile]::OpenRead($jar)
  $ids = @(Get-JarModIds $zip)
  # canonical ids (modAliases in cost-floors.json): a croptopia-refabricated jar counts as croptopia
  $srcMod[$src] = if ($ids.Count) { Resolve-ModAlias $costData $ids[0] } else { $src }
  foreach ($m in $ids) { [void]$loadedMods.Add($m); [void]$loadedMods.Add((Resolve-ModAlias $costData $m)) }
  foreach ($e in $zip.Entries) {
    if ($e.FullName -match '^assets/([^/]+)/lang/[^/]+\.json$') { [void]$ownedNs[$src].Add($matches[1]) }
  }
  foreach ($e in ($zip.Entries | Where-Object { ($_.FullName -replace '[/]','/') -match '/tags/item/' })) {
    $ns = ($e.FullName -split '/')[1]
    $r = New-Object IO.StreamReader($e.Open()); $j = $r.ReadToEnd(); $r.Close()
    $path = $e.FullName -replace "^data/$ns/tags/item/",'' -replace '\.json$',''
    Add-TagJson (Key $ns $path) $j $src $null
    $tid = "${ns}:$path"
    if (-not $definers.ContainsKey($tid)) { $definers[$tid] = New-Object System.Collections.Generic.HashSet[string] }
    [void]$definers[$tid].Add($srcMod[$src])
  }
  $zip.Dispose()
}
# Definers on EVERY scanned MC line (tools/work/jars + jars-26x + jars-12110, the generator's full
# set), used only to prove each declared floor has a real defining jar (Test-FloorDefiners, check 7).
# Their tag CONTENTS are not loaded: this audit resolves the 1.21.1 NeoForge pack.
$floorDefiners = @{}
foreach ($k in $definers.Keys) { $floorDefiners[$k] = New-Object System.Collections.Generic.HashSet[string]; foreach ($m in $definers[$k]) { [void]$floorDefiners[$k].Add($m) } }
if (-not $Minimal) {
  foreach ($xd in @('tools\work\jars-26x', 'tools\work\jars-12110')) {
    $xfull = Join-Path $root $xd
    if (-not (Test-Path $xfull)) { continue }
    foreach ($jar in (Get-ChildItem $xfull -Filter "*.jar")) {
      $zip = [IO.Compression.ZipFile]::OpenRead($jar.FullName)
      $xids = @(Get-JarModIds $zip)
      $xmod = if ($xids.Count) { Resolve-ModAlias $costData $xids[0] } else { $jar.Name }
      foreach ($e in $zip.Entries) {
        if ($e.FullName -match '^data/([^/]+)/tags/item/(.+)\.json$') {
          $tid = "$($matches[1]):$($matches[2])"
          if (-not $floorDefiners.ContainsKey($tid)) { $floorDefiners[$tid] = New-Object System.Collections.Generic.HashSet[string] }
          [void]$floorDefiners[$tid].Add($xmod)
        }
      }
      $zip.Dispose()
    }
  }
}
# Pantrywork's own data (hand-authored + generated)
foreach ($dir in @("src\main\resources\data", "src\generated\resources\data")) {
  $full = Join-Path $root $dir
  if (-not (Test-Path $full)) { continue }
  Get-ChildItem $full -Recurse -Filter "*.json" | Where-Object { $_.FullName.Replace([char]92, [char]47) -match '/tags/item/' } | ForEach-Object {
    $rel = $_.FullName.Substring($full.Length + 1).Replace([char]92, [char]47)
    if ($rel -match '^([^/]+)/tags/item/(.+)\.json$') { Add-TagJson (Key $matches[1] $matches[2]) ([IO.File]::ReadAllText($_.FullName)) 'pantrywork' $null }
  }
}
# Gated overlays, as declared in pack.mcmeta. The NeoForge and Fabric declarations must
# name the same directories with the same mods, and every overlay on disk must be declared.
$overlayProblems = New-Object System.Collections.ArrayList
$overlayGates = @{}   # overlay dir -> mod ids
$mcmetaPath = Join-Path $genRoot 'pack.mcmeta'
if (Test-Path $mcmetaPath) {
  $pm = ConvertFrom-Json ([IO.File]::ReadAllText($mcmetaPath))
  if (-not $pm.pack) { [void]$overlayProblems.Add("pack.mcmeta has no 'pack' section (Fabric would drop the whole pack)") }
  if ($pm.PSObject.Properties.Name -contains 'overlays') { [void]$overlayProblems.Add("pack.mcmeta uses the unconditional vanilla 'overlays' key") }
  $fab = @{}; $neo = @{}; $fabKind = @{}
  foreach ($en in $pm.'fabric:overlays'.entries) { $fab[$en.directory] = @($en.condition.values | Sort-Object); $fabKind[$en.directory] = $en.condition.condition }
  foreach ($en in $pm.'neoforge:overlays'.entries) {
    $c = $en.'neoforge:conditions'[0]
    $mods = if ($c.type -eq 'neoforge:mod_loaded') { @($c.modid) } elseif ($c.type -eq 'neoforge:or') { @($c.values | ForEach-Object { $_.modid }) } else { @("UNSUPPORTED:$($c.type)") }
    $neo[$en.directory] = @($mods | Sort-Object)
  }
  # The two declarations must name the same CANONICAL rescuers; each loader's list is those plus
  # that loader's aliases (review CF-2: Fabric's croptopia gate must also name croptopia-refabricated).
  foreach ($d in (@($fab.Keys) + @($neo.Keys) | Sort-Object -Unique)) {
    if (-not $fab.ContainsKey($d) -or -not $neo.ContainsKey($d)) { [void]$overlayProblems.Add("overlay $d is declared for only one loader"); continue }
    $canon = @($neo[$d] | ForEach-Object { Resolve-ModAlias $costData $_ } | Sort-Object -Unique)
    $wantNeo = @(Get-LoaderModIds $costData $canon 'neoforge' | Sort-Object)
    $wantFab = @(Get-LoaderModIds $costData $canon 'fabric' | Sort-Object)
    if (($neo[$d] -join ',') -ne ($wantNeo -join ',')) { [void]$overlayProblems.Add("overlay $($d): neoforge mods [$($neo[$d] -join ',')] should be [$($wantNeo -join ',')]"); continue }
    if (($fab[$d] -join ',') -ne ($wantFab -join ',')) { [void]$overlayProblems.Add("overlay $($d): fabric mods [$($fab[$d] -join ',')] differ from the neoforge rescuers plus their Fabric aliases [$($wantFab -join ',')]"); continue }
    $wantKind = if ($wantFab.Count -eq 1) { 'fabric:all_mods_loaded' } else { 'fabric:any_mods_loaded' }
    if ($fabKind[$d] -ne $wantKind) { [void]$overlayProblems.Add("overlay $($d): fabric condition $($fabKind[$d]) over [$($fab[$d] -join ',')], expected $wantKind"); continue }
    $overlayGates[$d] = $canon
  }
}
foreach ($od in (Get-ChildItem $genRoot -Directory -Filter 'pantrywork_gate_*' -ErrorAction SilentlyContinue)) {
  if (-not $overlayGates.ContainsKey($od.Name)) { [void]$overlayProblems.Add("overlay directory $($od.Name) exists but pack.mcmeta does not declare it (it would never load)"); continue }
  $full = Join-Path $od.FullName 'data'
  Get-ChildItem $full -Recurse -Filter "*.json" | ForEach-Object {
    $rel = $_.FullName.Substring($full.Length + 1).Replace([char]92, [char]47)
    if ($rel -match '^([^/]+)/tags/item/(.+)\.json$') {
      $k = Key $matches[1] $matches[2]
      if ($k -notlike 'pantrywork:gated/*') { [void]$overlayProblems.Add("overlay $($od.Name) holds $k outside pantrywork:gated/* (it would shadow a base file)") }
      Add-TagJson $k ([IO.File]::ReadAllText($_.FullName)) 'pantrywork' $overlayGates[$od.Name]
    }
  }
}
# An overlay applies when any of its mods is loaded (NeoForge neoforge:or / Fabric any_mods_loaded).
function Test-EntryActive($entry, $mods) {
  if ($null -eq $entry.gate) { return $true }
  foreach ($g in $entry.gate) { if ($mods.Contains($g)) { return $true } }
  return $false
}

$definedBy = @{}   # which keys exist at all: an empty tag file defines its tag; a tag known only
                   # through overlays whose mods are not loaded does not
foreach ($k in $tags.Keys) {
  if ($tags[$k].Count -eq 0 -or @($tags[$k] | Where-Object { Test-EntryActive $_ $loadedMods }).Count) { $definedBy[$k] = $true }
}

$missingRequired = New-Object System.Collections.ArrayList
function Resolve-Members($key, $visited) {
  $items = New-Object System.Collections.Generic.HashSet[string]
  if ($visited.Contains($key) -or -not $tags.ContainsKey($key)) { return ,$items }
  [void]$visited.Add($key)
  foreach ($entry in $tags[$key]) {
    if (-not (Test-EntryActive $entry $loadedMods)) { continue }
    $id = $entry.id
    if ($id.StartsWith('#')) {
      $ref = $id.Substring(1)
      $refKey = if ($ref.StartsWith('c:')) { $ref.Substring(2) } else { $ref }
      if (-not $definedBy.ContainsKey($refKey)) {
        if ($entry.required) { [void]$missingRequired.Add("$key -> $id (REQUIRED but undefined)") }
        continue
      }
      foreach ($i in (Resolve-Members $refKey $visited)) { [void]$items.Add($i) }
    } else {
      # A bare string entry is REQUIRED. A required item id that does not resolve
      # fails the WHOLE merged tag on 1.21.1 - every other mod's entries go with it -
      # so Pantrywork must never require an item from an optional mod, even when that
      # mod's jar is present in this audit.
      $itemNs = ($id -split ':')[0]
      if ($entry.required -and $entry.src -eq 'pantrywork' -and @('minecraft', 'pantrywork', 'neoforge', 'c') -notcontains $itemNs) {
        [void]$missingRequired.Add("$key -> $id (REQUIRED item from an optional mod)")
      }
      [void]$items.Add($id)
    }
  }
  return ,$items
}

# --- provenance resolution ---------------------------------------------------
# Walks EVERY path from a tag down to its literal items (a path stack instead of
# a global visited set, so an item reachable along two routes is seen on both)
# and records per item:
#   pw - some path to it passes through an entry Pantrywork authored. The entry
#        may be the literal item itself (a generated injection) or any tag ref on
#        the way (a hand-authored #ref into a tag that holds it). Either way our
#        data is what puts it there.
#   up - the sources whose LITERAL entry supplies it on a purely-upstream path.
# Get-Provenance caches per tag; the graph is small, paths are short. Inactive gated
# entries are skipped here (checks 3-5 see the pack as loaded); check 7 walks them all.
$provCache = @{}
function Walk-Provenance($key, $viaPw, $stack, $out) {
  if ($stack.Contains($key) -or -not $tags.ContainsKey($key)) { return }
  [void]$stack.Add($key)
  foreach ($entry in $tags[$key]) {
    if (-not (Test-EntryActive $entry $loadedMods)) { continue }
    $pw = $viaPw -or ($entry.src -eq 'pantrywork')
    $id = $entry.id
    if ($id.StartsWith('#')) {
      $ref = $id.Substring(1)
      $refKey = if ($ref.StartsWith('c:')) { $ref.Substring(2) } else { $ref }
      Walk-Provenance $refKey $pw $stack $out
    } else {
      if (-not $out.ContainsKey($id)) { $out[$id] = @{ pw = $false; up = New-Object System.Collections.Generic.HashSet[string] } }
      if ($pw) { $out[$id].pw = $true } else { [void]$out[$id].up.Add($entry.src) }
    }
  }
  [void]$stack.Remove($key)
}
function Get-Provenance($key) {
  if (-not $provCache.ContainsKey($key)) {
    $out = @{}
    Walk-Provenance $key $false (New-Object System.Collections.Generic.HashSet[string]) $out
    $provCache[$key] = $out
  }
  return $provCache[$key]
}

# Mirrors Test-IsSeed in GenerateBridges.ps1 - keep the two in step.
# "_seed"/"_sapling" is unambiguous; "_seeds" only counts when the ecosystem also
# files it under c:seeds (so roasted_pumpkin_seeds stays food); and c:seeds
# membership alone is not enough (plantable foods like onion live there too).
$seedSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($st in @('seeds', 'seeds/', 'villager_plantable_seeds')) {
  foreach ($i in (Resolve-Members $st (New-Object System.Collections.Generic.HashSet[string]))) { [void]$seedSet.Add($i) }
}
function Test-IsSeed($id) {
  if ($id -match '_seed$|_sapling$') { return $true }
  if ($id -match '_seeds$' -and $seedSet.Contains($id)) { return $true }
  return $false
}
# Audit every tag Pantrywork itself asserts - the role tags AND the canonical
# c: identity tags it defines - because a seed sitting in c:foods/vegetable is
# just as wrong as one in a role tag, even if no role currently surfaces it.
$ownKeys = New-Object System.Collections.Generic.HashSet[string]
foreach ($dir in @("src\main\resources\data", "src\generated\resources\data")) {
  $full = Join-Path $root $dir
  if (-not (Test-Path $full)) { continue }
  Get-ChildItem $full -Recurse -Filter "*.json" | Where-Object { $_.FullName.Replace([char]92, [char]47) -match '/tags/item/' } | ForEach-Object {
    $rel = $_.FullName.Substring($full.Length + 1).Replace([char]92, [char]47)
    if ($rel -match '^([^/]+)/tags/item/(.+)\.json$') { [void]$ownKeys.Add((Key $matches[1] $matches[2])) }
  }
}
$roles = @($ownKeys | Sort-Object)
# Two classes of tag get audited differently:
#   CANONICAL - the taxonomy this mod owns and is answerable for. A seed here is
#               our bug and fails the build.
#   INJECTED  - another mod's dialect tag that we only add items to. If Croptopia
#               files a seed in its own c:fruits, that is its call and a datapack
#               cannot subtract members anyway; re-classifying it would break the
#               project's own rule. Reported for visibility, never fatal - what
#               matters is that no CANONICAL tag reaches it.
function Test-IsCanonical($key) {
  return ($key -like 'pantrywork:*' -or $key -match '^foods($|/)' -or $key -match '^drinks($|/)' -or $key -eq 'eggs')
}
"=== PANTRYWORK TAG AUDIT ($($roles.Count) tags asserted by this mod; $($overlayGates.Count) gated overlays, active: $(@($overlayGates.Keys | Where-Object { @($overlayGates[$_] | Where-Object { $loadedMods.Contains($_) }).Count }).Count)) ==="
$violations = 0
$upstream = New-Object System.Collections.ArrayList
foreach ($r in $roles) {
  $members = Resolve-Members $r (New-Object System.Collections.Generic.HashSet[string])
  $bad = @($members | Where-Object { Test-IsSeed $_ } | Sort-Object)
  $canon = Test-IsCanonical $r
  $mark = ""
  if ($bad.Count) { $mark = if ($canon) { "   <-- $($bad.Count) VIOLATIONS" } else { "   (upstream: $($bad.Count))" } }
  "{0,-46} {1,4} members{2}" -f $r, $members.Count, $mark
  if ($bad.Count) {
    if ($canon) { $violations += $bad.Count; foreach ($b in $bad) { "        $b" } }
    else { foreach ($b in $bad) { [void]$upstream.Add("$r : $b") } }
  }
}
""
"=== UPSTREAM SEEDS (another mod's own tags - informational, not ours to fix) ==="
if ($upstream.Count -eq 0) { "  none" } else { $upstream | ForEach-Object { "  $_" } }
""
# --- containment check for the c:foods/milk deprecation shim ---------------
# c:foods/milk is life support for a name Farmer's Delight deliberately retired,
# not part of Pantrywork's taxonomy. It must stay a leaf that only the addons
# still referencing it can see:
#   - never reachable from #c:foods - neither milk item has food value, and that
#     is the exact objection that got the tag deprecated upstream (FD issue #1201)
#   - never reachable from a pantrywork:* role tag - dairy and liquid_base already
#     model milk correctly via separate #c:buckets/milk + #c:drinks/milk refs
#   - never widened past the milk bucket. FD's own last definition also held its
#     1/4-bucket bottle; the cost floor removed it (review CF-1: 4x below Bountiful Fares'
#     bucket, the only scanned reader). A nested #c:drinks/milk ref would drag in six
#     items including croptopia's 16-per-bucket milk_bottle and cowless soy_milk
#
# Widening is classified by provenance, never by a hardcoded item list:
#   WIDENED BY PANTRYWORK  - any path to the item passes through our data. Fails.
#   UPSTREAM WIDENING      - the item arrives ONLY through upstream entries AND the
#                            mod that owns the item's namespace lists it DIRECTLY
#                            in its own c:foods/milk (Bountiful Fares declares
#                            [milk_bucket, coconut_milk_bottle]). Reported, not
#                            fatal: that is BF's own classification of its own item.
#   anything else          - a third party widening the shim with someone else's
#                            item, or an indirect route. Fails; look at it.
"=== c:foods/milk SHIM CONTAINMENT ==="
$shimLeak = 0
if ($tags.ContainsKey('foods/milk')) {
    $prov = Get-Provenance 'foods/milk'
    $allowed = @('minecraft:milk_bucket')
    "  c:foods/milk members: $(($prov.Keys | Sort-Object) -join ', ')"
    foreach ($x in @($prov.Keys | Where-Object { $allowed -notcontains $_ } | Sort-Object)) {
        $ns = ($x -split ':')[0]
        $ownDirect = @($tags['foods/milk'] | Where-Object { $_.id -eq $x -and $_.src -ne 'pantrywork' -and $ownedNs.ContainsKey($_.src) -and $ownedNs[$_.src].Contains($ns) } | ForEach-Object { $_.src })
        if ($prov[$x].pw) { $shimLeak++; "  WIDENED BY PANTRYWORK: $x" }
        elseif ($ownDirect.Count) { "  UPSTREAM WIDENING (declared by the item's own mod, $($ownDirect -join ', ')): $x" }
        else { $shimLeak++; "  WIDENED BEYOND FD'S DEFINITION (via $(($prov[$x].up | Sort-Object) -join ', ')): $x" }
    }
    foreach ($parent in @('foods')) {
        if ((Resolve-Members $parent (New-Object System.Collections.Generic.HashSet[string])) -contains 'minecraft:milk_bucket') {
            $shimLeak++; "  LEAK: milk is reachable from #c:$parent"
        }
    }
    foreach ($rt in @($tags.Keys | Where-Object { $_ -like 'pantrywork:food_component*' })) {
        # dairy/liquid_base legitimately contain milk_bucket via c:buckets/milk;
        # the leak we care about is a path THROUGH the shim tag itself.
        if ($tags[$rt] | Where-Object { $_.id -eq '#c:foods/milk' }) { $shimLeak++; "  LEAK: $rt references #c:foods/milk directly" }
    }
    if ($shimLeak -eq 0) { "  contained: not joined to #c:foods, not referenced by any role tag, not widened by Pantrywork" }
} else { "  (shim not present)" }
""
# --- NON-FOOD check ------------------------------------------------------------
# Items that must never enter a food tag BECAUSE OF US. Every one of them already
# sits in some upstream tag legitimately, which is why a plain membership test is
# the wrong tool: Croptopia's own c:fruits pulls in Bountiful Fares' coconut
# sapling via #c:coconuts, Pam's own c:fruits holds the melon block, Create's own
# c:foods/fruit holds honeyed_apple. Those are the upstream mods' calls and a
# datapack cannot subtract them.
#
# So the test is provenance, per (tag, item):
#   FAIL      - some path to the item passes through a Pantrywork entry: a
#               generated injection, a pantrywork:bridged/* enumeration, or a
#               hand-authored #ref into a tag that holds it. Referencing a tag we
#               know holds a block is the same mistake as copying the block.
#   upstream  - it arrives only through other mods' own declarations. Reported.
#
# Two scopes, because one denylist cannot serve both kinds of item:
#   GENERAL  - blocks, a sapling item, a seed-pit, a processed treat, Brewin' &
#              Chewin's food-less cheese wheel BlockItems. Wrong in any food tag, so
#              checked in EVERY tag Pantrywork asserts.
#   DILUTION - Refurbished's toast / bread_slice (6 per bread) and jams (1 berry,
#              no sugar). Refurbished itself files the slice and toast in
#              c:foods/bread, and starch -> #c:foods/bread is a Pantrywork ref, so
#              a GENERAL scope would fail on Refurbished's own (defensible) "a
#              slice is bread" choice. What we must never do is pass them to the
#              recipes they would undercut, so they are checked only in the tags a
#              Pantrywork bridge writes that concept into: c:toast, c:toasts,
#              c:jams and every c:jellies/*.
"=== NON-FOOD / DILUTION-CLASS ITEMS ==="
$nonFoodFail = 0
# fishofthieves:mango_pit is a future-upstream guard, not a live check: FoT files the
# pit only under c:seeds, so no tag path reaches it today and deleting the generator's
# blacklist entry still passes here. GenerateBridges.ps1 -SelfTest is the live proof.
$generalDeny = @('minecraft:melon', 'minecraft:pumpkin', 'bountifulfares:coconut', 'create:honeyed_apple', 'fishofthieves:mango_pit',
                 'brewinandchewin:flaxen_cheese_wheel', 'brewinandchewin:scarlet_cheese_wheel')
$scopedDeny = @('refurbished_furniture:toast', 'refurbished_furniture:bread_slice', 'refurbished_furniture:sweet_berry_jam', 'refurbished_furniture:glow_berry_jam')
$scopedTags = @(@('toast', 'toasts', 'jams') + @($tags.Keys | Where-Object { $_ -like 'jellies/*' }) | Where-Object { $tags.ContainsKey($_) } | Sort-Object -Unique)
$nonFoodUp = New-Object System.Collections.ArrayList
$checks = @()
foreach ($t in $roles) { foreach ($d in $generalDeny) { $checks += ,@($t, $d) } }
foreach ($t in $scopedTags) { foreach ($d in $scopedDeny) { $checks += ,@($t, $d) } }
foreach ($c in $checks) {
  $t = $c[0]; $d = $c[1]
  $p = Get-Provenance $t
  if (-not $p.ContainsKey($d)) { continue }
  $label = if ($t -like '*:*') { "#$t" } else { "#c:$t" }
  if ($p[$d].pw) { $nonFoodFail++; "  FAIL  $label <- $d (through a Pantrywork entry)" }
  else { [void]$nonFoodUp.Add("  upstream  $label <- $d (declared by $(($p[$d].up | Sort-Object) -join ', '))") }
}
if ($nonFoodFail -eq 0) { "  none routed by Pantrywork (general denylist over $($roles.Count) tags; dilution-class over $($scopedTags -join ', '))" }
$nonFoodUp | Sort-Object -Unique
""
# --- path conditions (used by checks 5 and 7) --------------------------------------
# Walks EVERY path from a tag to its literal items, gated overlays included whether or
# not their mods are scanned, and records per item the list of Pantrywork paths, each
# with what the path proves is loaded:
#   mods  - the mod of every UPSTREAM entry on the path (Croptopia's c:salts -> #c:salt
#           ref only exists while Croptopia is loaded)
#   gates - the mod list of every gated overlay entry on the path (the overlay only
#           applies while one of those mods is loaded)
# A GATE(R) verdict is satisfied on a path when some path mod is in R, or some overlay
# on the path has all of its mods in R. Only Pantrywork paths are judged: an upstream
# mod's own members are its call.
$pathCache = @{}
function Walk-Paths($key, $viaPw, $mods, $gates, $stack, $out) {
  if ($stack.Contains($key) -or -not $tags.ContainsKey($key)) { return }
  [void]$stack.Add($key)
  foreach ($entry in $tags[$key]) {
    $pw = $viaPw -or ($entry.src -eq 'pantrywork')
    $m2 = $mods; $g2 = $gates
    if ($entry.src -ne 'pantrywork' -and $srcMod.ContainsKey($entry.src)) { $m2 = @($mods) + $srcMod[$entry.src] }
    if ($null -ne $entry.gate) { $g2 = @($gates) + ,(@($entry.gate)) }
    $id = $entry.id
    if ($id.StartsWith('#')) {
      $ref = $id.Substring(1)
      $refKey = if ($ref.StartsWith('c:')) { $ref.Substring(2) } else { $ref }
      Walk-Paths $refKey $pw $m2 $g2 $stack $out
    } elseif ($pw) {
      if (-not $out.ContainsKey($id)) { $out[$id] = New-Object System.Collections.ArrayList }
      [void]$out[$id].Add(@{ mods = @($m2); gates = @($g2); via = @($stack) })
    }
  }
  [void]$stack.Remove($key)
}
function Get-PwPaths($key) {
  if (-not $pathCache.ContainsKey($key)) {
    $out = @{}
    Walk-Paths $key $false @() @() (New-Object System.Collections.Generic.HashSet[string]) $out
    $pathCache[$key] = $out
  }
  return $pathCache[$key]
}
function Test-PathSatisfies($path, $rescuers) {
  foreach ($m in $path.mods) { if ($rescuers -contains $m) { return $true } }
  foreach ($g in $path.gates) {
    if (@($g | Where-Object { $rescuers -notcontains $_ }).Count -eq 0) { return $true }
  }
  return $false
}
function Format-Path($path) {
  $s = ($path.via -join ' > ')
  if ($path.gates.Count) { $s += " [gated: $(($path.gates | ForEach-Object { $_ -join '|' }) -join '; ')]" }
  return $s
}

# --- DILUTION guard ---------------------------------------------------------------
# A hand-kept table, independent of tools/cost-floors.json: each (tag, item) pair is an
# item below that tag's floor. 'never' pairs fail on ANY Pantrywork path; 'gated' pairs
# fail on any Pantrywork path that is not conditional on one of the listed mods. An
# upstream mod's own declaration is not ours and never fails.
#   milk          Croptopia bottle 1/16 bucket, soy milk no milk (Pam's floor 1/8); FD
#                 bottle 1/4 only with Pam's (F&C / Meadow buckets); in c:milks FD bottle
#                 and Pam's 1/8 fresh milk only with Croptopia (Meadow buckets)
#   drinks/milk   + Pam's 1/8 fresh milk; floor FD's 1/4 bottle
#   foods/milk    every milk below Bountiful Fares' bucket, FD's 1/4 bottle included (CF-1)
#   cheese/butter Croptopia's, made from its 1/16 bottle; floor Pam's 1/8; B&C wheels are
#                 food-less blocks; Pam's cheese in c:cheeses only with Croptopia
#   dough/flour   F&C dough (1/15 wheat) and farmers bread; Create/FD/Pam's dough in
#                 Croptopia's c:doughs only with F&C; Create flour only with BF/F&C/Pam's
#   meat / fish   FD, F&C and Ocean's Delight cuts (2-9 per whole item), Aquaculture fillets
#                 (a halibut fillets into 14), F&C roasted_chicken (~1/9 chicken) and
#                 bacon_with_eggs (1/3 porkchop), Meadow's 4-per-meat cooked buffalo meat,
#                 Croptopia's ground pork (tofu route, no meat) in Pam's ground pork (CF-3)
#   other         Pam's toast in c:toasts (half a bread), Pam's cooking oil in c:olive_oils
#                 (1/2 vegetable vs 2 olives), Croptopia's one-apple and one-slice juices in
#                 Pam's two-apple and two-slice juice tags (bottle returned, FC1-1), FD's
#                 cabbage leaf (1/2 cabbage) as a vegetable. NOT here: the melon slice in
#                 c:fruits (raw gathered produce = 1 unit, a PASS since FC2-4)
"=== DILUTION GUARD (items below a tag's cost floor) ==="
$dilution = 0
$dilutionOk = 0
$rawFishCuts = @('farmersdelight:cod_slice', 'farmersdelight:salmon_slice', 'oceansdelight:fugu_slice', 'oceansdelight:elder_guardian_slice')
$cookedFishCuts = @('farmersdelight:cooked_cod_slice', 'farmersdelight:cooked_salmon_slice', 'oceansdelight:cooked_elder_guardian_slice', 'aquaculture:fish_fillet_cooked')
$wheels = @('brewinandchewin:flaxen_cheese_wheel', 'brewinandchewin:scarlet_cheese_wheel')
$dilutionGuard = @(
  @{ tag = 'milk';          never = @('croptopia:milk_bottle', 'croptopia:soy_milk') },
  @{ tag = 'milk';          gated = @('pamhc2foodcore'); ids = @('farmersdelight:milk_bottle') },
  @{ tag = 'milks';         gated = @('croptopia'); ids = @('farmersdelight:milk_bottle', 'pamhc2foodcore:freshmilkitem') },
  @{ tag = 'drinks/milk';   never = @('croptopia:milk_bottle', 'croptopia:soy_milk', 'pamhc2foodcore:freshmilkitem') },
  @{ tag = 'foods/milk';    never = @('farmersdelight:milk_bottle', 'croptopia:milk_bottle', 'croptopia:soy_milk', 'pamhc2foodcore:freshmilkitem') },
  @{ tag = 'groundmeats/groundpork'; never = @('croptopia:ground_pork') },
  @{ tag = 'groundmeats';   never = @('croptopia:ground_pork') },
  @{ tag = 'cheese';        never = @('croptopia:cheese') + $wheels },
  @{ tag = 'cheeses';       never = $wheels },
  @{ tag = 'cheeses';       gated = @('croptopia'); ids = @('pamhc2foodcore:cheeseitem') },
  @{ tag = 'foods/cheese';  never = $wheels },
  @{ tag = 'butter';        never = @('croptopia:butter') },
  @{ tag = 'doughs';        gated = @('farm_and_charm'); ids = @('create:dough', 'farmersdelight:wheat_dough', 'pamhc2foodcore:doughitem') },
  @{ tag = 'foods/dough';   never = @('farm_and_charm:dough') },
  @{ tag = 'foods/dough';   gated = @('create'); ids = @('pamhc2foodcore:doughitem') },
  @{ tag = 'flour';         gated = @('bountifulfares', 'farm_and_charm', 'pamhc2foodcore'); ids = @('create:wheat_flour') },
  @{ tag = 'foods/pasta';   never = @('farm_and_charm:raw_pasta', 'pamhc2foodcore:pastaitem') },
  @{ tag = 'foods/bread';   never = @('farm_and_charm:farmers_bread') },
  @{ tag = 'salts';         gated = @('croptopia'); ids = @('pamhc2foodcore:saltitem') },
  @{ tag = 'olive_oils';    never = @('pamhc2foodcore:cookingoilitem') },
  @{ tag = 'toasts';        never = @('pamhc2foodcore:toastitem') },
  @{ tag = 'juices/applejuice'; never = @('croptopia:apple_juice') },
  @{ tag = 'juices/melonjuice'; never = @('croptopia:melon_juice') },
  @{ tag = 'vegetables';    gated = @('croptopia'); ids = @('farmersdelight:cabbage_leaf') },
  @{ tag = 'foods/vegetable'; never = @('farmersdelight:cabbage_leaf') },
  @{ tag = 'rawpork';       never = @('farmersdelight:bacon', 'farm_and_charm:bacon') },
  @{ tag = 'rawbeef';       never = @('farmersdelight:minced_beef') },
  @{ tag = 'raw_beef';      never = @('farmersdelight:minced_beef') },
  @{ tag = 'rawchicken';    never = @('farmersdelight:chicken_cuts', 'farm_and_charm:chicken_parts') },
  @{ tag = 'rawmutton';     never = @('farmersdelight:mutton_chops') },
  @{ tag = 'raw_mutton';    never = @('farmersdelight:mutton_chops') },
  @{ tag = 'rawfish';       never = $rawFishCuts },
  @{ tag = 'fishes';        never = $rawFishCuts },
  @{ tag = 'raw_fishes';    never = $rawFishCuts },
  @{ tag = 'foods/raw_fish'; never = @('oceansdelight:fugu_slice', 'oceansdelight:elder_guardian_slice') },
  @{ tag = 'cookedpork';    never = @('farmersdelight:cooked_bacon', 'farm_and_charm:bacon_with_eggs') },
  @{ tag = 'cookedbeef';    never = @('farmersdelight:beef_patty') },
  @{ tag = 'cookedchicken'; never = @('farmersdelight:cooked_chicken_cuts', 'farm_and_charm:roasted_chicken') },
  @{ tag = 'foods/cooked_chicken'; never = @('farm_and_charm:roasted_chicken') },
  @{ tag = 'foods/cooked_meat'; never = @('farm_and_charm:roasted_chicken', 'meadow:cooked_buffalo_meat') },
  @{ tag = 'cookedmutton';  never = @('farmersdelight:cooked_mutton_chops') },
  @{ tag = 'cooked_mutton'; never = @('farmersdelight:cooked_mutton_chops') },
  @{ tag = 'cookedfish';    never = $cookedFishCuts },
  @{ tag = 'cooked_fishes'; never = $cookedFishCuts }
)
foreach ($row in $dilutionGuard) {
  $t = $row.tag
  if (-not $tags.ContainsKey($t)) { continue }
  $paths = Get-PwPaths $t
  $ids = if ($row.never) { $row.never } else { $row.ids }
  foreach ($x in $ids) {
    if (-not $paths.ContainsKey($x)) { $dilutionOk++; continue }
    if ($row.never) {
      $dilution++; "  FAIL: Pantrywork routes $x into c:$t ($(Format-Path $paths[$x][0]))"
    } else {
      $bad = @($paths[$x] | Where-Object { -not (Test-PathSatisfies $_ $row.gated) })
      if ($bad.Count) { $dilution++; "  FAIL: Pantrywork routes $x into c:$t without a $($row.gated -join '/') gate ($(Format-Path $bad[0]))" }
      else { $dilutionOk++ }
    }
  }
}
if ($dilution -eq 0) { "  none routed by Pantrywork ($dilutionOk tag/item pairs absent or correctly gated)" }
""
# --- THIRD-MOD DEPENDENCE ------------------------------------------------------------
# 0.6.0's generator skipped an injection whenever the target tag already REACHED the
# item through any reference - including a third mod's. The bridge then silently
# vanished for players without that third mod: croptopia:dough reached Pam's c:dough
# only via Farm & Charm's c:dough -> #c:doughs, farm_and_charm:strawberry reached
# Pam's c:fruits only via Croptopia's c:fruits -> #c:strawberries. Re-resolve each
# tag with the third mod's entries (and the overlays it alone satisfies) removed and
# require the item to still be there. Needs no running server, so it covers the
# strawberry half that no dev boot can (there is no -PnoCroptopia run).
"=== THIRD-MOD DEPENDENCE (bridge must survive without the third mod) ==="
function Resolve-MembersWithout($key, $srcPattern, $mods, $visited) {
  $items = New-Object System.Collections.Generic.HashSet[string]
  if ($visited.Contains($key) -or -not $tags.ContainsKey($key)) { return ,$items }
  [void]$visited.Add($key)
  foreach ($entry in $tags[$key]) {
    if ($entry.src -match $srcPattern) { continue }
    if (-not (Test-EntryActive $entry $mods)) { continue }
    $id = $entry.id
    if ($id.StartsWith('#')) {
      $ref = $id.Substring(1)
      $refKey = if ($ref.StartsWith('c:')) { $ref.Substring(2) } else { $ref }
      foreach ($i in (Resolve-MembersWithout $refKey $srcPattern $mods $visited)) { [void]$items.Add($i) }
    } else { [void]$items.Add($id) }
  }
  return ,$items
}
$dependence = 0
$independence = @(
  @{ tag = 'fruits'; item = 'farm_and_charm:strawberry'; without = '^croptopia';     mod = 'croptopia';      label = 'Croptopia' },
  @{ tag = 'dough';  item = 'croptopia:dough';           without = 'farm_and_charm'; mod = 'farm_and_charm'; label = 'Farm & Charm' },
  @{ tag = 'flour';  item = 'create:wheat_flour';        without = 'farm_and_charm'; mod = 'farm_and_charm'; label = 'Farm & Charm' }
)
foreach ($ic in $independence) {
  $mods = New-Object System.Collections.Generic.HashSet[string]
  foreach ($m in $loadedMods) { if ($m -ne $ic.mod) { [void]$mods.Add($m) } }
  $m = Resolve-MembersWithout $ic.tag $ic.without $mods (New-Object System.Collections.Generic.HashSet[string])
  if ($Minimal) { "  (skipped in -Minimal: no compat jars)"; break }
  if ($m.Contains($ic.item)) { "  ok: $($ic.item) stays in c:$($ic.tag) without $($ic.label)" }
  else { $dependence++; "  FAIL: $($ic.item) reaches c:$($ic.tag) only while $($ic.label) is installed" }
}
""
# --- COST FLOOR ------------------------------------------------------------------------
# The rule itself is in tools/CostFloor.ps1, the numbers in tools/cost-floors.json - the
# same ones GenerateBridges.ps1 derives the data from. This check is independent of the
# generator in what it walks: every resolved Pantrywork path, hand-authored refs and
# upstream chains through our entries included.
"=== COST FLOOR (tolerance $($costData.tolerance)x; every Pantrywork path into a judged tag) ==="
$costFail = 0; $costGatedOk = 0; $costChecked = 0
$costLines = New-Object System.Collections.ArrayList
foreach ($p in $overlayProblems) { $costFail++; [void]$costLines.Add("  FAIL overlay: $p") }
foreach ($p in $costData.problems) { $costFail++; [void]$costLines.Add("  FAIL data: $p") }
# every tag Pantrywork writes an entry into must be known to cost-floors.json (judged or moot);
# the pantrywork:bridged/* and pantrywork:gated/* containers are judged at the tag that reads them
$pwTagIds = @($tags.Keys | Where-Object { @($tags[$_] | Where-Object { $_.src -eq 'pantrywork' }).Count } | ForEach-Object { TagId $_ } | Where-Object { $_ -notlike 'pantrywork:bridged/*' -and $_ -notlike 'pantrywork:gated/*' } | Sort-Object)
foreach ($tid in $pwTagIds) { if (-not $costData.tags.ContainsKey($tid)) { $costFail++; [void]$costLines.Add("  FAIL: Pantrywork writes into $tid, which cost-floors.json does not judge or mark moot") } }
foreach ($tid in ($costData.tags.Keys | Sort-Object)) {
  $t = $costData.tags[$tid]
  if ($t.moot) { continue }
  $mods = if ($definers.ContainsKey($tid)) { @($definers[$tid]) } else { @() }
  foreach ($p in (Test-DefinerCoverage $costData $tid $mods)) { $costFail++; [void]$costLines.Add("  FAIL stale floors: $p") }
  if (-not $Minimal) {
    $fd = if ($floorDefiners.ContainsKey($tid)) { @($floorDefiners[$tid]) } else { @() }
    foreach ($p in (Test-FloorDefiners $costData $tid $fd)) { $costFail++; [void]$costLines.Add("  FAIL fictional floor: $p") }
  }
  $key = if ($tid.StartsWith('c:')) { $tid.Substring(2) } else { $tid }
  if (-not $tags.ContainsKey($key)) { continue }
  $paths = Get-PwPaths $key
  foreach ($x in ($paths.Keys | Sort-Object)) {
    $costChecked++
    $v = Get-CostVerdict $costData $tid $x
    switch ($v.verdict) {
      'PASS' { }
      'EXCLUDE' { $costFail++; [void]$costLines.Add("  FAIL EXCLUDE: Pantrywork routes $x into $tid ($(Format-Path $paths[$x][0])) : $($v.detail)") }
      'GATE' {
        $bad = @($paths[$x] | Where-Object { -not (Test-PathSatisfies $_ $v.gates) })
        if ($bad.Count) { $costFail++; [void]$costLines.Add("  FAIL UNGATED: $x into $tid needs $($v.gates -join ' or ') but a Pantrywork path is unconditional ($(Format-Path $bad[0])) : $($v.detail)") }
        else { $costGatedOk++ }
      }
      default { $costFail++; [void]$costLines.Add("  FAIL $($v.verdict): $($v.detail)") }
    }
  }
}
$costLines | Sort-Object -Unique
if ($costFail -eq 0) { "  ok: $costChecked Pantrywork (tag, item) routes judged; $costGatedOk GATE verdicts proven conditional on a rescuing mod on every path" }
""
"=== REQUIRED-BUT-UNDEFINED TAG REFERENCES / REQUIRED FOREIGN ITEMS ==="
if ($missingRequired.Count -eq 0) { "  none" } else { $missingRequired | Sort-Object -Unique | ForEach-Object { "  $_" } }
""
"seed/sapling violations : $violations"
"missing required refs   : $(($missingRequired | Sort-Object -Unique).Count)"
"shim containment leaks   : $shimLeak"
"non-food via Pantrywork  : $nonFoodFail"
"dilution via Pantrywork  : $dilution"
"third-mod dependence     : $dependence"
"cost-floor failures      : $costFail"
if ($violations -gt 0 -or $missingRequired.Count -gt 0 -or $shimLeak -gt 0 -or $nonFoodFail -gt 0 -or $dilution -gt 0 -or $dependence -gt 0 -or $costFail -gt 0) { exit 1 } else { exit 0 }
