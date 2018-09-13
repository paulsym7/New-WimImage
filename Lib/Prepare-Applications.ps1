Function Prepare-Applications{
    <#
        .SYNOPSIS
            Download .NET Framework 4.7.2, Silverlight, x86 and x64 version of visual studio C++ 2005, 2008, 2010, 2012, 2013, 2015 and 2017.
    #>

    [CmdletBinding()]
    param()
    
    $AppsFoler = "$MediaLocation\Applications"
    If(-not(Test-Path $AppsFoler)){
        New-Item -Path $AppsFoler -ItemType Directory | Out-Null
    }

    # Applications: C++ 2005, 2008, 2010, 2012, 2013, 2015, 2017, Silverlight, .NET Framework 4.7.2
    $AppHashTable = @{'2005x64' = 'https://download.microsoft.com/download/d/3/4/d342efa6-3266-4157-a2ec-5174867be706/vcredist_x86.exe'
                      '2005x86' = 'https://download.microsoft.com/download/d/4/1/d41aca8a-faa5-49a7-a5f2-ea0aa4587da0/vcredist_x64.exe'
                      '2008x64' = 'https://download.microsoft.com/download/d/d/9/dd9a82d0-52ef-40db-8dab-795376989c03/vcredist_x86.exe'
                      '2008x86' = 'https://download.microsoft.com/download/2/d/6/2d61c766-107b-409d-8fba-c39e61ca08e8/vcredist_x64.exe'
                      '2010x64' = 'https://download.microsoft.com/download/A/8/0/A80747C3-41BD-45DF-B505-E9710D2744E0/vcredist_x64.exe'
                      '2010x86' = 'https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe'
                      '2012x64' = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'
                      '2012x86' = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'
                      '2013x64' = 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe'
                      '2013x86' = 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe'
                      '2015x64' = 'https://download.microsoft.com/download/6/D/F/6DF3FF94-F7F9-4F0B-838C-A328D1A7D0EE/vc_redist.x64.exe'
                      '2015x86' = 'https://download.microsoft.com/download/6/D/F/6DF3FF94-F7F9-4F0B-838C-A328D1A7D0EE/vc_redist.x86.exe'
                      '2017x64' = 'https://aka.ms/vs/15/release/vc_redist.x64.exe'
                      '2017x86' = 'https://aka.ms/vs/15/release/vc_redist.x86.exe'
                      'Silverlight' = 'http://go.microsoft.com/fwlink/?LinkID=229321'
                      'NETFramework472' = 'http://go.microsoft.com/fwlink/?linkid=863265'}

    foreach($Application in $AppHashTable.Keys){
        If(-not(Test-Path $AppsFoler\$Application)){
            Write-Verbose "Creating a folder for $Application"
            New-Item -Path $AppsFoler\$Application -ItemType Directory | Out-Null
        }
        If(-not(Get-Item -Path $AppsFoler\$Application\*.exe)){
            Write-Verbose "No executable found in the $Application folder, will attempt to download"
            $URL = $AppHashTable.$Application
            $Path = "$AppsFoler\$Application\$Application.exe"
            Download-File -URL $URL -Path $Path -Verbose
        }
    }
}