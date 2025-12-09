<#
.SYNOPSIS
    Generates a daily security summary report.

.DESCRIPTION
    Pulls failed logons (4625) and account lockouts (4740)
    from the Security event log for the last 24 hours and
    exports them to a CSV file.

.EXAMPLE
    .\DailySecuritySummary.ps1
#>

$now   = Get-Date
$since = $now.AddDays(-1)

$filter = @{
    LogName   = 'Security'
    Id        = 4625, 4740
    StartTime = $since
}

Write-Host "Collecting Security events since $since ..."

$events = Get-WinEvent -FilterHashtable $filter |
    Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message

if (-not $events) {
    Write-Host "No matching events found in the last 24 hours."
} else {
    $fileName = "DailySecuritySummary_{0:yyyyMMdd_HHmm}.csv" -f $now
    $outPath  = Join-Path -Path (Get-Location) -ChildPath $fileName

    $events | Export-Csv -Path $outPath -NoTypeInformation

    Write-Host "Daily security summary saved to:"
    Write-Host "  $outPath"
}
