# AuditRoles.ps1 - ground-truth audit of what the role tags actually resolve to.
#
# Loads every item tag definition visible at runtime (NeoForge jar + every compat
# jar in tools/work/jars + Pantrywork's own hand-authored and generated data),
# resolves each pantrywork:food_component/* tag transitively, and reports:
#   1. any member that violates the "seeds never cross a bridge" invariant
#   2. any tag reference that is REQUIRED but defined by nobody (a hard datapack
#      load failure for whoever is missing it)
#
# Exits nonzero when either check fails, so it can gate a release.
# Run:  powershell -File tools\AuditRoles.ps1
#
# -Minimal simulates the worst-case install: Pantrywork ALONE, with no compat
# mods and no platform convention tags (i.e. Fabric without Fabric API, which
# the README explicitly invites). Any cross-mod/convention tag reference we mark
# REQUIRED is undefined there, and a required reference to an undefined tag is a
# hard datapack load failure - a world that will not load. Run both modes.
param([switch]$Minimal)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Split-Path $PSScriptRoot -Parent
$jarsDir = Join-Path $root "tools\work\jars"

# tagKey -> list of entries; entry = @{ id=<string>; required=<bool> }
$tags = @{}
function Add-TagJson($key, $json) {
  if (-not $tags.ContainsKey($key)) { $tags[$key] = New-Object System.Collections.ArrayList }
  $parsed = ConvertFrom-Json $json
  foreach ($v in $parsed.values) {
    if ($v -is [string]) { [void]$tags[$key].Add(@{ id = $v; required = $true }) }
    else {
      $req = $true
      if ($null -ne $v.required) { $req = [bool]$v.required }
      [void]$tags[$key].Add(@{ id = $v.id; required = $req })
    }
  }
}
function Key($ns, $path) { if ($ns -eq 'c') { return $path } else { return "${ns}:$path" } }

$neoJar = Get-ChildItem "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\net.neoforged\neoforge" -Recurse -Filter "neoforge-*-universal.jar" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
$sources = @()
if (-not $Minimal) {
  if ($neoJar) { $sources += $neoJar }
  if (Test-Path $jarsDir) { $sources += (Get-ChildItem $jarsDir -Filter "*.jar" | ForEach-Object FullName) }
}
foreach ($jar in $sources) {
  $zip = [IO.Compression.ZipFile]::OpenRead($jar)
  foreach ($e in ($zip.Entries | Where-Object { ($_.FullName -replace '[/]','/') -match '/tags/item/' })) {
    $ns = ($e.FullName -split '/')[1]
    $r = New-Object IO.StreamReader($e.Open()); $j = $r.ReadToEnd(); $r.Close()
    $path = $e.FullName -replace "^data/$ns/tags/item/",'' -replace '\.json$',''
    Add-TagJson (Key $ns $path) $j
  }
  $zip.Dispose()
}
# Pantrywork's own data (hand-authored + generated)
foreach ($dir in @("src\main\resources\data", "src\generated\resources\data")) {
  $full = Join-Path $root $dir
  if (-not (Test-Path $full)) { continue }
  Get-ChildItem $full -Recurse -Filter "*.json" | Where-Object { $_.FullName.Replace([char]92, [char]47) -match '/tags/item/' } | ForEach-Object {
    $rel = $_.FullName.Substring($full.Length + 1).Replace([char]92, [char]47)
    if ($rel -match '^([^/]+)/tags/item/(.+)\.json$') { Add-TagJson (Key $matches[1] $matches[2]) ([IO.File]::ReadAllText($_.FullName)) }
  }
}

$definedBy = @{}   # which keys exist at all
foreach ($k in $tags.Keys) { $definedBy[$k] = $true }

$missingRequired = New-Object System.Collections.ArrayList
function Resolve-Members($key, $visited) {
  $items = New-Object System.Collections.Generic.HashSet[string]
  if ($visited.Contains($key) -or -not $tags.ContainsKey($key)) { return ,$items }
  [void]$visited.Add($key)
  foreach ($entry in $tags[$key]) {
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
      [void]$items.Add($id)
    }
  }
  return ,$items
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
"=== PANTRYWORK TAG AUDIT ($($roles.Count) tags asserted by this mod) ==="
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
#   - never widened past FD's own last definition {milk_bucket, milk_bottle}; a
#     nested #c:drinks/milk ref would drag in six items including croptopia's
#     16-per-bucket milk_bottle and cowless soy_milk
"=== c:foods/milk SHIM CONTAINMENT ==="
$shimLeak = 0
if ($tags.ContainsKey('foods/milk')) {
    $shimMembers = Resolve-Members 'foods/milk' (New-Object System.Collections.Generic.HashSet[string])
    $allowed = @('minecraft:milk_bucket', 'farmersdelight:milk_bottle')
    $extra = @($shimMembers | Where-Object { $allowed -notcontains $_ } | Sort-Object)
    "  c:foods/milk members: $(($shimMembers | Sort-Object) -join ', ')"
    if ($extra.Count) { $shimLeak += $extra.Count; "  WIDENED BEYOND FD'S DEFINITION: $($extra -join ', ')" }
    foreach ($parent in @('foods')) {
        if ((Resolve-Members $parent (New-Object System.Collections.Generic.HashSet[string])) -contains 'minecraft:milk_bucket') {
            $shimLeak++; "  LEAK: milk is reachable from #c:$parent"
        }
    }
    foreach ($rt in @($tags.Keys | Where-Object { $_ -like 'pantrywork:food_component*' })) {
        $rm = Resolve-Members $rt (New-Object System.Collections.Generic.HashSet[string])
        # dairy/liquid_base legitimately contain milk_bucket via c:buckets/milk;
        # the leak we care about is a path THROUGH the shim tag itself.
        if ($tags[$rt] | Where-Object { $_.id -eq '#c:foods/milk' }) { $shimLeak++; "  LEAK: $rt references #c:foods/milk directly" }
    }
    if ($shimLeak -eq 0) { "  contained: not joined to #c:foods, not referenced by any role tag, not widened" }
} else { "  (shim not present)" }
""
"=== REQUIRED-BUT-UNDEFINED TAG REFERENCES ==="
if ($missingRequired.Count -eq 0) { "  none" } else { $missingRequired | Sort-Object -Unique | ForEach-Object { "  $_" } }
""
"seed/sapling violations : $violations"
"missing required refs   : $(($missingRequired | Sort-Object -Unique).Count)"
"shim containment leaks   : $shimLeak"
if ($violations -gt 0 -or $missingRequired.Count -gt 0 -or $shimLeak -gt 0) { exit 1 } else { exit 0 }
