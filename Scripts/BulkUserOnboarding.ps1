<#
.SYNOPSIS
    Bulk user onboarding script for Active Directory.

.DESCRIPTION
    Reads a CSV file with user information, creates AD accounts,
    adds them to the specified group(s), and logs the results.

.PARAMETER CsvPath
    Path to the CSV file. Columns required:
    DisplayName, SamAccountName, OU, PrimaryGroup

.EXAMPLE
    .\BulkUserOnboarding.ps1 -CsvPath .\new_users.csv
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

# Requires RSAT / AD tools
Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Test-Path -Path $CsvPath)) {
    Write-Error "CSV file not found at path: $CsvPath"
    exit 1
}

$users = Import-Csv -Path $CsvPath
$log   = @()

foreach ($user in $users) {
    try {
        $name  = $user.DisplayName
        $sam   = $user.SamAccountName
        $ou    = $user.OU
        $group = $user.PrimaryGroup

        Write-Host "Creating user $name ($sam) in $ou ..." 

        New-ADUser `
            -Name $name `
            -SamAccountName $sam `
            -UserPrincipalName "$sam@moal.local" `
            -Path $ou `
            -AccountPassword (ConvertTo-SecureString "TempP@ssw0rd!" -AsPlainText -Force) `
            -Enabled $true

        if ($group -and $group -ne "") {
            Add-ADGroupMember -Identity $group -Members $sam
        }

        $log += [pscustomobject]@{
            TimeStamp       = Get-Date
            DisplayName     = $name
            SamAccountName  = $sam
            OU              = $ou
            Group           = $group
            Status          = "Success"
            Error           = ""
        }
    }
    catch {
        $log += [pscustomobject]@{
            TimeStamp       = Get-Date
            DisplayName     = $user.DisplayName
            SamAccountName  = $user.SamAccountName
            OU              = $user.OU
            Group           = $user.PrimaryGroup
            Status          = "Failed"
            Error           = $_.Exception.Message
        }
    }
}

$logPath = Join-Path -Path (Get-Location) -ChildPath "BulkUserOnboarding_Log.csv"
$log | Export-Csv -Path $logPath -NoTypeInformation

Write-Host "Bulk onboarding complete. Log saved to $logPath"
