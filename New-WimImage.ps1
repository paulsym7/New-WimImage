<#
.SYNOPSIS
   The New-WimImage.ps1 script will create a customized .wim image patched with the latest OS cumulative update and containing a pre-determined list of applications. If a list of AppxProvisioned packages is supplied, these packages will be removed from the .wim file.
.DESCRIPTION
   The New-WimImage.ps1 script will create a customized .wim image patched with the latest OS cumulative update and containing a pre-determined list of applications.

    Script prerequisites:
    Hyper-V is installed
    Latest version of Windows ADK installed

    Applications, Windows features and updates:
    If an AppsToInstall.csv file is placed in the config folder, the script will install these applications during the task sequence.
    Note, the application must have a silent install switch and the script currently only supports .exe files
    
    Applications not found in the media location folder will be downloaded using the URL provided in the AppsToInstall.csv file.
    
    If an AppsToRemove.txt file is placed in the config folder, the script will mount the customized .wim and remove all listed packages from the .wim
    Use the (Get-AppxProvisionedPackage -Online).DisplayName command to discover the correct name format for packages to remove.

    If an OSFeatures.txt file is placed in the config folder, the script will install all features listed in the file.
    Use the (Get-WindowsOptionalFeature -Online).FeatureName command to discover the correct name format for the Windows features. 

    Aaron Parker's LatestUpdate module is used to locate and download the most recent cumulative update.
    The script will download and install this module from the PSGallery if it is not already installed.


.EXAMPLE
    New-WimImage -Verbose

    This command uses the default parameters to create a .wim image file in the C:\MDT-Capture folder using a .iso file, applications and cumulative update from the C:\Media folder
.EXAMPLE
    New-WimImage -MediaLocation C:\Temp -MDTDeploymentShare F:\MDT-ReferenceImage

    This command creates a .wim image file in the F:\MDT-ReferenceImage folder using a .iso file, applications and cumulative update from the C:\Temp folder
.EXAMPLE
    New-WinImage -DoNotCreateVM

    This command tells the script to only create the deployment share and boot media.
#>

[CmdletBinding()]
param(
    [string]$MDTDeploymentShare = 'C:\MDT-Capture',
        
    [ValidateScript({Get-ChildItem -Path $_ -Recurse -Include *.iso})]
    [string]$MediaLocation = 'C:\Media'
    )

#Requires -RunAsAdministrator

# Is MDT workbench installed?
$MDTInstallDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Deployment 4').Install_Dir + 'Bin'
If(Test-Path $MDTInstallDir){
    Import-Module "$MDTInstallDir\MicrosoftDeploymentToolkit.psd1"
}
Else{
    Write-Warning 'Unable to locate the MDT PowerShell module. Please check the MDT workbench has been correctly installed.'
    Break
}

$timer = [system.diagnostics.stopwatch]::StartNew()
$Summary = @("`nScript summary`n--------------")
$MDTServer = $env:COMPUTERNAME
$OperatingSystemName = 'Windows 10'

# Dot source helper scripts
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$moduleLibPath = Join-Path -Path $moduleRoot -ChildPath 'Lib'
$ConfigPath = Join-Path -Path $moduleRoot -ChildPath 'Config'
Get-ChildItem -Path $moduleLibPath -Include *.ps1 -Recurse |
    ForEach-Object {
        Write-Verbose -Message ('Importing library\source file ''{0}''.' -f $_.FullName);
        ## https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
        . ([System.Management.Automation.ScriptBlock]::Create(
                [System.IO.File]::ReadAllText($_.FullName)
            ));
    }

# Select .wim file to import for task sequence
Write-Verbose 'Mounting .iso file'
$ISOSource = Get-ChildItem -Path $medialocation -Include '*.iso' -Recurse
If($ISOSource.count -gt 1){
    for($i=0;$i -lt $ISOSource.Count;$i++){
        "$($i+1)`t$($ISOSource[$i].PSChildName)"
    }
    Do{
        [int]$ISOFile = Read-Host "`nFound more than one .iso file in $MediaLocation, please select which one you wish to open" 
    }
    While(1..$ISOSource.count -notcontains $ISOFile)
    $ISOSource = $ISOSource[($ISOFile-1)]
    Write-Verbose "$ISOSource has been chosen"
}
Mount-ISO -ISOSource $ISOSource

