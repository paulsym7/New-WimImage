# New-WimImage
The New-WimImage.ps1 script will create a customized .wim image patched with the latest OS cumulative update and containing a pre-determined list of applications.

Script prerequisites:
---------------------
Hyper-V installed
Latest version of Windows ADK installed

Applications, Windows features and updates:
-------------------------------------------
If an AppsToInstall.csv file is placed in the config folder, the script will install these applications during the task sequence.
Note, the application must have a silent install switch and the script currently only supports .exe files.
    
Applications not found in the media location folder will be downloaded using the URL provided in the AppsToInstall.csv file.
    
If an AppsToRemove.txt file is placed in the config folder, the script will mount the customized .wim and remove all listed packages from the .wim
Use the (Get-AppxProvisionedPackage -Online).DisplayName command to discover the correct name format for packages to remove.

If an OSFeatures.txt file is placed in the config folder, the script will install all features listed in the file.
Use the (Get-WindowsOptionalFeature -Online).FeatureName command to discover the correct name format for the Windows features. 

Aaron Parker's LatestUpdate module is used to locate and download the most recent cumulative update.
The script will download and install this module from the PSGallery if it is not already installed.

Script usage:
-------------
The script takes parameters to define the media location - where the .iso file can be found, and the MDT deployment share to be created

New-WimImage -MediaLocation C:\Downloads -MDTDeploymentShare D:\MDT-Capture
