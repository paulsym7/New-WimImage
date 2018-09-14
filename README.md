# New-WimImage
The New-WimImage.ps1 script will create a customized .wim image patched with the latest OS cumulative update and containing the following applications:

Microsoft C++ redistributables, x86 and x64 versions from 2005 to 2017
Silverlight
.NET Framework 4.7.2

If a list of AppxProvisionedPackages is provided, the script will mount the customized .wim and remove all listed packages from the .wim

Applications and cumulative update will be downloaded if they are not found in the media location folder.
Aaron Parker's LatestUpdate module (https://github.com/aaronparker/LatestUpdate) is used to locate and download the cumulative update, the script will be download and install this module from the PSGallery if it is not already installed.

Script actions:
---------------
Creates a local user account to connect to MDT deployment share
Creates a MDT deployment share
Imports operating system
Imports applications
Imports latest OS cumulative update
Creates task sequence
Customizes bootstrap.ini
Customizes customsettings.ini to install OS features and applications during the task sequence

Creates a Hyper-V virtual machine to capture the image on
Uses MDT boot media to connect to MDT deployment share
Installs operating system, cumulative update, features and applications
Syspreps machine and captures .wim
Virtual machine and local user account are then deleted

Mounts .wim file and removes any unwanted AppxProvisionedPackages

Script prerequisites:
---------------------
Hyper-V installed
Latest version of Windows ADK installed

Script usage:
-------------
The script takes parameters to define the media location - where the .iso file can be found, and the MDT deployment share to be created

New-WimImage -MediaLocation C:\Downloads -MDTDeploymentShare D:\MDT-Capture
