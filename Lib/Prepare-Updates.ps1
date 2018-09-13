Function Prepare-Updates{
    <#
        .SYNOPSIS
            Download the latest available cumulative update.
            Uses Aaron Parkers LatestUpdate module https://stealthpuppy.com/powershell-download-import-updates-mdt/
            Module will be downloaded from PSGallery if it is not already installed
    #>

    [CmdletBinding()]
    Param()

    If(-not(Test-Path $MediaLocation\Updates)){
        New-Item -Path $MediaLocation\Updates -ItemType Directory | Out-Null
    }

    Write-Verbose 'Checking if LatestUpdate module is installed'
    try{
        Get-LatestUpdate -ErrorAction Stop | Out-Null
        Write-Verbose 'The LatestUpdate Module is installed'
    }
    catch{
        Write-Verbose 'The LatestUpdate module is not installed, will download and install from the PSGallery'
        try{
            Register-PSRepository -Default -ErrorAction Stop
            Write-Verbose 'Registering PSGallery'
        }
        catch{
            Write-Verbose 'PSGallery is already registered'
        }
        Install-Module -Name LatestUpdate -Repository PSGallery -Force
    }

    Get-LatestUpdate -WindowsVersion $OperatingSystemName.Replace(' ','') | Save-LatestUpdate -Path $MediaLocation\Updates
}