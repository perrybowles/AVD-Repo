#########################
#    Install AZ Module  #
#########################
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -force
#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
#Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
#Install-Module -Name Az -AllowClobber -Scope CurrentUser -Repository PSGallery 
#connect-AzAccount

##############################
#    WVD Script Parameters   #
##############################
Param (        
    [Parameter(Mandatory=$true)]
        [string]$HostPoolRgName,
    [Parameter(Mandatory=$true)]
        [string]$HostPoolName,
    [Parameter(Mandatory=$false)]
        [string]$Optimize
)

######################
#    AVD Variables   #
######################
$LocalAVDpath      = "c:\temp\AVD\"
$AVDBootURI        = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$AVDAgentURI       = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$AVDAgentInstaller = 'AVD-Agent.msi'
$AVDBootInstaller  = 'AVD-Bootloader.msi'
$HostPoolRgName    = 'ZIP_AVD_HostPools_RG'
$HostPoolName      = 'ZIP-AVD-HostPool-01'
$RegistrationToken = New-AzWvdRegistrationInfo -ResourceGroupName $HostPoolRgName `
    -HostPoolName $HostPoolName `
    -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')) `
    | Select-Object -ExpandProperty Token
    Add-Content -LiteralPath C:\temp\New-AVDSessionHost.log $HostPoolRgName
    Add-Content -LiteralPath C:\temp\New-AVDSessionHost.log $HostPoolName
    Add-Content -LiteralPath C:\temp\New-AVDSessionHost.log $RegistrationToken

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