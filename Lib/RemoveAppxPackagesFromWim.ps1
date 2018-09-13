Function Remove-AppXPackagesFromWim {
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
    
    $PackagesToRemove = Get-Content $AppsToRemove        If(-not(Test-Path $MountPath)){        New-Item -Path $MountPath -ItemType Directory | Out-Null    }    Write-Verbose "Mounting image from $WimFile to the $MountPath folder"    Mount-WindowsImage –ImagePath $WimFile –Index $Index –Path $MountPath | Out-Null     # Remove the packages    $AppxPackagesToRemove = (Get-AppxProvisionedPackage -Path $MountPath | Where-Object DisplayName -In $PackagesToRemove)    ForEach ($App in $AppxPackagesToRemove){         try{            Get-AppxProvisionedPackage -Path $MountPath | where {$_.DisplayName -eq $App.DisplayName} | Remove-AppxProvisionedPackage -ErrorAction Stop | Out-Null            Write-Verbose "Removing $($App.DisplayName)"            "$(Get-Date -Format g)`tSuccessfully removed $($App.DisplayName)" |Out-File $LogFile -Append        }        catch{            Write-Output "$(Get-Date -Format g)`tUnable to remove $($App.DisplayName)" | Out-File $LogFile -Append        }    }    ## Dismount the image and save changes    Dismount-WindowsImage –Path $MountPath -Save    Remove-Item -Path $MountPath -Force}