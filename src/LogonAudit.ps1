$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path $scriptPath
$last24Hours = (Get-Date).AddHours(-24)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Define output directory and file
$dataDir = Join-Path $scriptDir "..\data" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $dataDir) {
    $dataDir = Join-Path $scriptDir "..\data"
    try {
        New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
        Write-Host "Created output directory: $dataDir"
    } catch {
        Write-Warning "Failed to create output directory: $_"
        return
    }
}
$outputFile = Join-Path $dataDir "LogonEvents_$timestamp.csv"

$results = @()

# Collect Security log events (Logon/Logoff/Lock/Unlock)
try {
    $securityEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        Id = 4624, 4647, 4634, 4800, 4801
        StartTime = $last24Hours
    }
} catch {
    Write-Warning "Failed to retrieve Security events: $_"
    $securityEvents = @()
}

# Collect System log events (Shutdown/Restart)
try {
    $systemEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Id = 1074, 6006, 6008
        StartTime = $last24Hours
    }
} catch {
    Write-Warning "Failed to retrieve System events: $_"
    $systemEvents = @()
}

# Process Security events
foreach ($event in $securityEvents) {
    $props = $event.Properties
    $eventId = $event.Id

    # Use correct indices based on event type
    if ($eventId -in 4800, 4801) {
        $accountDomain = $props[0].Value
        $accountName   = $props[1].Value
    } else {
        $accountName   = $props[5].Value
        $accountDomain = $props[6].Value
    }

    $logonType = if ($props.Count -gt 8) { $props[8].Value } else { $null }
    $logonId   = if ($props.Count -gt 7) { $props[7].Value } else { $null }
    $user      = "$accountDomain\$accountName"

    if (
        ($eventId -eq 4624 -and $logonType -in 7, 10, 11 -and
         $accountName -notmatch '^(UMFD|DWM|LOCAL SERVICE|SYSTEM|ANONYMOUS LOGON|$)' -and
         $accountName -ne 'IUSR') -or
        ($eventId -in 4647, 4634 -and $logonId) -or
        ($eventId -in 4800, 4801)
    ) {
        $type = switch ($eventId) {
            4624 { "Logon" }
            4647 { "Logoff (User Initiated)" }
            4634 { "Logoff (Session Ended)" }
            4800 { "Locked" }
            4801 { "Unlocked" }
        }

        $results += [PSCustomObject]@{
            TimeStamp = $event.TimeCreated
            User      = $user
            EventID   = $eventId
            Type      = $type
        }
    }
}

# Process System events
foreach ($event in $systemEvents) {
    $eventId = $event.Id
    $type = switch ($eventId) {
        1074 { "Shutdown/Restart (Planned)" }
        6006 { "Shutdown (Clean)" }
        6008 { "Shutdown (Unexpected)" }
        default { "System Event" }
    }

    $results += [PSCustomObject]@{
        TimeStamp = $event.TimeCreated
        User      = "SYSTEM"
        EventID   = $eventId
        Type      = $type
    }
}

# Save to CSV
try {
    $results | Sort-Object TimeStamp |
    Export-Csv -Path $outputFile -NoTypeInformation
    Write-Host "Results saved to: $outputFile"
} catch {
    Write-Warning "Failed to export results: $_"
}