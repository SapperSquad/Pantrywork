# Publish Pantrywork release jars to Modrinth and CurseForge via their APIs.
# Adapted from ReelRivals/tools/publish.ps1 (same HttpClient approach and the
# same CurseForge version-type guardrails). ASCII only - PS 5.1 reads BOM-less
# scripts as ANSI.
#
# ONE-TIME SETUP:
#   1. Create the Modrinth project by hand (suggested slug: pantrywork), then set:
#        setx MODRINTH_PROJECT_ID "xxxxxxxx"   # base62 id from the project page/API, NOT the slug
#        setx MODRINTH_TOKEN "mrp_xxxxxxxx"
#   2. CurseForge (optional at first launch, Modrinth-only is fine):
#        setx CURSEFORGE_PROJECT_ID "123456"   # numeric, from About Project sidebar
#        setx CURSEFORGE_TOKEN "xxxxxxxx"
#   Open a NEW terminal after setx.
#
# USAGE (stage dist\<version>\ first - see PUBLISHING.md):
#   powershell -File tools\publish.ps1 -Version 0.1.0 -ChangelogFile tools\changelog-current.md -DryRun
#   powershell -File tools\publish.ps1 -Version 0.1.0 -ChangelogFile tools\changelog-current.md
#
# ONE-FILE RELEASES: -Only filters the file list, so a release that adds a single
# artifact does not warn four times about jars that were deliberately not built.
# 0.10.0 is exactly that - the Forge 1.20.1 file, with the four 1.21.1/26.x files
# left live at 0.9.0:
#   powershell -File tools\publish.ps1 -Version 0.10.0 -ChangelogFile tools\changelog-current.md -Only forge -DryRun
# -Only matches the loader slug, the label or the jar name (wildcards allowed), and
# it fails loudly rather than silently publishing nothing if it matches no file.
#
# FORGE LEG, DRY-RUN VERIFIED 2026-11-06 (read-only GETs; -DryRun never reaches the
# upload POST). Both CurseForge ids resolve, so neither is a guess:
#   loader 'Forge' -> 7498   (distinct from NeoForge; the lookup is an exact name
#                             match under the 'modloader' version type, so the two
#                             cannot collide)
#   Minecraft '1.20.1' -> 9990      environment Client/Server -> 9638 / 9639
# Modrinth needs no lookup: loader slug 'forge', and the payload comes out as
# version_number '0.10.0+mc1.20.1-forge', loaders ['forge'], game_versions
# ['1.20.1'], dependencies [] - no Fabric API on this file, correctly.
# Re-run a -DryRun before the real publish anyway: CurseForge mints new ids over time
# and Get-CurseForgeVersionIdByType warns and skips rather than guessing.
#
# This performs REAL, PUBLIC uploads when run without -DryRun.

param(
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$ChangelogFile,
    [string]$ModrinthProjectId = "",
    [int]$CurseForgeProjectId = 0,
    [string[]]$Only = @(),
    [switch]$SkipModrinth,
    [switch]$SkipCurseForge,
    [switch]$SkipJarCheck,
    [switch]$DryRun
)
$ErrorActionPreference = "Stop"

# Pantrywork's own store ids, baked in on purpose. The MODRINTH_PROJECT_ID /
# CURSEFORGE_PROJECT_ID env vars are GLOBAL and shared by every mod on this
# machine, so whichever project published last owns them - at the 0.5.0 publish
# CURSEFORGE_PROJECT_ID had drifted to 1616194 (another project entirely) and
# all four uploads were aimed at the wrong mod. They failed only because that
# project rejects the NeoForge loader id; had it accepted, Pantrywork's jars
# would have landed on someone else's page. Ids verified 2026-08-29 against the
# live pages. Resolution order: explicit parameter > baked-in id > env var.
$PANTRYWORK_MODRINTH = 'rNg1wypx'
$PANTRYWORK_CURSEFORGE = 1617573
# Fabric API, required by both Fabric files (see the $files comment below)
$FABRIC_API_MODRINTH = 'P7dR8mSH'
$FABRIC_API_CURSEFORGE_SLUG = 'fabric-api'
if (-not $ModrinthProjectId) { $ModrinthProjectId = $PANTRYWORK_MODRINTH }
if ($CurseForgeProjectId -eq 0) { $CurseForgeProjectId = $PANTRYWORK_CURSEFORGE }
if ($env:MODRINTH_PROJECT_ID -and $env:MODRINTH_PROJECT_ID -ne $ModrinthProjectId) {
  Write-Warning "MODRINTH_PROJECT_ID env var is '$($env:MODRINTH_PROJECT_ID)' but this script targets '$ModrinthProjectId' - using the latter."
}
if ($env:CURSEFORGE_PROJECT_ID -and [int]$env:CURSEFORGE_PROJECT_ID -ne $CurseForgeProjectId) {
  Write-Warning "CURSEFORGE_PROJECT_ID env var is '$($env:CURSEFORGE_PROJECT_ID)' but this script targets '$CurseForgeProjectId' - using the latter."
}

