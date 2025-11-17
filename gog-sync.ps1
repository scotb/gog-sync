
param(
    [switch]$Download,
    [switch]$DownloadAll,
    [switch]$Repair,
    [switch]$ListAll,
    [switch]$Tty,
    [switch]$ShowAllOutput,
    [switch]$VerboseLog,
    [string]$GameName,
    [switch]$ExactMatch
)

$logFile = "gog-sync.log"

Set-Location "C:\gog-archive"

# Output relevant info for analysis
$mode = if ($ListAll) { 'ListAll' } elseif ($DownloadAll) { 'DownloadAll' } elseif ($Download) { 'Download' } elseif ($Repair) { 'Repair' } else { 'ListUpdated' }
$downloadDir = '/downloads'
$threads = '8'

$startTime = Get-Date

$i = 0
$dockerArgs = @('run', '--rm')
if ($Tty) { $dockerArgs += '-t' }
$dockerArgs += 'gogrepo'

$lgogArgs = @('lgogdownloader')
if ($ListAll) {
    $lgogArgs += '--list'
} elseif ($DownloadAll) {
    $lgogArgs += '--download'
} elseif ($Download) {
    $lgogArgs += '--download'
    $lgogArgs += '--updated'
} elseif ($Repair) {
    $lgogArgs += '--repair'
    $lgogArgs += '--download'
} else {
    $lgogArgs += '--list'
    $lgogArgs += '--updated'
}
$gamePattern = $null
if ($GameName) {
    if ($ExactMatch) {
        $gamePattern = "^$GameName$"
    } else {
        $gamePattern = $GameName
    }
    $lgogArgs += '--game'
    $lgogArgs += $gamePattern
}
$lgogArgs += '--directory'; $lgogArgs += $downloadDir
$lgogArgs += '--threads'; $lgogArgs += $threads

$fullArgs = $dockerArgs + $lgogArgs

$infoLines = @(
    "==== GOG Sync Run Start: $(Get-Date) ===="
    "Mode: $mode"
    "Download Directory: $downloadDir"
    "Threads: $threads"
    "TTY: $Tty"
    "ShowAllOutput: $ShowAllOutput"
    "VerboseLog: $VerboseLog"
)
$infoLines | Tee-Object -FilePath $logFile -Append
# Print and log the command to both console and log file
$cmdString = "Running command: docker-compose $($fullArgs -join ' ')"
Write-Host $cmdString
Add-Content -Path $logFile -Value $cmdString

if ($ListAll -or ($lgogArgs -contains '--list')) {
    # Always show all output when listing, and suppress PowerShell error wrapping
    cmd /c "docker-compose $($fullArgs -join ' ')" |
        ForEach-Object {
            $line = $_
            if ($line -match 'Repairing file') {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
            } else {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
            }
        }
} elseif ($ShowAllOutput) {
    cmd /c "docker-compose $($fullArgs -join ' ')" |
        ForEach-Object {
            $line = $_
            if ($line -match 'Repairing file') {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
            } else {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
            }
        }
} elseif ($VerboseLog) {
    # Exclude all lines starting with #, only keep the last Total:/Remaining: line, errors, warnings, and run summary lines
    $progressCount = 0
    cmd /c "docker-compose $($fullArgs -join ' ')" |
        ForEach-Object {
            $line = $_
            $line = $line -replace "[^\x09\x0A\x0D\x20-\x7E]", ''
            if ($line -match 'Repairing file') {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
            } elseif ($line -match '(ERROR|WARNING|Run completed|====)' -and $line.Trim().Length -gt 0) {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
            } elseif ($line -match '^#') {
                # For UI feedback, print a dot for each per-file line (not logged)
                $progressCount++
                if ($progressCount % 1000 -eq 0) { Write-Host -NoNewline "." }
            }
        }
    if ($progressCount -gt 0) { Write-Host "" }
} else {
    cmd /c "docker-compose $($fullArgs -join ' ')" |
        ForEach-Object {
            $line = $_
            if ($line -match 'Repairing file') {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
            } elseif ($line -match 'ERROR|WARNING') {
                Write-Host $line
                Add-Content -Path $logFile -Value $line
                $i++
                if ($i % 1000 -eq 0) { Write-Host -NoNewline "." }
            }
        }
}

$endTime = Get-Date
$elapsed = $endTime - $startTime
$elapsedStr = $elapsed.ToString()
"==== GOG Sync Run End: $endTime (Elapsed: " + $elapsedStr + ") ====" | Tee-Object -FilePath $logFile -Append