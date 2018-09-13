Function Download-File {
    <#
        .SYNOPSIS
            Download and save a file from a given url location.
    #>

    [CmdletBinding()]
    param(
        [string]$URL,

        [string]$Path
    )

    Write-Verbose "Downloading $Application from $URL`nSaving as $Path"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($URL,$Path)
}
