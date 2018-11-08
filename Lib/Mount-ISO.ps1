Function Mount-ISO {
    <#
        .SYNOPSIS
            Mount or dismount a .ISO file and return drive letter path.
    #>

    [CmdletBinding()]
    param(
        $ISOSource,

        [ValidateSet('Mount','Dismount')]
        $Action = 'Mount'
    )

    $MountParams = @{ImagePath = $ISOSource.FullName
                     PassThru = $true
                     ErrorAction = 'Ignore'}
    If($Action -eq 'Mount'){
        $Mount = Mount-DiskImage @MountParams
        $Volume = Get-DiskImage -ImagePath $mount.ImagePath | Get-Volume
        $script:FileSource = $volume.DriveLetter + ':\'
    }
    Else{
        Dismount-DiskImage @MountParams | Out-Null
    }
}
