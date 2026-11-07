# boot-forge1201.ps1 - boot the Forge 1.20.1 harness and run a suite against it.
#
#   powershell -File tools\boot-forge1201.ps1 -Scenario solo
#   powershell -File tools\boot-forge1201.ps1 -Scenario compat
#   powershell -File tools\boot-forge1201.ps1 -Scenario control   # compat set, Pantrywork removed
#
# Why this harness needs a script when the NeoForge/Fabric ones are hand-booted:
#   - Forge 1.20.1 is javafml 47 and will not start on the machine's default JDK 26. It needs
#     JDK 21 passed explicitly (1.20.1 is nominally a Java 17 line; 21 is what is installed here
#     and boots clean).
#   - Forge takes its classpath from an @argfile under libraries/, not from a single server jar.
#   - 1.20.1 has no `execute if items` and no minecraft:crafter, so tag membership is asserted
#     through predicates that have to be copied into world/datapacks before the world loads
#     (tools/testpack-1201). Forgetting that copy makes every probe answer nothing, which reads
#     as 300+ failures - so the copy belongs in the script, not in a checklist.
#
# Always boots a FRESH world with the logs cleared, per the house rule for every release boot.
param(
  [Parameter(Mandatory)][ValidateSet('solo', 'compat', 'control')][string]$Scenario,
  [string]$Suite,
  [string]$Jdk = 'C:\Program Files\Java\jdk-21.0.11',
  [int]$BootTimeoutSec = 180,
  [switch]$KeepRunning
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$srv = Join-Path $root 'tools\forge-server-1201'
$jars = Join-Path $root 'tools\work\jars-1201'
$forgeArgs = 'libraries\net\minecraftforge\forge\1.20.1-47.4.28\win_args.txt'
$java = Join-Path $Jdk 'bin\java.exe'
if (-not (Test-Path $java)) { throw "JDK not found at $Jdk (pass -Jdk)" }
if (-not (Test-Path (Join-Path $srv $forgeArgs))) {
  throw "Forge is not installed in $srv. Run the installer first:`n" +
        "  java -jar forge-1.20.1-47.4.28-installer.jar --installServer `"$srv`""
}

# The 18 roster jars that actually load on Forge 1.20.1. Everything excluded is excluded for a
# measured reason - see tools/work/jars-1201/SOURCES.md.
$compatJars = @(
  'FarmersDelight-1.20.1-1.3.4.jar', 'BrewinAndChewin-1.20.1-3.2.1.jar', 'cookscollection-0.6.1.jar',
  'culturaldelights-0.16.7.jar', 'ends_delight-2.6.1+forge.1.20.1.jar',
  'hearthandharvest-1.20.1-1.4.3.jar', 'oceansdelight-1.0.2-1.20.jar',
  'rusticdelight-forge-1.20.1-1.7.0.jar', 'kaleidoscopecookery-1.6.0-forge+mc1.20.1.jar',
  'pamhc2foodcore-1.20.4-1.0.5.jar', 'pamhc2foodextended-1.20.4-1.0.1.jar',
  'Aquaculture-1.20.1-2.5.7.jar', 'Croptopia-1.20.1-FORGE-4.0.1.jar',
  'EpheroLib-1.20.1-FORGE-1.2.0.jar', 'letsdo-farm_and_charm-forge-1.0.14.jar',
  'letsdo-meadow-forge-1.3.25.jar', 'letsdo-vinery-forge-1.4.41.jar',
  'architectury-9.2.14-forge.jar'
)

if (-not $Suite) {
  $Suite = switch ($Scenario) {
    'solo'    { 'tools\tagtest-forge1201.txt' }
    'compat'  { 'tools\tagtest-forge1201-compat.txt' }
    'control' { '' }
  }
}

# ---- refuse to run on top of a live server: the port tells the truth ----
if (Get-Process java -ErrorAction SilentlyContinue) {
  throw 'A java process is already running. Stop it (tools\rcon.ps1 -Command stop) first.'
}

# ---- mods/ ----
$mods = Join-Path $srv 'mods'
Remove-Item -Recurse -Force $mods -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $mods | Out-Null
$jar = Get-ChildItem (Join-Path $root 'build\libs') -Filter 'pantrywork-*-forge-mc1201.jar' |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $jar) { throw 'No pantrywork-*-forge-mc1201.jar in build\libs - run: gradlew forgeJar1201' }
if ($Scenario -ne 'control') { Copy-Item $jar.FullName $mods }
if ($Scenario -ne 'solo') {
  foreach ($f in $compatJars) {
    $p = Join-Path $jars $f
    if (-not (Test-Path $p)) { throw "Missing roster jar: $p (see jars-1201\SOURCES.md)" }
    Copy-Item $p $mods
  }
}

# ---- fresh world, logs cleared, probe pack in place BEFORE the world loads ----
Remove-Item -Recurse -Force (Join-Path $srv 'world'), (Join-Path $srv 'logs') -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force (Join-Path $srv 'world\datapacks') | Out-Null
Copy-Item -Recurse (Join-Path $root 'tools\testpack-1201') (Join-Path $srv 'world\datapacks\pwtest')
Set-Content (Join-Path $srv 'eula.txt') 'eula=true' -Encoding ascii

$sha = (Get-FileHash $jar.FullName -Algorithm SHA1).Hash.Substring(0, 8)
"scenario   : $Scenario"
"jar        : $($jar.Name)  sha1 $sha$(if ($Scenario -eq 'control') { '  (NOT installed - control boot)' })"
"mods/      : $((Get-ChildItem $mods).Count) files"
"jdk        : $Jdk"

# ---- boot ----
$log = Join-Path $srv "boot-$Scenario.out"
$p = Start-Process -FilePath $java -WorkingDirectory $srv -PassThru -NoNewWindow `
     -ArgumentList '@user_jvm_args.txt', "@$forgeArgs", 'nogui' `
     -RedirectStandardOutput $log -RedirectStandardError (Join-Path $srv "boot-$Scenario.err")
$deadline = (Get-Date).AddSeconds($BootTimeoutSec)
$up = $false
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 3
  if ($p.HasExited) { break }
  if ((Test-Path $log) -and (Select-String -Path $log -Pattern 'RCON running on' -Quiet)) { $up = $true; break }
}
if (-not $up) {
  "BOOT FAILED - last 20 lines of $log :"
  Get-Content $log -Tail 20
  exit 1
}
$done = (Select-String -Path $log -Pattern 'Done \(([0-9.]+)s\)' | Select-Object -First 1)
"boot       : up ($($done.Matches[0].Groups[1].Value)s)"

# ---- log scan: everything here is upstream and is proven so by -Scenario control ----
$cats = [ordered]@{
  'TagLoader missing-ref' = "Couldn't load tag"
  'recipe parse errors'   = 'Parsing error loading recipe'
  'empty data file'       = "Couldn't parse data file"
  'loot_tables elements'  = "Couldn't parse element loot_tables"
}
foreach ($k in $cats.Keys) {
  $n = @(Select-String -Path $log -Pattern ([regex]::Escape($cats[$k]))).Count
  "  {0,-22}: {1}" -f $k, $n
}
$ours = @(Select-String -Path $log -Pattern 'pantrywork' |
          Where-Object { $_.Line -match 'ERROR|FATAL' })
"  {0,-22}: {1}" -f 'error lines naming us', $ours.Count
if ($ours.Count) { $ours | ForEach-Object { "      $($_.Line)" } }

# ---- suite ----
if ($Suite) {
  $out = Join-Path $root ("run\forge1201-$Scenario.out")
  New-Item -ItemType Directory -Force (Join-Path $root 'run') | Out-Null
  & powershell -ExecutionPolicy Bypass -File (Join-Path $root 'tools\rcon.ps1') -File (Join-Path $root $Suite) |
    Out-File -Encoding utf8 $out
  & powershell -ExecutionPolicy Bypass -File (Join-Path $root 'tools\CountSuite.ps1') -Suite (Join-Path $root $Suite) -Output $out
  $suiteExit = $LASTEXITCODE
} else {
  "suite      : none for this scenario"
  $suiteExit = 0
}

if (-not $KeepRunning) {
  & powershell -ExecutionPolicy Bypass -File (Join-Path $root 'tools\rcon.ps1') -Command 'stop' | Out-Null
  for ($i = 0; $i -lt 20 -and -not $p.HasExited; $i++) { Start-Sleep -Seconds 1 }
  "stopped    : java exited = $($p.HasExited)"
}
exit $suiteExit
