Function Create-LocalUser {
    <#
        .SYNOPSIS
            Create a local user account that MDT will use to connect to the deployment share.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalUserName,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalUserPassword
    )

    [System.Security.SecureString]$Password = ($LocalUserPassword | ConvertTo-SecureString -AsPlainText -Force)
    # Create MDT-Capture local account
    try{
        Get-LocalUser -Name $LocalUserName -ErrorAction Stop | Out-Null
        Write-Verbose "Local account $LocalUserName already exists"
        $Random = Get-Random -Minimum 1 -Maximum 99
        Create-LocalUser -LocalUserName ($LocalUserName + $Random) -LocalUserPassword $Password
    }
    catch{
        New-LocalUser -Name $LocalUserName -Password $Password | Out-Null
        Write-Verbose "User account $LocalUserName created"
    }

    $script:MDTUserName = $LocalUserName
    $script:MDTPassword = $LocalUserPassword
}