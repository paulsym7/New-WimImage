﻿Function Remove-AppXPackagesFromWim {
    <#
        .SYNOPSIS
            Remove unwanted AppxProvisioned packages from .wim file.
            Looks for a text file in the Config folder containing the display name of packages to be removed
    #>

    [CmdletBinding()]
    param(
        # Path to .wim file Appx provisioned packages are to be removed from
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$WimFile,

        # Path to text file containing list of Appx provisioned packages to be removed
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$AppsToRemove,

        # Empty folder to mount the .wim into - will be created if it does not already exist
        [Parameter(Mandatory=$true)]
        [string]$MountPath,

        [Parameter(Mandatory=$true)]
        [int]$Index,

        [string]$LogFile = "$env:SystemDrive\Temp\Remove-AppxPackages.log"
    )
    
    $PackagesToRemove = Get-Content $AppsToRemove