$proj = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $proj ("dist\" + $Version)

if (-not (Test-Path $ChangelogFile)) { throw "Changelog file not found: $ChangelogFile" }
# [string] cast strips PSPath metadata that would corrupt ConvertTo-Json (see RR publish.ps1)
$changelog = [string](Get-Content $ChangelogFile -Raw -Encoding UTF8)

$ModrinthToken = $env:MODRINTH_TOKEN
$CurseForgeToken = $env:CURSEFORGE_TOKEN
if (-not $SkipModrinth -and -not $DryRun) {
    if (-not $ModrinthProjectId) { throw "Modrinth project id not set. Pass -ModrinthProjectId or setx MODRINTH_PROJECT_ID (base62 id, not the slug)." }
    if (-not $ModrinthToken) { throw "MODRINTH_TOKEN env var is not set. See the header of this script." }
}
if (-not $SkipCurseForge -and -not $DryRun -and $CurseForgeProjectId -ne 0 -and -not $CurseForgeToken) { throw "CURSEFORGE_TOKEN env var is not set." }

Add-Type -AssemblyName System.Net.Http

function Invoke-MultipartPost {
    param([string]$Uri, [hashtable]$Headers, [string]$JsonFieldName, [string]$JsonBody, [string]$FileFieldName, [string]$FilePath)
    $client = New-Object System.Net.Http.HttpClient
    try {
        foreach ($h in $Headers.GetEnumerator()) { $client.DefaultRequestHeaders.TryAddWithoutValidation($h.Key, $h.Value) | Out-Null }
        $content = New-Object System.Net.Http.MultipartFormDataContent
        $jsonContent = New-Object System.Net.Http.StringContent($JsonBody, [System.Text.Encoding]::UTF8, "application/json")
        $content.Add($jsonContent, $JsonFieldName)
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $fileContent = New-Object System.Net.Http.ByteArrayContent(, $fileBytes)
        $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/java-archive")
        $content.Add($fileContent, $FileFieldName, [System.IO.Path]::GetFileName($FilePath))
        $response = $client.PostAsync($Uri, $content).GetAwaiter().GetResult()
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) { throw "$Uri failed: $($response.StatusCode) - $body" }
        return $body
    } finally {
        $client.Dispose()
    }
}

$script:cfVersionCache = $null
$script:cfTypeCache = $null

function Get-CurseForgeApi {
    param([string]$Path, [string]$Token)
    $client = New-Object System.Net.Http.HttpClient
    try {
        $client.DefaultRequestHeaders.TryAddWithoutValidation("X-Api-Token", $Token) | Out-Null
        $resp = $client.GetAsync("https://minecraft.curseforge.com/api$Path").GetAwaiter().GetResult()
        $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $resp.IsSuccessStatusCode) { throw "GET $Path failed: $($resp.StatusCode) - $body" }
        return $body | ConvertFrom-Json
    } finally {
        $client.Dispose()
    }
}

function Get-CurseForgeVersionIdByType {
    param([string]$Name, [string]$TypeSlugPrefix, [string]$Token)
    if (-not $script:cfVersionCache) { $script:cfVersionCache = Get-CurseForgeApi -Path "/game/versions" -Token $Token }
    if (-not $script:cfTypeCache)    { $script:cfTypeCache    = Get-CurseForgeApi -Path "/game/version-types" -Token $Token }
    # Same guardrail as ReelRivals: a version string exists under several
    # gameVersionTypeIDs (Minecraft, Addons/Bukkit, unlisted). Restrict to the
    # intended type family instead of trusting response order.
    $typeIds = @($script:cfTypeCache | Where-Object { $_.slug -like ($TypeSlugPrefix + "*") } | ForEach-Object { $_.id })
    $all   = @($script:cfVersionCache | Where-Object { $_.name -eq $Name -or $_.slug -eq $Name })
    $valid = @($all | Where-Object { $typeIds -contains $_.gameVersionTypeID })
    if ($valid.Count -eq 0) {
        Write-Warning "'$Name' did not resolve under version-type '$TypeSlugPrefix*' on CurseForge."
        return $null
    }
    if ($valid.Count -gt 1) { Write-Warning "'$Name' matched several ids; using $($valid[0].id)." }
    return $valid[0].id
}

