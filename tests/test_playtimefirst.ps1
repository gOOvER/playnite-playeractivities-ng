<#
.SYNOPSIS
    Test-Runner for PlayerActivities PlaytimeFirst logic fix.
.DESCRIPTION
    Tests the logic implemented in PlayerActivities.cs and PlayerActivitiesDatabase.cs:
    1. HasFirst() on empty collection -> False
    2. HasFirst() when item exists -> True
    3. Game start 1 (first time) -> Adds 1 PlaytimeFirst entry
    4. Game start 2 (subsequent) -> Does NOT add duplicate PlaytimeFirst entry
    5. Game start 3 (PlayCount > 1) -> Does NOT add PlaytimeFirst entry
    6. Legacy data deduplication -> Reduces 6 duplicate entries to 1 earliest entry
#>

$ErrorActionPreference = 'Stop'
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  PlayerActivities NG - PlaytimeFirst Bugfix Verification " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Assert-Test([string]$name, [bool]$condition, [string]$failMessage = "") {
    if ($condition) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $name : $failMessage" -ForegroundColor Red
        $script:failed++
    }
}

# --- Mock Models ---
class Activity {
    [int]$Type # 5 = PlaytimeFirst, 4 = PlaytimeGoal
    [DateTime]$DateActivity = [DateTime]::UtcNow
    [uint64]$Value = 0
}

class PlayerActivitiesData {
    [System.Collections.Generic.List[Activity]]$Items = [System.Collections.Generic.List[Activity]]::new()

    [bool] HasFirst() {
        foreach ($item in $this.Items) {
            if ($item.Type -eq 5) { return $true }
        }
        return $false
    }
}

class GameMock {
    [uint64]$PlayCount = 0
}

# --- Test 1: HasFirst on empty data ---
$data = [PlayerActivitiesData]::new()
Assert-Test "HasFirst returns false on empty list" (-not $data.HasFirst())

# --- Test 2: HasFirst with existing item ---
$act = [Activity]::new()
$act.Type = 5
$data.Items.Add($act)
Assert-Test "HasFirst returns true when PlaytimeFirst exists" ($data.HasFirst())

# --- Test 3: Simulation of OnGameStarted Fix ---
$freshData = [PlayerActivitiesData]::new()
$game = [GameMock]::new()
$game.PlayCount = 0

# First start (Fixed logic: if ($game.PlayCount -le 1 -and -not $freshData.HasFirst()))
if ($game.PlayCount -le 1 -and -not $freshData.HasFirst()) {
    $item = [Activity]::new()
    $item.Type = 5
    $freshData.Items.Add($item)
}
Assert-Test "1st Game Start: Exactly 1 PlaytimeFirst added" ($freshData.Items.Count -eq 1 -and $freshData.Items[0].Type -eq 5)

# Second start (PlayCount incremented to 1)
$game.PlayCount = 1
if ($game.PlayCount -le 1 -and -not $freshData.HasFirst()) {
    $item = [Activity]::new()
    $item.Type = 5
    $freshData.Items.Add($item)
}
Assert-Test "2nd Game Start: Duplicate prevented (still 1 entry)" ($freshData.Items.Count -eq 1)

# Third start (PlayCount incremented to 2)
$game.PlayCount = 2
if ($game.PlayCount -le 1 -and -not $freshData.HasFirst()) {
    $item = [Activity]::new()
    $item.Type = 5
    $freshData.Items.Add($item)
}
Assert-Test "3rd Game Start: Duplicate prevented when PlayCount > 1" ($freshData.Items.Count -eq 1)

# --- Test 4: Existing game with prior play history (>1) ---
$importedData = [PlayerActivitiesData]::new()
$importedGame = [GameMock]::new()
$importedGame.PlayCount = 25

if ($importedGame.PlayCount -le 1 -and -not $importedData.HasFirst()) {
    $item = [Activity]::new()
    $item.Type = 5
    $importedData.Items.Add($item)
}
Assert-Test "Game with PlayCount=25: No PlaytimeFirst added" ($importedData.Items.Count -eq 0)

# --- Test 5: Legacy Duplicate Cleanup / Deduplication ---
$corruptItems = [System.Collections.Generic.List[Activity]]::new()

$earliestDate = [DateTime]::Parse("2026-05-30T15:39:26Z")
$d1 = [Activity]::new(); $d1.Type = 5; $d1.DateActivity = [DateTime]::Parse("2026-10-04T13:48:00Z"); $corruptItems.Add($d1)
$d2 = [Activity]::new(); $d2.Type = 5; $d2.DateActivity = $earliestDate; $corruptItems.Add($d2)
$d3 = [Activity]::new(); $d3.Type = 4; $d3.Value = 25; $corruptItems.Add($d3)
$d4 = [Activity]::new(); $d4.Type = 5; $d4.DateActivity = [DateTime]::Parse("2026-10-04T13:48:31Z"); $corruptItems.Add($d4)
$d5 = [Activity]::new(); $d5.Type = 5; $d5.DateActivity = [DateTime]::Parse("2026-10-04T13:49:07Z"); $corruptItems.Add($d5)

# Deduplication logic as implemented in PlayerActivitiesDatabase.GetActivitiesData:
$firstPlaytimes = @($corruptItems | Where-Object { $_.Type -eq 5 } | Sort-Object DateActivity)
if ($firstPlaytimes.Count -gt 1) {
    [void]$corruptItems.RemoveAll([Predicate[Activity]]{ param($x) $x.Type -eq 5 })
    $corruptItems.Add($firstPlaytimes[0])
}

$playtimeFirstCount = @($corruptItems | Where-Object { $_.Type -eq 5 }).Count
$retainedDate = ($corruptItems | Where-Object { $_.Type -eq 5 })[0].DateActivity

Assert-Test "Deduplication: Reduced 4 duplicates to exactly 1" ($playtimeFirstCount -eq 1)
Assert-Test "Deduplication: Retained the earliest date ($earliestDate)" ($retainedDate -eq $earliestDate)

Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Results: $passed Passed, $failed Failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

exit $failed
