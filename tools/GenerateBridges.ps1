# GenerateBridges.ps1 — reverse-bridge generator.
#
# Forward bridging (canonical c:foods/* tags absorbing dialect tags) is
# hand-authored in src/main/resources as optional TAG references. This
# script handles the reverse direction, which must be ITEM-level entries
# to avoid tag reference cycles: for each category, every mod's dialect
# tag gains the other sources' member items as optional entries, so e.g.
# a Croptopia recipe requiring #c:cheeses accepts Pam's cheese.
#
# Output: src/generated/resources/data/c/tags/item/<dialect>.json
# Report: tools/work/bridges-report.txt
# Rerun whenever a compat jar in tools/work/jars changes.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Split-Path $PSScriptRoot -Parent
$jarsDir = Join-Path $root "tools\work\jars"
$outDir = Join-Path $root "src\generated\resources\data\c\tags\item"
$reportFile = Join-Path $root "tools\work\bridges-report.txt"

# --- gather every c: item-tag definition from all sources ---
$tagEntries = @{}   # tagPath -> [System.Collections.ArrayList] of entry ids (strings, '#'-prefixed for tag refs)
function Add-TagFile($tagPath, $json) {
  $parsed = ConvertFrom-Json $json
  if (-not $tagEntries.ContainsKey($tagPath)) { $tagEntries[$tagPath] = New-Object System.Collections.ArrayList }
  foreach ($v in $parsed.values) {
    $id = if ($v -is [string]) { $v } else { $v.id }
    [void]$tagEntries[$tagPath].Add($id)
  }
}
$neoforgeJar = Get-ChildItem "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\net.neoforged\neoforge\21.1.241" -Recurse -Filter "neoforge-21.1.241-universal.jar" | Select-Object -First 1 -ExpandProperty FullName
$sources = @($neoforgeJar) + (Get-ChildItem $jarsDir -Filter "*.jar" | ForEach-Object FullName)
foreach ($jar in $sources) {
  $zip = [IO.Compression.ZipFile]::OpenRead($jar)
  foreach ($e in ($zip.Entries | Where-Object { $_.FullName -match '^data/c/tags/item/.+\.json$' })) {
    $r = New-Object IO.StreamReader($e.Open()); $json = $r.ReadToEnd(); $r.Close()
    Add-TagFile ($e.FullName -replace '^data/c/tags/item/','' -replace '\.json$','') $json
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
      if ($ref.StartsWith('c:')) {
        foreach ($i in (Resolve-Tag ($ref.Substring(2)) $visited)) { [void]$items.Add($i) }
      } # non-c: tag refs (mod-namespace tags) aren't indexed here; skip
    } else {
      [void]$items.Add($id)
    }
  }
  return ,$items
}

# Never injected anywhere: items the target mods plausibly excluded on
# purpose (poison food, golden-tier items). Principle: bridges widen
# ingredient pools, they don't re-litigate another mod's exclusions.
$blacklist = @('minecraft:pufferfish', 'minecraft:golden_apple',
               'minecraft:enchanted_golden_apple', 'minecraft:golden_carrot')

