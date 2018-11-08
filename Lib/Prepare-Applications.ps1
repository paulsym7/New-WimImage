Function Prepare-Applications{
    <#
        .SYNOPSIS
            Download applications specified in the Applications.csv file.
    #>

    [CmdletBinding()]
    param()
    
    $AppsFolder = "$MediaLocation\Applications"
    If(-not(Test-Path $AppsFolder)){
        New-Item -Path $AppsFolder -ItemType Directory | Out-Null
    }

    foreach($Application in $Applications){
        If(-not(Test-Path $AppsFolder\$($Application.Name))){
            Write-Verbose "Creating a $($Application.Name) folder for $($Application.FullName)"
            New-Item -Path $AppsFolder\$($Application.Name) -ItemType Directory | Out-Null
        }
        If(-not(Get-Item -Path $AppsFolder\$($Application.Name)\$($Application.Name).exe -ErrorAction SilentlyContinue)){
            Write-Verbose "No $($Application.Name).exe file found in the $($Application.Name) folder, will download it from $($Application.URL)"
            $URL = $Application.URL
            $Path = "$AppsFolder\$($Application.Name)\$($Application.Name).exe"
            Write-Verbose "Downloading $($Application.FullName) from $URL`nSaving as $Path"
            Download-File -URL $URL -Path $Path -Verbose
        }
    }
}