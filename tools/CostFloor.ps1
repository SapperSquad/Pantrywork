# CostFloor.ps1 - the cost-floor rule, shared by GenerateBridges.ps1 and AuditRoles.ps1.
# Dot-source it:  . (Join-Path $PSScriptRoot 'CostFloor.ps1')
#
# The DATA lives in tools/cost-floors.json (item costs, per-tag floors per defining mod).
# This file only holds the rule, so the generator (which writes the tags) and the audit
# (which walks every resolved path, hand-authored refs included) can never disagree on it.
#
# THE RULE (SapperSquad, 2026-09-13: "apply the cost floor strictly, everywhere"):
#   cost(X)    cheapest route to make X, in the base unit of its category, counting yields,
#              containers not returned and side ingredients (see cost-floors.json "conventions").
#   floor(M,T) cheapest item defining mod M itself lists in tag T (directly or via its own refs).
#   An injected item X may be up to TOLERANCE (1.5x) cheaper than a floor.
#   Judged per defining mod, not on the union:
#     PASS     within tolerance of every defining mod's floor
#     GATE     too cheap for some defining mods, but some rescuer N (floor(N,T) <= 1.5 x cost(X))
#              exists: emit only while any rescuer is loaded (N's own recipes already accept an
#              equally cheap item upstream, so nothing new is diluted)
#     EXCLUDE  too cheap and no defining mod rescues it
#   Two gates are always satisfied and therefore PASS:
#     self-rescue        X's own mod is a rescuer (X only exists while that mod is loaded)
#     dependency-rescue  a rescuer is a hard dependency of X's mod ("dependencies" in the data)
#     platform           the platform convention tags ("neoforge" key) are a rescuer

function ConvertTo-CostNumber($v) {
  if ($null -eq $v) { return $null }
  if ($v -is [string]) {
    if ($v -match '^\s*([0-9.]+)\s*/\s*([0-9.]+)\s*$') { return [double]$matches[1] / [double]$matches[2] }
    return [double]$v
  }
  return [double]$v
}

function Format-Cost([double]$c) {
  if ($c -eq 0) { return '0' }
  foreach ($d in 2, 3, 4, 6, 8, 9, 12, 14, 16) {
    $n = $c * $d
    if ([math]::Abs($n - [math]::Round($n)) -lt 1e-9 -and [math]::Round($n) -ne $d -and $c -lt 1) { return "$([math]::Round($n))/$d" }
  }
  return ('{0:0.###}' -f $c)
}

# Parses cost-floors.json into plain hashtables. Fails loudly on internal inconsistency
# (an item listed with a unit other than the tag's, a floor item with no cost).
function Read-CostData($root) {
  $path = Join-Path $root 'tools\cost-floors.json'
  $j = ConvertFrom-Json ([IO.File]::ReadAllText($path))
  $data = @{ tolerance = [double]$j.tolerance; items = @{}; tags = @{}; dependencies = @{}; aliases = @{}; problems = New-Object System.Collections.ArrayList }
  if ($j.modAliases) {
    foreach ($p in $j.modAliases.PSObject.Properties) {
      if (@('fabric', 'neoforge', 'any') -notcontains $p.Value.loader) { [void]$data.problems.Add("modAliases.$($p.Name): loader must be fabric, neoforge or any") }
      $data.aliases[$p.Name] = @{ as = $p.Value.as; loader = $p.Value.loader; why = $p.Value.why }
    }
  }
  foreach ($p in $j.items.PSObject.Properties) {
    $data.items[$p.Name] = @{ cost = (ConvertTo-CostNumber $p.Value.cost); unit = $p.Value.unit; why = $p.Value.why }
  }
  foreach ($p in $j.dependencies.PSObject.Properties) { $data.dependencies[$p.Name] = @($p.Value) }
  foreach ($p in $j.tags.PSObject.Properties) {
    $t = $p.Value
    $entry = @{ id = $p.Name; unit = $t.unit; moot = $t.moot; floors = [ordered]@{}; default = (ConvertTo-CostNumber $t.default); note = $t.note; nofloor = @{} }
    if ($t.floors) {
      foreach ($f in $t.floors.PSObject.Properties) {
        $v = $f.Value
        if ($v -is [string]) { $entry.floors[$f.Name] = @{ item = $v; cost = $null; why = $null } }
        elseif ($null -ne $v.none) { $entry.nofloor[$f.Name] = $v.none }
        else { $entry.floors[$f.Name] = @{ item = $v.item; cost = (ConvertTo-CostNumber $v.cost); why = $v.why; unscanned = $v.unscanned } }
      }
    }
    $data.tags[$p.Name] = $entry
  }
  # resolve floor costs and check units
  foreach ($t in $data.tags.Values) {
    if ($t.moot) { continue }
    if (-not $t.unit) { [void]$data.problems.Add("$($t.id): judged tag has no unit"); continue }
    foreach ($m in @($t.floors.Keys)) {
      $f = $t.floors[$m]
      if ($null -eq $f.cost) {
        $c = Get-ItemCost $data $t $f.item
        if ($null -eq $c) { [void]$data.problems.Add("$($t.id): floor item $($f.item) (for $m) has no cost and the tag has no default") }
        $f.cost = $c
      }
    }
    if ($t.floors.Count -eq 0) { [void]$data.problems.Add("$($t.id): judged tag declares no floors") }
  }
  return $data
}