# --- categories: dialect tags that mean the same thing.
# 'emit' lists the tags that receive injections (dialect tags only —
# canonical c:foods/* tags already absorb dialects via forward refs).
$categories = @(
  @{ name='cheese';         tags=@('cheeses','cheese','foods/cheese');                emit=@('cheeses','cheese') },
  @{ name='dough';          tags=@('doughs','dough','foods/dough');                   emit=@('doughs','dough') },
  @{ name='butter';         tags=@('butters','butter','foods/butter');                emit=@('butters','butter') },
  @{ name='milk';           tags=@('milks','milk','drinks/milk');                     emit=@('milks','milk') },
  @{ name='salt';           tags=@('salts','salt');                                   emit=@('salts','salt') },
  @{ name='oil';            tags=@('olive_oils','cookingoil');                        emit=@('olive_oils','cookingoil') },
  @{ name='stock';          tags=@('stock');  extra=@('farmersdelight:bone_broth');   emit=@('stock') },
  @{ name='pasta';          tags=@('pasta','foods/pasta');                            emit=@('pasta') },
  @{ name='raw_pork';       tags=@('rawpork','foods/raw_pork');                       emit=@('rawpork') },
  @{ name='raw_beef';       tags=@('rawbeef','beef_replacements','foods/raw_beef');   emit=@('rawbeef','beef_replacements') },
  @{ name='raw_chicken';    tags=@('rawchicken','chicken_replacements','foods/raw_chicken'); emit=@('rawchicken','chicken_replacements') },
  @{ name='raw_mutton';     tags=@('rawmutton','foods/raw_mutton');                   emit=@('rawmutton') },
  @{ name='cooked_pork';    tags=@('cookedpork','foods/cooked_pork');                 emit=@('cookedpork') },
  @{ name='cooked_beef';    tags=@('cookedbeef','foods/cooked_beef');                 emit=@('cookedbeef') },
  @{ name='cooked_chicken'; tags=@('cookedchicken','foods/cooked_chicken');           emit=@('cookedchicken') },
  @{ name='cooked_mutton';  tags=@('cookedmutton','foods/cooked_mutton');             emit=@('cookedmutton') },
  @{ name='raw_fish';       tags=@('rawfish','fishes','foods/raw_fish');              emit=@('rawfish','fishes') },
  @{ name='cooked_fish';    tags=@('cookedfish','foods/cooked_fish');                 emit=@('cookedfish') },
  @{ name='tomato';         tags=@('tomatoes','foods/tomato');                        emit=@('tomatoes') },
  @{ name='onion';          tags=@('onions','foods/onion');                           emit=@('onions') },
  @{ name='cabbage';        tags=@('cabbage','foods/cabbage');                        emit=@('cabbage') },
  @{ name='rice_grain';     tags=@('rice','crops/rice');                              emit=@('rice') },
  @{ name='vegetables';     tags=@('vegetables','foods/vegetable');                   emit=@('vegetables') },
  @{ name='fruits';         tags=@('fruits','foods/fruit');                           emit=@('fruits') }
)

if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Force $outDir | Out-Null
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$report = New-Object Text.StringBuilder
$filesWritten = 0
foreach ($cat in $categories) {
  $union = New-Object System.Collections.Generic.HashSet[string]
  foreach ($t in $cat.tags) {
    foreach ($i in (Resolve-Tag $t (New-Object System.Collections.Generic.HashSet[string]))) { [void]$union.Add($i) }
  }
  if ($cat.extra) { foreach ($i in $cat.extra) { [void]$union.Add($i) } }
  foreach ($b in $blacklist) { [void]$union.Remove($b) }
  [void]$report.AppendLine("[$($cat.name)] union: $(($union | Sort-Object) -join ', ')")
  foreach ($t in $cat.emit) {
    if (-not $tagEntries.ContainsKey($t)) { [void]$report.AppendLine("  $t : tag not defined by any source, skipped"); continue }
    $own = Resolve-Tag $t (New-Object System.Collections.Generic.HashSet[string])
    $inject = $union | Where-Object { -not $own.Contains($_) } | Sort-Object
    if (-not $inject) { [void]$report.AppendLine("  c:$t : nothing to inject"); continue }
    $entries = ($inject | ForEach-Object { "    { ""id"": ""$_"", ""required"": false }" }) -join ",`n"
    $file = Join-Path $outDir ($t -replace '/','\')
    New-Item -ItemType Directory -Force (Split-Path "$file.json") | Out-Null
    [IO.File]::WriteAllText("$file.json", "{`n  ""values"": [`n$entries`n  ]`n}`n", $utf8NoBom)
    $filesWritten++
    [void]$report.AppendLine("  c:$t += $($inject -join ', ')")
  }
  [void]$report.AppendLine("")
}
[IO.File]::WriteAllText($reportFile, $report.ToString(), $utf8NoBom)
"Wrote $filesWritten bridge files to $outDir"
"Report: $reportFile"
