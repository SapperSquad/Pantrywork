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
# This performs REAL, PUBLIC uploads when run without -DryRun.

param(
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$ChangelogFile,
    [string]$ModrinthProjectId = "",
    [int]$CurseForgeProjectId = 0,
    [switch]$SkipModrinth,
    [switch]$SkipCurseForge,
    [switch]$DryRun
)
$ErrorActionPreference = "Stop"

if (-not $ModrinthProjectId -and $env:MODRINTH_PROJECT_ID) { $ModrinthProjectId = $env:MODRINTH_PROJECT_ID }
if ($CurseForgeProjectId -eq 0 -and $env:CURSEFORGE_PROJECT_ID) { $CurseForgeProjectId = [int]$env:CURSEFORGE_PROJECT_ID }

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

# The three release artifacts, each carrying the Minecraft versions it was
# actually verified against (see PUBLISHING.md verification log). Loader names:
# Modrinth uses lowercase loader slugs; CurseForge models loaders as
# game-version entries under the 'modloader' type.
$fabric121 = @('1.21.1','1.21.2','1.21.3','1.21.4','1.21.5','1.21.6','1.21.7','1.21.8','1.21.9','1.21.10','1.21.11')
$fabric26  = @('26.1.2','26.2')
$files = @(
    @{ jar = "pantrywork-$Version.jar";             loaderModrinth = "neoforge"; loaderCf = "NeoForge"; label = "1.21.1";  mc = @('1.21.1') },
    @{ jar = "pantrywork-$Version-fabric.jar";      loaderModrinth = "fabric";   loaderCf = "Fabric";   label = "1.21.x"; mc = $fabric121 },
    @{ jar = "pantrywork-$Version-fabric-mc26.jar"; loaderModrinth = "fabric";   loaderCf = "Fabric";   label = "26";     mc = $fabric26 }
)

foreach ($f in $files) {
    $jar = Join-Path $dist $f.jar
    if (-not (Test-Path $jar)) { Write-Warning "missing $jar - skipped"; continue }
    $suffix = if ($f.loaderModrinth -eq 'fabric') { "-fabric" } else { "" }
    Write-Host "`n=== $($f.jar)  [$($f.loaderCf) $($f.label): $($f.mc -join ', ')] ==="

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
            dependencies   = @()
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
        } else {
            if (-not $ldId -or $gvIds.Count -eq 0 -or $envIds.Count -eq 0) {
                Write-Warning "Skipping CurseForge upload for $($f.jar) - loader, environment, or all game versions unresolved."
            } else {
                if ($unresolved.Count -gt 0) { Write-Warning "$($f.jar): dropping unresolved CurseForge versions: $($unresolved -join ', ')" }
                $metadata = @{
                    changelog     = $changelog
                    changelogType = "markdown"
                    displayName   = "Pantrywork $Version ($($f.loaderCf) $($f.label))"
                    releaseType   = "release"
                    gameVersions  = @($gvIds + $ldId + $envIds)
                } | ConvertTo-Json -Depth 5
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
