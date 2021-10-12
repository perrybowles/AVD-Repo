## Use this version when calling from an ARM Template ##
## Use the version AddVM2HostPool.ps1 as a standalone script run from the VM ##

##############################
#    AVD Script Parameters   #
##############################
Param (        
    [Parameter(Mandatory=$true)]
        [string]$RegistrationToken,
    [Parameter(Mandatory=$false)]
        [string]$Optimize
)
Add-Content -LiteralPath C:\New-AVDSessionHost.log $RegistrationToken
Add-Content -LiteralPath C:\New-AVDSessionHost.log ""
######################
#    AVD Variables   #
######################
$LocalAVDpath      = "c:\temp\AVD\"
$AVDBootURI        = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$AVDAgentURI       = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$AVDAgentInstaller = 'AVD-Agent.msi'
$AVDBootInstaller  = 'AVD-Bootloader.msi'

####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}
if((Test-Path $LocalAVDpath) -eq $false) {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Create C:\temp\AVD Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating c:\temp\AVD directory"
    New-Item -Path $LocalAVDpath -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "C:\temp\AVD Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "c:\temp\AVD directory already exists"
}

#################################
#    Download AVD Components    #
#################################
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Downloading AVD Boot Loader"
    Invoke-WebRequest -Uri $AVDBootURI -OutFile "$LocalAVDpath$AVDBootInstaller"
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Downloading AVD Agent"
    Invoke-WebRequest -Uri $AVDAgentURI -OutFile "$LocalAVDpath$AVDAgentInstaller"

################################
#    Install AVD Components    #
################################
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Installing AVD Agent"
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"
Stop-Service -Name 'RdAgent'
$agent_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $LocalAVDpath\$AVDAgentInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "REGISTRATIONTOKEN=$RegistrationToken", "/l* $LocalAVDpath\AgentInstall.txt" `
    -Wait `
    -Passthru
Add-Content -LiteralPath C:\New-AVDSessionHost.log "AVD Agent Install Complete"
Wait-Event -Timeout 5
Start-Service -Name 'RdAgent'

Add-Content -LiteralPath C:\New-AVDSessionHost.log "Installing AVD Bootloader"
$bootloader_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $LocalAVDpath\$AVDBootInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "/l* $LocalAVDpath\AgentBootLoaderInstall.txt" `
    -Wait `
    -Passthru
$sts = $bootloader_deploy_status.ExitCode
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Installing AVD Bootloader Complete"
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
Wait-Event -Timeout 5
Start-Service -Name 'RDAgentBootLoader'

#Set the execution policy to default for current user
Set-ExecutionPolicy -ExecutionPolicy default -scope currentuser -Force

##########################################
#    Enable Screen Capture Protection    #
##########################################
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Enable Screen Capture Protection"
Push-Location 
Set-Location "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
New-ItemProperty `
    -Path .\ `
    -Name fEnableScreenCaptureProtection `
    -Value "1" `
    -PropertyType DWord `
    -Force
Pop-Location


##############################################
#    AVD Optimizer (Virtual Desktop Team)    #
##############################################
If ($Optimize -eq $true) {  
    Write-Output "Optimizer selected"
    [Cmdletbinding()]
Param (
    [ValidateSet('All','WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup')] 
    [String[]]
    $Optimizations = "All"
)
    ################################
    #    Download AVD Optimizer    #
    ################################
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Optimize Selected"
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Creating C:\Optimize folder"
    New-Item -Path C:\ -Name Optimize -ItemType Directory -ErrorAction SilentlyContinue
    $LocalPath = "C:\Optimize\"
    $AVDOptimizeURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
    $AVDOptimizeInstaller = "Windows_10_VDI_Optimize-master.zip"
    Invoke-WebRequest `
        -Uri $AVDOptimizeURL `
        -OutFile "$Localpath$AVDOptimizeInstaller"


    ###############################
    #    Prep for AVD Optimize    #
    ###############################
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Optimize downloaded and extracted"
    Expand-Archive `
        -LiteralPath "C:\Optimize\Windows_10_VDI_Optimize-master.zip" `
        -DestinationPath "$Localpath" `
        -Force `
        -Verbose

    #################################
    #    Run AVD Optimize Script    #
    #################################
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Begining Optimize"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
    .\Win10_VirtualDesktop_Optimize.ps1 -Optimizations $Optimizations -Restart -AcceptEULA -Verbose
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Optimization Complete"
}
else {
    Write-Output "Optimize not selected"
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Optimize NOT selected"    
}
    #Add the local "Administrators" group to the local "FSLogix Profile Exclude List" group
    Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member "Administrators"

#######################################
#  Set the region and timezone again  #
#######################################
    net use Z: \\zipscripts.file.core.windows.net\sw-repo aopmUsV/SF1bnBZXln7wCK//eq2pQLZgIJGeaiJOLHt3nlv6A+FJjIpRkfH7vDZ8ej62t3pZv6iDmD/s6XELeA== /user:localhost\zipscripts /persistent:no
    # Set UK timezone
    Set-TimeZone "GMT Standard Time"

    # Set UK locale, language etc. for current user
    Set-WinHomeLocation -GeoId 242 #sets the "Country or Region" (Location) to UK
    Set-Culture en-GB # sets the "Regional Format" (Format) to UK
    New-WinUserLanguageList -Language en-GB
    Set-WinUserLanguageList -LanguageList en-GB -Force #sets "Windows display", "Apps & websites" and "Keyboard" (Input language) to UK
    Set-WinUILanguageOverride -Language en-GB #overrides the "Windows display" (Display language) but not the "Keyboard" (Input language), or "Regional format" (Format) with UK region
    Set-WinSystemLocale -SystemLocale en-GB #sets the System-locale code pages, which include ANSI, DOS, and Macintosh, to UK. Requires admin privelages and a reboot

    #Copy current user's region settings to System & Default users + Welcome screen
    #Start-Sleep 5
    & $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"Z:\Scripts\en-GB\CopyRegion.xml`""

    #Delete drive mapping and D:\LangPack folder
    net use Z: /delete /y
    remove-item -path d:\LangPack -recurse

##########################
#    Restart Computer    #
##########################
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Process Complete - REBOOT"
    Shutdown /r /t 0
