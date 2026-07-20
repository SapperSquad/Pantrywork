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

# The two release artifacts. Loader names: Modrinth uses lowercase loader slugs;
# CurseForge models loaders as game-version entries under the 'modloader' type.
$files = @(
    @{ jar = "pantrywork-$Version.jar";        loaderModrinth = "neoforge"; loaderCf = "NeoForge"; suffix = "" },
    @{ jar = "pantrywork-$Version-fabric.jar"; loaderModrinth = "fabric";   loaderCf = "Fabric";   suffix = "-fabric" }
)
$mc = "1.21.1"

foreach ($f in $files) {
    $jar = Join-Path $dist $f.jar
    if (-not (Test-Path $jar)) { Write-Warning "missing $jar - skipped"; continue }
    Write-Host "`n=== $($f.jar) ==="

    if (-not $SkipModrinth) {
        $versionNumber = "$Version+mc$mc$($f.suffix)"
        $data = @{
            name           = "Pantrywork $versionNumber"
            version_number = $versionNumber
            project_id     = $ModrinthProjectId
            file_parts     = @("file")
            primary_file   = "file"
            game_versions  = @($mc)
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
            $headers = @{ Authorization = $ModrinthToken }
            $result = Invoke-MultipartPost -Uri "https://api.modrinth.com/v2/version" -Headers $headers -JsonFieldName "data" -JsonBody $data -FileFieldName "file" -FilePath $jar
            Write-Host "Modrinth: uploaded $versionNumber"
        }
    }

    if ($SkipCurseForge) {
        Write-Host "CurseForge: SKIPPED (-SkipCurseForge)"
    } elseif ($CurseForgeProjectId -eq 0) {
        Write-Host "CurseForge: SKIPPED - no project id. Pass -CurseForgeProjectId <number> or set CURSEFORGE_PROJECT_ID."
    } else {
        if ($DryRun) {
            Write-Host "[DryRun] CurseForge project $CurseForgeProjectId"
            if ($CurseForgeToken) {
                $gvId = Get-CurseForgeVersionIdByType -Name $mc -TypeSlugPrefix "minecraft-" -Token $CurseForgeToken
                $ldId = Get-CurseForgeVersionIdByType -Name $f.loaderCf -TypeSlugPrefix "modloader" -Token $CurseForgeToken
                Write-Host "[DryRun]   '$mc' -> $gvId ; '$($f.loaderCf)' -> $ldId ; would POST upload-file"
            } else {
                Write-Host "[DryRun]   CURSEFORGE_TOKEN not set - cannot verify version ids"
            }
        } else {
            $gvId = Get-CurseForgeVersionIdByType -Name $mc -TypeSlugPrefix "minecraft-" -Token $CurseForgeToken
            $ldId = Get-CurseForgeVersionIdByType -Name $f.loaderCf -TypeSlugPrefix "modloader" -Token $CurseForgeToken
            if (-not $gvId -or -not $ldId) {
                Write-Warning "Skipping CurseForge upload for $($f.jar) - unresolved version ids."
            } else {
                $metadata = @{
                    changelog     = $changelog
                    changelogType = "markdown"
                    displayName   = "Pantrywork $Version ($($f.loaderCf) $mc)"
                    releaseType   = "release"
                    gameVersions  = @($gvId, $ldId)
                } | ConvertTo-Json -Depth 5
                $headers = @{ "X-Api-Token" = $CurseForgeToken }
                $result = Invoke-MultipartPost -Uri "https://minecraft.curseforge.com/api/projects/$CurseForgeProjectId/upload-file" -Headers $headers -JsonFieldName "metadata" -JsonBody $metadata -FileFieldName "file" -FilePath $jar
                Write-Host "CurseForge: uploaded $($f.jar)"
            }
        }
    }
}
Write-Host "`nDone."
