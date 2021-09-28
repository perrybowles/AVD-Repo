####################################################################
# Install UK Language Pack & features and set Region and Time Zone #
####################################################################

# copy language files to "D:\LangPack" folder (temp drive)
net use F: \\zipscripts.file.core.windows.net\sw-repo aopmUsV/SF1bnBZXln7wCK//eq2pQLZgIJGeaiJOLHt3nlv6A+FJjIpRkfH7vDZ8ej62t3pZv6iDmD/s6XELeA== /user:localhost\zipscripts /persistent:no
copy-item -path F:\LangPack\ -destination D:\ -recurse

# Disable Language Pack cleanup
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"

# Set Language Pack Content Stores
[string]$LIPContent = "D:\LangPack"

# Add English (United Kingdom) language packs and features
Add-AppProvisionedPackage -Online -PackagePath $LIPContent\en-gb\LanguageExperiencePack.en-gb.Neutral.appx -LicensePath $LIPContent\en-gb\License.xml
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-Client-Language-Pack_x64_en-gb.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Basic-en-gb-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Handwriting-en-gb-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-OCR-en-gb-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-Speech-en-gb-Package~31bf3856ad364e35~amd64~~.cab
Add-WindowsPackage -Online -PackagePath $LIPContent\Microsoft-Windows-LanguageFeatures-TextToSpeech-en-gb-Package~31bf3856ad364e35~amd64~~.cab

# Set UK timezone
Set-TimeZone "GMT Standard Time"

# Set UK locale, language etc. for current user
New-WinUserLanguageList -Language en-GB
Set-WinUILanguageOverride -Language en-GB
Set-WinDefaultInputMethodOverride -InputTip "0809:00000809"
Set-WinSystemLocale -SystemLocale en-GB
Set-WinUserLanguageList -LanguageList en-GB -Force
Set-WinHomeLocation -GeoId 242
Set-Culture en-GB

#Copy current user's region settings to System & Default users + Welcome screen
Start-Sleep 5
& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"F:\Scripts\en-GB\CopyRegion.xml`""

#Delete drive mapping and D:\LangPack folder
#net use f: /delete /y
remove-item -path d:\LangPack -recurse

#Set the execution policy to default for current user
Set-ExecutionPolicy -ExecutionPolicy default -scope currentuser -Force

#Reboot immediately
shutdown /r /t 0