# The five release artifacts and the Minecraft versions each is tagged with on the
# stores. The versions actually booted are in PUBLISHING.md's verification log: the
# Fabric 1.21.x file was booted on 1.21.1, 1.21.10 and 1.21.11, and 1.21.2-1.21.9 are
# tagged from its declared range (>=1.21.1 <1.22). Both Fabric files are sent with
# Fabric API as a required dependency, and both jars' fabric.mod.json declare
# "fabric-api": "*" (Fabric API's resource loader is what loads mod data; without it
# Fabric Loader refuses to start and names the missing dependency - booted 2026-09-13 on
# the staged 0.7.0 -fabric jar). Modrinth project id P7dR8mSH
# (api.modrinth.com/v2/project/fabric-api, checked 2026-09-13; the -DryRun output lists it
# on the two Fabric files only); CurseForge relation by slug 'fabric-api' (not checked
# against the CurseForge API from here: confirm it on the live file pages after the upload,
# see PUBLISHING.md release blockers; a rejected upload is reported by the catch below and
# the other uploads still go). Loader names:
# Modrinth uses lowercase loader slugs; CurseForge models loaders as
# game-version entries under the 'modloader' type.
#
# FORGE 1.20.1 (added for 0.10.0) is Forge, NOT NeoForge, and the difference is not
# cosmetic: it declares META-INF/mods.toml where the NeoForge files declare
# META-INF/neoforge.mods.toml, and Minecraft 1.20.1 reads tags from the plural
# data/<ns>/tags/items/ path where 1.21 reads the singular tags/item/ - each silently
# dead on the other line. A Forge jar uploaded under the neoforge loader tag, or a
# NeoForge jar under forge, would install for the wrong people and fail without an
# error either way, so $jarMeta below re-reads each staged jar and refuses to publish
# one whose metadata disagrees with its row here. That file bridges 21 mods, not 24,
# and ships no conditional overlays (1.20.1 has none); PUBLISHING.md's "Forge 1.20.1"
# section is the store copy that says so.
#
# `suffix` is explicit rather than derived from the loader. It used to be
# `if fabric then '-fabric' else ''`, which silently gave the Forge file the
# NeoForge files' unsuffixed shape (0.10.0+mc1.20.1) instead of the intended
# 0.10.0+mc1.20.1-forge. The four values below are EXACTLY what the live store
# versions already use - do not change them, they are published ids.
$fabric121 = @('1.21.1','1.21.2','1.21.3','1.21.4','1.21.5','1.21.6','1.21.7','1.21.8','1.21.9','1.21.10','1.21.11')
$mc26      = @('26.1.2','26.2')
$files = @(
    @{ jar = "pantrywork-$Version.jar";               loaderModrinth = "neoforge"; loaderCf = "NeoForge"; label = "1.21.1"; suffix = "";        meta = "META-INF/neoforge.mods.toml"; mc = @('1.21.1') },
    @{ jar = "pantrywork-$Version-fabric.jar";        loaderModrinth = "fabric";   loaderCf = "Fabric";   label = "1.21.x"; suffix = "-fabric"; meta = "fabric.mod.json";             mc = $fabric121 },
    @{ jar = "pantrywork-$Version-fabric-mc26.jar";   loaderModrinth = "fabric";   loaderCf = "Fabric";   label = "26";     suffix = "-fabric"; meta = "fabric.mod.json";             mc = $mc26 },
    @{ jar = "pantrywork-$Version-neoforge-mc26.jar"; loaderModrinth = "neoforge"; loaderCf = "NeoForge"; label = "26";     suffix = "";        meta = "META-INF/neoforge.mods.toml"; mc = $mc26 },
    @{ jar = "pantrywork-$Version-forge-mc1201.jar";  loaderModrinth = "forge";    loaderCf = "Forge";    label = "1.20.1"; suffix = "-forge";  meta = "META-INF/mods.toml";          mc = @('1.20.1') }
)

