#------------------------------------------------------------------------------
#
#    Script Pour les postes Windows 10 pour faire du kiosk
#    Creation le : 20/09/2019
#    Modification le : 20/09/2019
#
#------------------------------------------------------------------------------
#

# Declaration des Variable
$CompN = Read-Host "Entrez un nom d'ordinateur :"
$Password = Read-Host "Entrez un Mot de passe pour le compte Kiosk :"

# Activation du remote Powershell
Enable-PSRemoting -Force

# Creation Compte Utilisateur
New-LocalUser "kiosk" -Password $Password -FullName "kiosk" -Description "Compte local Kiosk"

# Rename Computer name
Rename-Computer -NewName $CompN
Set-TimeZone "Romance Standard Time"

# Modification de la Base de registre
$RegKey ="HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $RegKey -Name AutoAdminLogon  -Value 1
Set-ItemProperty -Path $RegKey -Name DefaultUserName -value "kiosk"
Set-ItemProperty -Path $RegKey -Name PasswordExpiryWarning -value 0
New-Item -Path $RegKey -Value “DefaultPassword”
Set-ItemProperty -Path $RegKey -Name DefaultPassword -value $Password

# Telechargement et installation de Chrome
$Path = $env:TEMP
$Installer = "chrome_installer.exe"
Invoke-WebRequest "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $Path\$Installer
Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait
Remove-Item $Path\$Installer

# Telechargement et installation TightVNC
$Path = $env:TEMP
$Installer = "tightvnc-2.8.11-gpl-setup-64bit.msi"
Invoke-WebRequest "https://www.tightvnc.com/download/2.8.11/tightvnc-2.8.11-gpl-setup-64bit.msi" -OutFile $Path\$Installer
Start-Process -FilePath $Path\$Installer -Args "/quiet /norestart" -Verb RunAs -Wait
Remove-Item $Path\$Installer

# Creation du liens de demarrage
$lnk1Path = "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$exe1path = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
New-Item -ItemType SymbolicLink -Path $lnk1Path -Name "chrome.lnk" -Value $exe1path & " --kiosk http://play.playr.biz"

# PowerManagement
Configuration ConfigureAdapterPowerManagement 
{ 
    Param 
    ( 
        #Target nodes to apply the configuration   
        [String[]]$ComputerName = $env:COMPUTERNAME 
    ) 
     
    Import-DSCResource -ModuleName xNetAdapterPowerManagement 
  
    Node $ComputerName 
    { 
        xNetAdapterPowerManagement AdapterPowerManagementExample 
        { 
            TurnOffDeviceSavePower = "Disable" 
            WakeUpComputer = "Enable" 
        } 
    } 
} 
  
ConfigureAdapterPowerManagement 
Start-DscConfiguration -Path .\ConfigureAdapterPowerManagement -Wait -Force -Verbose

# Desactivation Windows Update
sc.exe config wuauserv start=disabled


# Reboot du poste
shutdown /r /t:45