# cost of an item inside a judged tag: its own entry (unit must match), else the tag default
function Get-ItemCost($data, $tag, $itemId) {
  if ($data.items.ContainsKey($itemId)) {
    $it = $data.items[$itemId]
    if ($it.unit -ne $tag.unit) {
      if ($null -ne $tag.default) { return $null }   # a costed item of another unit in a produce tag: unknown, never silently defaulted
      return $null
    }
    return $it.cost
  }
  return $tag.default
}

# Verdict for one (tag, item). Returns a hashtable:
#   verdict  PASS | GATE | EXCLUDE | MOOT | UNJUDGED | UNKNOWN
#   gates    rescuer mod ids (GATE only), sorted
#   detail   one-line explanation with every floor ratio (floor / cost)
function Get-CostVerdict($data, [string]$tagId, [string]$itemId) {
  if (-not $data.tags.ContainsKey($tagId)) { return @{ verdict = 'UNJUDGED'; gates = @(); detail = "$tagId has no entry in cost-floors.json" } }
  $t = $data.tags[$tagId]
  if ($t.moot) { return @{ verdict = 'MOOT'; gates = @(); detail = "moot: $($t.moot)" } }
  $cost = Get-ItemCost $data $t $itemId
  if ($null -eq $cost) {
    $why = if ($data.items.ContainsKey($itemId)) { "costed in unit '$($data.items[$itemId].unit)', tag unit is '$($t.unit)'" } else { "no cost entry and $tagId has no default" }
    return @{ verdict = 'UNKNOWN'; gates = @(); detail = "$itemId in ${tagId}: $why" }
  }
  $tol = $data.tolerance
  $ok = New-Object System.Collections.ArrayList; $bad = New-Object System.Collections.ArrayList; $parts = @()
  foreach ($m in $t.floors.Keys) {
    $fc = $t.floors[$m].cost
    $pass = ($fc -le $tol * $cost + 1e-9)
    $ratio = if ($cost -eq 0) { if ($fc -eq 0) { '1.00' } else { 'inf' } } else { '{0:0.00}' -f ($fc / $cost) }
    $parts += "$m $(Format-Cost $fc) (x$ratio $(if ($pass) {'ok'} else {'FAIL'}))"
    if ($pass) { [void]$ok.Add($m) } else { [void]$bad.Add($m) }
  }
  $detail = "cost $(Format-Cost $cost) $($t.unit); floors: $($parts -join ', ')"
  if ($bad.Count -eq 0) { return @{ verdict = 'PASS'; gates = @(); detail = $detail } }
  if ($ok.Count -eq 0) { return @{ verdict = 'EXCLUDE'; gates = @(); detail = $detail } }
  $ns = ($itemId -split ':')[0]
  if ($ok -contains 'neoforge') { return @{ verdict = 'PASS'; gates = @(); detail = "$detail; platform floor rescues" } }
  if ($ok -contains $ns) { return @{ verdict = 'PASS'; gates = @(); detail = "$detail; self-rescued ($ns is a rescuer and $itemId exists only with it)" } }
  if ($data.dependencies.ContainsKey($ns)) {
    $dep = @($data.dependencies[$ns] | Where-Object { $ok -contains $_ })
    if ($dep.Count) { return @{ verdict = 'PASS'; gates = @(); detail = "$detail; dependency-rescued ($ns requires $($dep -join ', '))" } }
  }
  return @{ verdict = 'GATE'; gates = @($ok | Sort-Object); detail = $detail }
}