if ($Only.Count -gt 0) {
    # Matched in priority order, and the first rule that hits for a term WINS. A plain
    # substring match on the jar name is not good enough on its own: 'forge' is a
    # substring of 'neoforge', so -Only forge quietly selected the NeoForge 26.x leg as
    # well as the Forge one. An exact loader slug or label is therefore tried first, and
    # only a term that is neither falls through to a jar-name wildcard.
    $kept = @()
    foreach ($term in $Only) {
        $hit = @($files | Where-Object { $_.loaderModrinth -eq $term })
        if ($hit.Count -eq 0) { $hit = @($files | Where-Object { $_.label -eq $term }) }
        if ($hit.Count -eq 0) { $hit = @($files | Where-Object { $_.jar -like "*$term*" }) }
        foreach ($h in $hit) { if ($kept -notcontains $h) { $kept += $h } }
    }
    $kept = @($files | Where-Object { $kept -contains $_ })   # keep the table's order
    if ($kept.Count -eq 0) {
        throw ("-Only '$($Only -join ', ')' matched none of the $($files.Count) files. " +
               "Match on a loader slug (neoforge/fabric/forge), a label (1.21.1/1.21.x/26/1.20.1), " +
               "or part of a jar name.")
    }
    Write-Host "-Only '$($Only -join ', ')': publishing $($kept.Count) of $($files.Count) files - $(($kept | ForEach-Object { $_.jar }) -join ', ')"
    $files = $kept
}

# Re-read each staged jar and refuse to publish one whose own metadata disagrees with
# its row above. Two mistakes this catches, both of which have a precedent in this
# project: a jar staged under the wrong name (so it would go up with another loader's
# tag), and a jar built at the wrong version - gradle.properties' mod_version is a
# separate edit from -Version here, and the Forge jar sat at 0.9.0 while 0.10.0 was
# being written up. Pass -SkipJarCheck only to deliberately publish a jar whose
# metadata you have already read yourself.
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Get-JarModMeta {
    param([string]$JarPath)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
    try {
        $found = @($zip.Entries | Where-Object {
            $_.FullName -in @('META-INF/mods.toml','META-INF/neoforge.mods.toml','fabric.mod.json')
        } | ForEach-Object { $_.FullName })
        $ver = $null
        if ($found.Count -eq 1) {
            $entry = $zip.Entries | Where-Object { $_.FullName -eq $found[0] }
            $reader = New-Object System.IO.StreamReader($entry.Open())
            try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
            # mods.toml: version = "x"   |   fabric.mod.json: "version": "x"
            $m = [regex]::Match($text, '(?m)^\s*version\s*=\s*"([^"]+)"')
            if (-not $m.Success) { $m = [regex]::Match($text, '"version"\s*:\s*"([^"]+)"') }
            if ($m.Success) { $ver = $m.Groups[1].Value }
        }
        return @{ meta = $found; version = $ver }
    } finally { $zip.Dispose() }
}