# Select operating system image
$images = Get-WindowsImage -ImagePath "$FileSource\sources\install.wim"
$OperatingSystemVersion = (Get-WindowsImage -ImagePath "$FileSource\sources\install.wim" -Index 1).Version.Split('.')[2]
If($images.Count -gt 1){
    Write-Output "Images found in the $OperatingSystemName-$OperatingSystemVersion.iso file`n"
    for($i=0;$i -lt $images.Count;$i++){
        "$($i+1)`t$($images[$i].ImageName)"
    }
    Do{
        [int]$SKU = Read-Host "`nWhich operating system image do you wish to use"
    }
    While(1..$images.Count -notcontains $SKU)
    $ISOImage = $images[($SKU-1)]
    Write-Verbose "Creating a $($ISOImage.ImageName) reference image"
}

# Create VM to be used as capture machine
Configure-VM -Prepare -Verbose

# Verify applications are downloaded
If(Test-Path $ConfigPath\AppsToInstall.csv){
    Write-Verbose 'Checking all required applications are present'
    $Applications = Import-Csv -Path $ConfigPath\AppsToInstall.csv
    Prepare-Applications -Verbose
}

# Verify latest cumulative update is downloaded
Write-Verbose 'Downloading latest cumulative update'
Prepare-Updates -Verbose

# Create MDT-Capture local account
Create-LocalUser -LocalUserName 'MDT-Capture' -LocalUserPassword 'Pa55word'

