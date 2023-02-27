Function Set-SwMaintMode {
    <#
    .SYNOPSIS
        This function places a host into maintenance mode in SolarWinds for 1 day
    .DESCRIPTION
        SolarWinds maintenance mode
    .NOTES
        Reqires SwisPowerShell - "Install-Module SwisPowerShell"
    .EXAMPLE
        Set-SwMaintMode -swhostname swnetmon.local -swnode esxilab001.local -mute
    .EXAMPLE
        Set-SwMaintMode -swhostname swnetmon.local -swnode esxilab001.local -unmute
    #>
    param(
        [Parameter(Mandatory = $true)][string]$swhostname,
        [Parameter(Mandatory = $true)][string]$swnode,
        [parameter(Mandatory = $false)][switch]$mute,
        [parameter(Mandatory = $false)][switch]$unmute
        # [Parameter(Mandatory = $true)][string]$sw_user,
        # [Parameter(Mandatory = $true)][string]$sw_pass
    )

    # define target host and credentials
    if (!$swhostname) { $swhostname = 'swnetmon.local' }
    if (!$swnode) { $swnode = Read-Host "Please enter the SolarWinds hostname" }
    # if (!$sw_user) { $sw_user = Read-Host "Please enter your SolarWinds username" }
    # if (!$sw_pass) { $sw_pass = Read-Host "Please enter your SolarWinds password" }

    $swis = Connect-Swis -Hostname $swhostname -Trusted # -UserName $sw_user -Password $sw_pass

<#------------- ACTUAL SCRIPT -------------#>
## !! DO NOT INDENT THE $query - THIS WILL BREAK THE QUERY !! ##
$query = @"
SELECT NodeID, Caption, Uri AS [EntityUri]
FROM Orion.Nodes WHERE Caption like '$swnode'
"@
$nodes = Get-SwisData $swis $query

# times to unmanage between
$now = [DateTime]::UtcNow
$later = [DateTime]::UtcNow.AddDays(1)

    if ($mute){
        foreach($node in $nodes) {  
            # write out which group we're working with
            # "Unmanaging $($node.Caption) from $now to $later"
            # Invoke-SwisVerb $swis Orion.Nodes Unmanage @($Node.nodeid, $now, $later, "false") | Out-Null
            Write-Host "Muting $($node.Caption) from $now to $later" -ForegroundColor Yellow
            Invoke-SwisVerb $swis Orion.AlertSuppression SuppressAlerts @(@($node.EntityUri), $now) | Out-Null
        }
    }
    if ($unmute){
        foreach($node in $nodes) {  
            # write out which group we're working with
            # "Unmanaging $($node.Caption) from $now to $later"
            # Invoke-SwisVerb $swis Orion.Nodes Unmanage @($Node.nodeid, $now, $later, "false") | Out-Null
            Write-Host "Unmuting $($node.Caption)" -ForegroundColor Yellow
            Invoke-SwisVerb $swis Orion.AlertSuppression ResumeAlerts @( , [string[]] $node.EntityUri) | Out-Null
        }
    }
}