foreach ($f in $files) {
    $jar = Join-Path $dist $f.jar
    if (-not (Test-Path $jar)) { Write-Warning "missing $jar - skipped"; continue }
    $suffix = $f.suffix
    Write-Host "`n=== $($f.jar)  [$($f.loaderCf) $($f.label): $($f.mc -join ', ')] ==="

    if (-not $SkipJarCheck) {
        $jm = Get-JarModMeta -JarPath $jar
        $problems = @()
        if ($jm.meta.Count -ne 1) {
            $problems += "declares $($jm.meta.Count) loader metadata files ($($jm.meta -join ', ')); expected exactly $($f.meta)"
        } elseif ($jm.meta[0] -ne $f.meta) {
            $problems += "declares $($jm.meta[0]) but this row is $($f.loaderCf), which needs $($f.meta) - the jar is for the WRONG LOADER or staged under the wrong name"
        }
        if (-not $jm.version) {
            $problems += "no mod version could be read from its metadata"
        } elseif ($jm.version -ne $Version) {
            $problems += "declares version '$($jm.version)' but -Version is '$Version' - rebuild after bumping mod_version in gradle.properties"
        }
        if ($problems.Count -gt 0) {
            Write-Warning "SKIPPED $($f.jar) - jar check failed:"
            foreach ($pb in $problems) { Write-Warning "    $pb" }
            continue
        }
        Write-Host "jar check : $($jm.meta[0]), version $($jm.version) - matches this row"
    }
    # assigned outside an if-expression so PS 5.1 never unrolls the one-element arrays
    $mrDeps = @()
    $cfRelations = $null
    if ($f.loaderModrinth -eq 'fabric') {
        $mrDeps = @(@{ project_id = $FABRIC_API_MODRINTH; dependency_type = "required" })
        $cfRelations = @{ projects = @(@{ slug = $FABRIC_API_CURSEFORGE_SLUG; type = "requiredDependency" }) }
    }

    if (-not $SkipModrinth) {
        $versionNumber = "$Version+mc$($f.label)$suffix"
        $data = @{
            name           = "Pantrywork $versionNumber"
            version_number = $versionNumber
            project_id     = $ModrinthProjectId
            file_parts     = @("file")
            primary_file   = "file"
            game_versions  = $f.mc
            loaders        = @($f.loaderModrinth)
            version_type   = "release"
            featured       = $false
            dependencies   = $mrDeps
            changelog      = $changelog
        } | ConvertTo-Json -Depth 5
        if ($DryRun) {
            Write-Host "[DryRun] Would POST to Modrinth /version (project id: '$ModrinthProjectId'):"
            Write-Host $data
        } else {
            # Each upload is independent: a failure here (e.g. a version number
            # that already exists from a previous run) is reported and skipped,
            # never fatal, so the other files and the other platform still go.
            try {
                $headers = @{ Authorization = $ModrinthToken }
                $result = Invoke-MultipartPost -Uri "https://api.modrinth.com/v2/version" -Headers $headers -JsonFieldName "data" -JsonBody $data -FileFieldName "file" -FilePath $jar
                Write-Host "Modrinth: uploaded $versionNumber"
            } catch {
                Write-Warning "Modrinth: FAILED $versionNumber - $($_.Exception.Message)"
            }
        }
    }

    if ($SkipCurseForge) {
        Write-Host "CurseForge: SKIPPED (-SkipCurseForge)"
    } elseif ($CurseForgeProjectId -eq 0) {
        Write-Host "CurseForge: SKIPPED - no project id. Pass -CurseForgeProjectId <number> or set CURSEFORGE_PROJECT_ID."
    } elseif (-not $CurseForgeToken) {
        Write-Host "[DryRun]   CURSEFORGE_TOKEN not set - cannot verify version ids"
        if ($cfRelations) { Write-Host "[DryRun]   relations: $($cfRelations | ConvertTo-Json -Depth 5 -Compress)" }
    } else {
        # Resolve the Minecraft versions, the loader id, and the environment
        # ids. CurseForge rejects an upload (error 1021) unless the gameVersions
        # array includes at least one entry from the environment group; this mod
        # runs on both, so tag Client + Server.
        $ldId = Get-CurseForgeVersionIdByType -Name $f.loaderCf -TypeSlugPrefix "modloader" -Token $CurseForgeToken
        $envIds = @()
        foreach ($en in @('Client','Server')) {
            $eid = Get-CurseForgeVersionIdByType -Name $en -TypeSlugPrefix "environment" -Token $CurseForgeToken
            if ($eid) { $envIds += $eid }
        }
        $gvIds = @()
        $unresolved = @()
        foreach ($v in $f.mc) {
            $id = Get-CurseForgeVersionIdByType -Name $v -TypeSlugPrefix "minecraft-" -Token $CurseForgeToken
            if ($id) { $gvIds += $id } else { $unresolved += $v }
        }
        if ($DryRun) {
            Write-Host "[DryRun] CurseForge project $CurseForgeProjectId"
            Write-Host "[DryRun]   loader '$($f.loaderCf)' -> $ldId ; environment (Client,Server) -> $($envIds -join ', ')"
            Write-Host "[DryRun]   resolved $($gvIds.Count)/$($f.mc.Count) game versions -> $($gvIds -join ', ')"
            if ($unresolved.Count -gt 0) { Write-Host "[DryRun]   UNRESOLVED (would be dropped): $($unresolved -join ', ')" }
            if ($cfRelations) { Write-Host "[DryRun]   relations: $($cfRelations | ConvertTo-Json -Depth 5 -Compress)" }
        } else {
            if (-not $ldId -or $gvIds.Count -eq 0 -or $envIds.Count -eq 0) {
                Write-Warning "Skipping CurseForge upload for $($f.jar) - loader, environment, or all game versions unresolved."
            } else {
                if ($unresolved.Count -gt 0) { Write-Warning "$($f.jar): dropping unresolved CurseForge versions: $($unresolved -join ', ')" }
                $meta = @{
                    changelog     = $changelog
                    changelogType = "markdown"
                    displayName   = "Pantrywork $Version ($($f.loaderCf) $($f.label))"
                    releaseType   = "release"
                    gameVersions  = @($gvIds + $ldId + $envIds)
                }
                if ($cfRelations) { $meta.relations = $cfRelations }
                $metadata = $meta | ConvertTo-Json -Depth 6
                try {
                    $headers = @{ "X-Api-Token" = $CurseForgeToken }
                    $result = Invoke-MultipartPost -Uri "https://minecraft.curseforge.com/api/projects/$CurseForgeProjectId/upload-file" -Headers $headers -JsonFieldName "metadata" -JsonBody $metadata -FileFieldName "file" -FilePath $jar
                    Write-Host "CurseForge: uploaded $($f.jar)"
                } catch {
                    Write-Warning "CurseForge: FAILED $($f.jar) - $($_.Exception.Message)"
                }
            }
        }
    }
}
Write-Host "`nDone."