# Every jar that defines a judged tag must be declared in its floors (or as {"none": why}).
# A defining mod the data does not know about means the floors are stale - fail, don't guess.
function Test-DefinerCoverage($data, [string]$tagId, $definerMods) {
  $problems = @()
  if (-not $data.tags.ContainsKey($tagId)) { return $problems }
  $t = $data.tags[$tagId]
  if ($t.moot) { return $problems }
  foreach ($m in ($definerMods | Sort-Object -Unique)) {
    if (-not $t.floors.Contains($m) -and -not $t.nofloor.ContainsKey($m)) {
      $problems += "${tagId}: defined by '$m' in a scanned jar, but cost-floors.json declares no floor for it"
    }
  }
  return $problems
}

# Every DECLARED floor must belong to a mod that some scanned jar shows defining the tag. A floor
# for a mod that defines the tag in no scanned jar is fictional, and it is worse than stale: the
# self-rescue rule turns it into a free PASS for that mod's own items. That is exactly how
# Farmer's Delight's 1/4 bottle stayed in c:foods/milk through the first cost-floor pass (no
# scanned FD jar for a line with a reader of the tag defined it). A deliberate exception must
# say why in an "unscanned" field on the floor entry.
function Test-FloorDefiners($data, [string]$tagId, $definerMods) {
  $problems = @()
  if (-not $data.tags.ContainsKey($tagId)) { return $problems }
  $t = $data.tags[$tagId]
  if ($t.moot) { return $problems }
  foreach ($m in $t.floors.Keys) {
    if (@($definerMods) -contains $m) { continue }
    if ($t.floors[$m].unscanned) { continue }
    $problems += "${tagId}: declares a floor for '$m', but no scanned jar of '$m' defines the tag (a floor nobody defines rescues that mod's items for free); remove it, or give the floor an ""unscanned"" reason"
  }
  return $problems
}

# Mod-id aliases ("modAliases" in cost-floors.json): a build of a mod published under another id
# on one loader (Croptopia Refabricated = croptopia-refabricated on Fabric 1.21.10, same recipes and
# tags as croptopia). Floors, definers and gates use the canonical id; a gate's overlay CONDITION
# must name every alias for that loader, or the overlay never opens there.
function Resolve-ModAlias($data, [string]$modId) {
  if ($data.aliases.ContainsKey($modId)) { return $data.aliases[$modId].as }
  return $modId
}
function Get-LoaderModIds($data, $mods, [string]$loader) {
  $out = New-Object System.Collections.ArrayList
  foreach ($m in @($mods)) {
    if (-not $out.Contains($m)) { [void]$out.Add($m) }
    foreach ($a in ($data.aliases.Keys | Sort-Object)) {
      $al = $data.aliases[$a]
      if ($al.as -eq $m -and ($al.loader -eq $loader -or $al.loader -eq 'any') -and -not $out.Contains($a)) { [void]$out.Add($a) }
    }
  }
  return @($out)
}

# Gate key / overlay directory naming (shared so the audit can parse what the generator wrote)
function Get-GateKey($gates) { return (($gates | Sort-Object) -join '_or_') }

# modId of a jar: the FIRST [[mods]] entry of META-INF/neoforge.mods.toml, or fabric.mod.json "id".
# Dependency blocks also carry modId= lines, so only [[mods]] sections count.
function Get-JarModIds($zip) {
  $ids = @()
  foreach ($e in $zip.Entries) {
    if ($e.FullName -eq 'META-INF/neoforge.mods.toml') {
      $r = New-Object IO.StreamReader($e.Open()); $txt = $r.ReadToEnd(); $r.Close()
      $section = ''
      foreach ($line in ($txt -split "`n")) {
        $l = $line.Trim()
        if ($l -match '^\[\[?([^\]]+)\]\]?') { $section = $matches[1].Trim(); continue }
        if ($section -eq 'mods' -and $l -match '^modId\s*=\s*"([^"]+)"') { $ids += $matches[1] }
      }
    }
    elseif ($e.FullName -eq 'fabric.mod.json') {
      $r = New-Object IO.StreamReader($e.Open()); $txt = $r.ReadToEnd(); $r.Close()
      try { $ids += (ConvertFrom-Json $txt).id } catch { }
    }
  }
  return @($ids | Select-Object -Unique)
}