# Create deployment share
If(Test-Path $MDTDeploymentShare){
    Write-Verbose "Found an existing deployment share at $MDTDeploymentShare, this will now be removed"
    Remove-Item -Path $MDTDeploymentShare -Recurse -Force
    Write-Verbose "$MDTDeploymentShare has been removed"
}
New-Item -Path $MDTDeploymentShare -ItemType Directory | Out-Null
$MDTShareName = $MDTDeploymentShare.Split('\')[1] + '$'
If(-not(Get-SmbShare | where {$_.Path -eq $MDTDeploymentShare})){
    $MDTShare = New-SmbShare -Name $MDTShareName -Path $MDTDeploymentShare -FullAccess Administrators -ChangeAccess Everyone
}
Write-Verbose "New deployment share created at $MDTDeploymentShare, shared as $MDTShareName"

# Import module and create PSDrive
Import-Module "$MDTInstallDir\MicrosoftDeploymentToolkit.psd1"
$DSName = 'DS999'
If(Get-PSDrive | where {$_.Name -eq $DSName}){
    $PSDrive = @{Name = $DSName
                 Force = $true}
    Remove-PSDrive @PSDrive
}
New-PSDrive -Name $DSName -PSProvider MDTProvider -Root $MDTDeploymentShare -Description "MDT Reference Image" -NetworkPath "\\$MDTServer\$MDTShareName" -Verbose | Add-MDTPersistentDrive -Verbose

# Set permissions on the deployment share
$SID = (Get-LocalUser -Name $MDTUserName).SID
icacls $MDTDeploymentShare /grant '"Users":(OI)(CI)(RX)'
icacls $MDTDeploymentShare /grant '"Administrators":(OI)(CI)(F)'
icacls $MDTDeploymentShare /grant '"SYSTEM":(OI)(CI)(F)'
icacls $MDTDeploymentShare\Captures /grant ""*$($SID)":(OI)(CI)(M)"

# Create folder to import the operating system into
New-Item -path "$($DSName):\Operating Systems" -enable "True" -Name "$OperatingSystemName-$OperatingSystemVersion" -Comments "$OperatingSystemName-$OperatingSystemVersion" -ItemType "folder" -Verbose

# Import operating system
$OSFolderPath = "$($DSName):\Operating Systems\$OperatingSystemName-$OperatingSystemVersion"
Import-MDTOperatingSystem -path $OSFolderPath -SourcePath $FileSource -DestinationFolder "$OperatingSystemName-$OperatingSystemVersion" -Verbose
$TSWim = "$($ISOImage.ImageName) in $OperatingSystemName-$OperatingSystemVersion install.wim"
Write-Verbose "$TSWim to be used as the operating system image, all other images will be removed from the folder"
Remove-Item -Path $OSFolderPath\*.wim -Exclude $TSWim
Mount-ISO -ISOSource $ISOSource -Action Dismount
  
# Import latest cumulative update package
If(Get-Item -Path "$MediaLocation\Updates\*" -Include *.msu,*.cab -ErrorAction SilentlyContinue){
    Import-MDTPackage -path "$($DSName):\Packages" -SourcePath "$MediaLocation\Updates" -Verbose -ErrorAction Stop
}

# Create a reference image task sequence
Import-MDTTaskSequence -path "$($DSName):\Task Sequences" -Name "$OperatingSystemName $OperatingSystemVersion Reference image" -Template "Client.xml" -Version "1.0" -OperatingSystemPath "$($DSName):\Operating Systems\$OperatingSystemName-$OperatingSystemVersion\$TSWim" -Comments "$OperatingSystemName $OperatingSystemVersion reference image" -ID "RefImg" -Verbose

# Import applications
foreach($app in $Applications){
    $Path = Get-ChildItem -Path "$MediaLocation\Applications\$($app.Name)\*" -Include *.exe
    $SourcePath = $Path.Directory
    $ExecutableName = Split-Path $Path.FullName -Leaf
    $AppCommandLine = $ExecutableName + ' ' + $app.Silent
    Import-MDTApplication -path "$($DSName):\Applications" -enable "True" -Name $app.FullName -ShortName $app.Name -Publisher "Microsoft" -Language "" -CommandLine "$AppCommandLine" -WorkingDirectory ".\Applications\$($app.Name)" -ApplicationSourcePath $SourcePath -DestinationFolder $app.Name -Verbose
}

Write-Output 'Generating bootstrap.ini and customsettings.ini'
# Generate bootstrap.ini and customsettings.ini
$Bootstrap = @"
[Settings]
Priority=MACAddress,Default

[$MACAddress]
OSDAdapter0EnableDHCP=FALSE
OSDAdapterCount=1
OSDAdapter0IPAddressList=$VMIPAddress
OSDAdapter0SubnetMask=$SubnetMask

[Default]
DeployRoot=\\$MDTServer\$MDTShareName
UserDomain=$MDTServer
UserID=$MDTUserName
UserPassword=$MDTPassword
KeyboardLocalePE=0809:00000809
SkipBDDWelcome=YES

"@ | Out-File "$MDTDeploymentShare\Control\Bootstrap.ini" -Encoding ascii

$CSini = @"
[Settings]
Priority=Default

[Default]
_SMSTSOrgName=Running $OperatingSystemName Reference Image Capture
_SMSTSPackageName=$OperatingSystemName v$OperatingSystemVersion
UserDataLocation=NONE
ComputerBackupLocation=NETWORK 
DoCapture=YES
OSInstall=Y
AdminPassword=Pa55word
TimeZoneName=GMT Standard Time
JoinWorkgroup=WORKGROUP
HideShell=NO
DoNotCreateExtraPartition=YES
ApplyGPOPack=NO
SkipBDDWelcome=YES
SkipAdminPassword=YES
SkipProductKey=YES
SkipComputerName=YES
SkipDomainMembership=YES
SkipUserData=YES
SkipLocaleSelection=YES
KeyboardLocale=0809:00000809
UserLocale=en-GB
UILanguage=en-GB
SkipPackageDisplay=YES
SkipTaskSequence=YES
TaskSequenceID=REFIMG
SkipTimeZone=YES
SkipApplications=YES
SkipBitLocker=YES
SkipSummary=YES
SkipRoles=YES
SkipCapture=YES
BackupShare =\\$MDTServer\$MDTShareName
BackupDir=Captures
BackupFile=$($OperatingSystemName.Replace(' ',''))-$OperatingSystemVersion-#day(date) & "-" & month(date) & "-" & year(date)#.wim
SkipFinalSummary=YES
FinishAction=SHUTDOWN
"@ | Out-File "$MDTDeploymentShare\Control\CustomSettings.ini" -Encoding ascii

# Add OS features
If(Test-Path -Path $ConfigPath\OSFeatures.txt){
    $OSFeatures = Get-Content -Path $ConfigPath\OSFeatures.txt
    $FeatureList = $OSFeatures -join ','
    "`rOSFeatures=$FeatureList" | Out-File -FilePath "$MDTDeploymentShare\Control\CustomSettings.ini" -Encoding ascii -Append
}

# Add applications to customsettings as mandatory applications
$appxml = Get-Item -Path "$MDTDeploymentShare\Control\Applications.xml"
do{
    Start-Sleep -Seconds 2
}
until ($appxml.Length -gt 1024)
Write-Output 'Adding mandatory applications to customsettings.ini'
[xml]$applicationlist = (Get-Content -Path "$MDTDeploymentShare\Control\Applications.xml")
$applications = $applicationlist.applications.application
for ($i = 0; $i -lt $applications.Count; $i++){ 
    $AppNumber = "{0:000}" -f  ($i+1)
    "`rMandatoryApplications$AppNumber=$($applications[$i].guid)" | Out-File -FilePath "$MDTDeploymentShare\Control\CustomSettings.ini" -Encoding ascii -Append
}

# Update deployment share to create boot media
Write-Output "Updating $MDTDeploymentShare deployment share"
# Remove MDAC components from WinPE and set driver injection selection profile to Nothing - this will prevent the CU from being injected into the WinPE boot image
If(-not(Test-Path $MDTDeploymentShare\Control\Settings.xml)){
    Start-Process "$MDTInstallDir\DeploymentWorkbench.msc"
    do{
        Start-Sleep -Seconds 2
    }
    until (Test-Path $MDTDeploymentShare\Control\Settings.xml)
    Stop-Process -Name 'mmc'
}
[xml]$Settings = Get-Content -Path $MDTDeploymentShare\Control\Settings.xml
$Settings.Settings.'Boot.x64.FeaturePacks' = ''
$Settings.Settings.'Boot.x64.SelectionProfile' = 'Nothing'
$Settings.Settings.'Boot.x86.FeaturePacks' = ''
$Settings.Settings.'Boot.x86.SelectionProfile' = 'Nothing'
$Settings.Save("$MDTDeploymentShare\Control\Settings.xml")
Update-MDTDeploymentShare -Path "$DSName`:" -Force
Write-Verbose 'Deployment share has been updated'
$Summary += "`nTask sequence and boot media created"

# Wait until Lite TouchPE boot image .iso is created
do{
    Start-Sleep -Seconds 20
}
until (Get-Item -Path $MDTDeploymentShare\Boot\*iso)
Write-Output 'Deployment share and boot media have been created'

# Add .iso to virtual machine DVD drive and start the VM
Set-VMDvdDrive -VMName $VMName -Path (Get-Item -Path $MDTDeploymentShare\Boot\LiteTouchPE_x86.iso)
Start-VM -VMName $VMName
Write-Output 'Creating reference image'
# Wait until .wim file is generated
do{
    Write-Progress -Activity 'Generating reference image on virtual machine' -PercentComplete -1
    Start-Sleep -Seconds 20
}
until((Get-VM -Name $VMName).State -eq 'Off')
Write-Progress -Activity 'Generating reference image on virtual machine' -Completed
Configure-VM -CleanUp -Verbose
Remove-LocalUser -Name $MDTUserName
Write-Verbose "Local user account $MDTUserName has been removed"
If(Test-Path $MDTDeploymentShare\Captures\*.wim){
    $Summary += "Customized .wim file created"
    # Mount wim file, remove appx packages
    If(Test-Path $ConfigPath\AppsToRemove.txt){
        Write-Output 'Reference image has now been created, AppxProvisioned packages will now be removed'
        Remove-AppXPackagesFromWim -WimFile (Get-Item -Path $MDTDeploymentShare\Captures\*.wim).FullName -AppsToRemove "$ConfigPath\AppsToRemove.txt" -MountPath "$MediaLocation\OfflineWim" -Index 1 -LogFile "$MediaLocation\Remove-AppxPackages.log" -Verbose
        $Summary += "AppxProvisioned packages removed from .wim file"
    }
}
Else{
    Write-Warning 'Unable to locate a .wim file to mount'
}

$timer.Stop()
$Summary += ('Total time taken to create image was {0:0} minutes' -f $timer.Elapsed.TotalMinutes)
Write-Output $Summary