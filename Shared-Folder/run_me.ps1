﻿#C:\Users\Arthur\Downloads\Kali Linux 2024.1 (64bit).vdi
#C:\Users\Arthur\Downloads/Ubuntu Server 23.04 (64bit).vdi
#C:\Users\Arthur\Downloads\Debian 11 Server (64bit).vdi
#C:\Users\Arthur\Documents\Github\CSV-2024\Shared-Folder
# Functie om het absolute pad van een bestand te krijgen
write-host "-----------------VM CREATOR-----------------"
function Get-AbsolutePath {
    param([string]$Path)
    $AbsolutePath = Convert-Path $Path
    return $AbsolutePath
}

# Functie om een geldig pad te verkrijgen
function Get-ValidPath {
    param([string]$Prompt)
    $Path = Read-Host $Prompt
    while (-not (Test-Path $Path)) {
        Write-Host "!!!!!!!!!!!!!!Het opgegeven pad is ongeldig. Probeer het opnieuw.!!!!!!!!!!!!!"
        $Path = Read-Host $Prompt
    }
    return (Get-AbsolutePath -Path $Path)
}

# Vraag om het absolute pad van het Kali Linux VDI-bestand
$KaliLinuxVDIPath = Get-ValidPath -Prompt "Geef het absolute pad van het Kali Linux VDI-bestand in"

# Vraag om het absolute pad van het Ubuntu Server VDI-bestand
$UbuntuServerVDIPath = Get-ValidPath -Prompt "Geef het absolute pad van het Ubuntu Server VDI-bestand in"

# Vraag om het absolute pad van het DebianServer VDI-bestand
$DebianServerVDIPath = Get-ValidPath -Prompt "Geef het absolute pad van het DebianServer VDI-bestand in"

# Vraag om het absolute pad van de gedeelde map
$SharedFolderPath = Get-ValidPath -Prompt "Geef het absolute pad van de gedeelde map in"

#-------------------------------------------------------------------------------------ADAPTER OPTIE MENU--------------------------------------------------------------------------------------------------------------


# Lijst van bridged network interfaces ophalen en filteren op naam
$bridgedInterfaces = VBoxManage list bridgedifs | Select-String "Name:" | ForEach-Object { $_.ToString().Trim() -replace '^Name:\s+' }

# Controleren of er bridged interfaces zijn
if ($bridgedInterfaces) {
    # Lijst tonen met nummering
    $index = 1
    foreach ($interface in $bridgedInterfaces) {
        Write-Host "$index. $interface"
        $index++
    }

    # Gebruikerskeuze
    $choice = $null
    while (-not ([int]::TryParse($choice, [ref]$null) -and [int]$choice -ge 1 -and [int]$choice -le $bridgedInterfaces.Count)) {
        Write-Host "Geef uw effectie Netwerk adapter die u wilt gebruiken om op internet mee te verbinden."
        $choice = Read-Host "Kies een nummer voor de bridged interface (1-$($bridgedInterfaces.Count))"
        if (-not ([int]::TryParse($choice, [ref]$null))) {
            Write-Host "Ongeldige invoer. Voer een nummer in."
        } elseif ([int]$choice -lt 1 -or [int]$choice -gt $bridgedInterfaces.Count) {
            Write-Host "Ongeldige invoer. Voer een nummer in tussen 1 en $($bridgedInterfaces.Count)."
        }
    }

    # Keuze toewijzen aan variabele
    $selectedInterface = $bridgedInterfaces[[int]$choice - 1]
} else {
    Write-Host "Er zijn geen bridged interfaces gevonden."
}

#-------------------------------------------------------------------------------------EINDE---ADAPTER OPTIE MENU--------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------OPSTARTEN EN AANMAKEN VM'S--------------------------------------------------------------------------------------------------------------
Write-Host "installeren dependencys powershell lokaal!"
Install-Module -Name Posh-SSH -Scope CurrentUser -Force
# Controleer of de Ubuntu Server VM al bestaat
$UbuntuVMExists = & VBoxManage showvminfo "Ubuntu server" --machinereadable 2>$null
if ($UbuntuVMExists) {
    Write-Host "De VM 'Ubuntu server' bestaat al."
} else {
    Write-Host "Aanmaken van Ubuntu server VM."
    VBoxManage createvm --name "Ubuntu server" --ostype "Linux_64" --register
    VBoxManage modifyvm "Ubuntu server" --memory 2048 --vram 256 --graphicscontroller vmsvga --draganddrop bidirectional --clipboard bidirectional --nic1 bridged --bridgeadapter1 $selectedInterface
    VBoxManage storagectl "Ubuntu server" --name "SATA Controller" --add sata
    VBoxManage storageattach "Ubuntu server" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $UbuntuServerVDIPath
    VBoxManage sharedfolder add "Ubuntu server" --name "gedeelde_map" --hostpath $SharedFolderPath --automount
}

# Controleer of de Debian Server VM al bestaat
$DebianServerVDIPathExist = & VBoxManage showvminfo "Debian server" --machinereadable 2>$null
if ($DebianServerVDIPathExist) {
    Write-Host "De VM 'Debian server' bestaat al."
} else {
    Write-Host "Aanmaken van Debian server VM."
    VBoxManage createvm --name "Debian server" --ostype "Linux_64" --register
    VBoxManage modifyvm "Debian server" --memory 2048 --vram 256 --graphicscontroller vmsvga --draganddrop bidirectional --clipboard bidirectional --nic1 bridged --bridgeadapter1 $selectedInterface
    VBoxManage storagectl "Debian server" --name "SATA Controller" --add sata
    VBoxManage storageattach "Debian server" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $DebianServerVDIPath
    VBoxManage sharedfolder add "Debian server" --name "gedeelde_map" --hostpath $SharedFolderPath --automount
}

# Controleer of de Kali Linux VM al bestaat
$kaliVMExists = & VBoxManage showvminfo "Kali Linux" --machinereadable 2>$null
if ($kaliVMExists) {
    Write-Host "De VM 'Kali Linux' bestaat al."
} else {
    Write-Host "Aanmaken van Kali Linux VM."
    VBoxManage createvm --name "Kali Linux" --ostype "Linux_64" --register
    VBoxManage modifyvm "Kali Linux" --memory 3048 --cpus 2 --vram 256 --graphicscontroller vmsvga --draganddrop bidirectional --clipboard bidirectional --nic1 bridged --bridgeadapter1 $selectedInterface
    VBoxManage storagectl "Kali Linux" --name "SATA Controller" --add sata
    VBoxManage storageattach "Kali Linux" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $KaliLinuxVDIPath
    VBoxManage sharedfolder add "Kali Linux" --name "gedeelde_map" --hostpath $SharedFolderPath --automount
}


# Controleer en start de Ubuntu Server VM
if ((& VBoxManage showvminfo "Ubuntu server" --machinereadable | Select-String "VMState" | ForEach-Object {$_ -match 'VMState="(.+?)"'; $Matches[1]}) -ne "running") {
    Write-Host "Ubuntu Server VM wordt gestart..."
    & VBoxManage startvm "Ubuntu server"
}
# Controleer en start de Debian Server VM
if ((& VBoxManage showvminfo "Debian server" --machinereadable | Select-String "VMState" | ForEach-Object {$_ -match 'VMState="(.+?)"'; $Matches[1]}) -ne "running") {
    Write-Host "Debian Server VM wordt gestart..."
    & VBoxManage startvm "Debian server"
}
# Controleer en start de Kali Linux VM
if ((& VBoxManage showvminfo "Kali Linux" --machinereadable | Select-String "VMState" | ForEach-Object {$_ -match 'VMState="(.+?)"'; $Matches[1]}) -ne "running") {
    Write-Host "Kali Linux VM wordt gestart..."
    & VBoxManage startvm "Kali Linux"
}
#-------------------------------------------------------------------------------------EINDE OPSTARTEN EN AANMAKEN VM'S--------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------WACHTEN TOT DE UBUNTU SERVER IS OPGESTART--------------------------------------------------------------------------------------------------------------
# Oneindige lus tot de VM Ubuntu server is opgestart
while ($true) {
    # Voer de VBoxManage-opdracht uit en leid de uitvoer naar $null
    $null = VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org'" --quiet --no-verbose >$null 2>&1
    
    # Controleer de exitcode van de opdracht
    if ($LASTEXITCODE -eq 0) {
        # Als de exitcode 0 is, betekent dit dat de opdracht succesvol is uitgevoerd
        Write-Host "Ubuntu server is opgestart!!!"
        break  # Verlaat de lus
    } else {
        # Als de exitcode niet 0 is, wacht een paar seconden voor een nieuwe poging
        Write-Host "Wachten tot Ubuntu server aan staat..."
        Start-Sleep -Seconds 5
    }
}
#------------------------------------------------------------------------------------- EINDE WACHTEN TOT DE UBUNTU SERVER IS OPGESTART--------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------INSTALEREN GUESTEDITIONS UBUNTU--------------------------------------------------------------------------------------------------------------
Write-Host "-------------------------------UPDATEN VAN GUEST EDITIONS UBUNTU SERVER------------------------------------------------"

Write-Host "---------------------Het IP-adres van de Ubuntu-server wordt opgehaald...-----------------------------------------------"
$ipAddressUbuntu = $(VBoxManage guestproperty get "Ubuntu server" "/VirtualBox/GuestInfo/Net/0/V4/IP").Replace("Value: ", "").Trim()
Write-Host "----------------------------------------------------IP-adres van Ubuntu server: $ipAddressUbuntu-----------------------------------"
$password = "osboxes.org" | ConvertTo-SecureString -AsPlainText -Force
#username voor ssh login
$username = "osboxes"
# Create credential object
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password 
# Initialize SSH session variable
$sshSession = $null
# Loop until SSH session is established without errors, oplossing voor random errors!!
while (-not $sshSession) {
    # Attempt to create SSH session
    $sshSession = New-SSHSession -ComputerName $ipAddressUbuntu -Credential $credential -Force -ErrorAction SilentlyContinue

}
# Create shell stream for command execution
$stream = $sshSession.Session.CreateShellStream("BASH-SHH", 0, 0, 0, 0, 100000)
write-host "--------------------------!!!!!!!!!!!SSH SESSION GESTART DIT KAN EVENTJES DUREN!!!!!!!!!!!----------------------------------------"
# Read initial data from the stream
$stream.ReadLine()
Start-Sleep -Seconds 1
Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for ${username}:" -SecureAction $password
Start-Sleep -Seconds 1
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "bash /media/sf_gedeelde_map/guestupdate.sh && echo 'PATSER'"
Start-Sleep -Seconds 1

$stream.Expect("PATSER")
# Remove the SSH session
Remove-SSHSession -SSHSession $sshSession
write-host "------------------------EINDE SSH SESSION WACHT OP REBOOT...---------------------------"
#-------------------------------------------------------------------------------------EINDE INSTALEREN GUESTEDITIONS UBUNTU--------------------------------------------------------------------------------------------------------------
#------------------------------WACHTEN TOT KALI LINUX ONLINE IS-----------------------------------------#
while ($true) {
    # Voer de VBoxManage-opdracht uit en leid de uitvoer naar $null
    $null = VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org'" --quiet --no-verbose >$null 2>&1
    
    # Controleer de exitcode van de opdracht
    if ($LASTEXITCODE -eq 0) {
        # Als de exitcode 0 is, betekent dit dat de opdracht succesvol is uitgevoerd
        Write-Host "Kali Linux is opgestart!!!"
        break  # Verlaat de lus
    } else {
        # Als de exitcode niet 0 is, wacht een paar seconden voor een nieuwe poging
        Write-Host "wachten tot Kali Linux server aan staat..."
        Start-Sleep -Seconds 5
    }
}
#------------------------------EINDE WACHTEN TOT KALI LINUX ONLINE IS-----------------------------------------#
#---------------------------------------------------------------- OPHALEN IP ADDRES DEBIAN SERVER============================================

write-host "--------------------installeren van software voor ophalen ip addres van Debian server adhv mac address----------------------------------------"
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S apt update -y && echo 'osboxes.org' | sudo -S apt install arp-scan -y"
Start-Sleep -Seconds 2
$ipAddressDebian = $false


while (!$ipAddressDebian) {
    Write-Host "Debian Server ip verkrijgen ..."
    $vmName = "Debian server"
    $DebianserverMacAddress = (VBoxManage showvminfo $vmName --machinereadable | Select-String "macaddress1=")
    $DebianserverMacAddress = $DebianserverMacAddress -replace 'macaddress1="', '' -replace '"', ''
    $DebianserverMacAddress = $DebianserverMacAddress.ToUpper() -replace '([A-F0-9]{2})', '$1-' -replace '-$', ''

    $ipAddressDebian = $(VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S arp-scan --destaddr=${DebianserverMacAddress} --localnet 2>/dev/null | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1}'")
    # Gebruik een reguliere expressie om het IP-adres te extraheren

    $ipAddressDebian = $ipAddressDebian -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
    Start-Sleep -Seconds 3

}


$ipAddressDebian = $matches[0]
Write-Host "IP-adres van Debian server: $ipAddressDebian"
#---------------------------------------------------------------- EINDE OPHALEN IP ADDRES DEBIAN SERVER============================================
#-------------------------------------------------------------------------------------INSTALEREN GUESTEDITIONS DEBIAN--------------------------------------------------------------------------------------------------------------

Write-Host "-------------------------------INSTALEREN VAN GUEST EDITIONS DEBIAN SERVER------------------------------------------------"
# Voer het Bash-script uit op de Linux VM met SSH en wachtwoord authenticatie

$guestupdatesh = Get-Content -Path "$SharedFolderPath/guestupdate.sh" -Raw
$password = "osboxes.org" | ConvertTo-SecureString -AsPlainText -Force
#username voor ssh login
$username = "osboxes"
# Create credential object
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password 

# Initialize SSH session variable
$sshSession = $null
# Loop until SSH session is established without errors, oplossing voor random errors!!
while (-not $sshSession) {
    # Attempt to create SSH session
    $sshSession = New-SSHSession -ComputerName $ipAddressDebian -Credential $credential -Force -ErrorAction SilentlyContinue

}
# Create shell stream for command execution
$stream = $sshSession.Session.CreateShellStream("BASH-SHH", 0, 0, 0, 0, 100000   )

write-host "--------------------------!!!!!!!!!!!!!SSH SESSION GESTART DIT KAN EVENTJES DUREN!!!!!!!!!!!!!------------------------------"
# Read initial data from the stream
$stream.Read()
Start-Sleep -Seconds 1
Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su - " -ExpectString "[sudo] password for ${username}:" -SecureAction $password
Start-Sleep -Seconds 1
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "echo '${guestupdatesh}' > /home/osboxes/guestupdate.sh"
Start-Sleep -Seconds 1
# Invoke-SSHStreamShellCommand -ShellStream $stream -Command "sudo apt install dos2unix -y &>/dev/null && sudo dos2unix /home/osboxes/guestupdate.sh"
# Start-Sleep -Seconds 1
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "chmod +x /home/osboxes/guestupdate.sh"
Start-Sleep -Seconds 1
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "bash /home/osboxes/guestupdate.sh && echo 'plopkoekkabouter'"
$stream.Expect("plopkoekkabouter")


# Remove the SSH session
Remove-SSHSession -SSHSession $sshSession
write-host "--------------------------------EINDE SSH SESSION WACHT OP REBOOT...---------------------"
#-------------------------------------------------------------------------------------EINDE INSTALEREN GUESTEDITIONS DEBIAN--------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------WACHTEN TOT UBUNTU SERVER IS OPGESTART--------------------------------------------------------------------------------------------------------------

# --------------------------Oneindige lus tot de VM is opgestart----------------------------
while ($true) {
    # Voer de VBoxManage-opdracht uit en leid de uitvoer naar $null
    $null = VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org'" --quiet --no-verbose >$null 2>&1
    
    # Controleer de exitcode van de opdracht
    if ($LASTEXITCODE -eq 0) {
        # Als de exitcode 0 is, betekent dit dat de opdracht succesvol is uitgevoerd
        Write-Host "Ubuntu server is opgestart!!!"
        break  # Verlaat de lus
    } else {
        # Als de exitcode niet 0 is, wacht een paar seconden voor een nieuwe poging
        Write-Host "Wachten tot Ubuntu server aan staat..."
        Start-Sleep -Seconds 5
    }
}
#-------------------------------------------------------------------------------------EINDE WACHTEN TOT UBUNTU SERVER IS OPGESTART--------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------uitvoeren van SCRIPTS WORDPRESS-----------------------------------------------------------------
write-host "---------------------------uitvoeren van script1.sh op Ubuntu server-----------------------------------------------------------------"
Start-Sleep -Seconds 5
VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S chmod +x /media/sf_gedeelde_map/script1.sh"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S  /media/sf_gedeelde_map/script1.sh"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S  /media/sf_gedeelde_map/script1.sh"
Start-Sleep -Seconds 2
# geef root rechten aan osboxes voor aanpasssen hosts file...
write-host "----------------------------------------rootpromotie.sh script kopieren naar Kali Linux----------------------------------------------------"
VBoxManage --nologo guestcontrol "Kali Linux" copyto "$SharedFolderPath/rootpromotie.sh" "/home/osboxes/rootpromotie.sh" --username osboxes --password osboxes.org

# Initialiseer de variabele $DOMAIN_NAME_CHAMILO
$DOMAIN_NAME= ""
write-host "---------------------------ophalen van domein naam van Ubuntu server-----------------------------------------------------------------"
# Voer het commando uit totdat $DOMAIN_NAME_CHAMILO niet meer leeg iss
while (-not $DOMAIN_NAME) {
    $DOMAIN_NAME = $(VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org --wait-stderr --wait-stdout -- -c "echo 'osboxes.org' | sudo -S grep -oP 'ServerName \K.*' /etc/apache2/sites-available/wordpress.conf")
    Start-Sleep -Seconds 1  # Wacht een seconde voordat je het opnieuw probeert
}


Write-Host "-----------------------------rootpromotie.sh script uitvoeren----------------------"
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout -- -c "echo 'osboxes.org' | sudo -S chmod +x /home/osboxes/rootpromotie.sh"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout -- "/home/osboxes/rootpromotie.sh"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout -- "/home/osboxes/rootpromotie.sh"
Start-Sleep -Seconds 2
# hosts file aanpasen nu met nodig egegevens MET ROOT
write-host "---------------------------------------------------------hosts file aanpassen--------------------------------------"
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username root --password osboxes.org  --wait-stdout  -- -c "echo $ipAddressUbuntu $DOMAIN_NAME >> /etc/hosts"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username root --password osboxes.org  --wait-stdout  -- -c "echo $ipAddressUbuntu $DOMAIN_NAME >> /etc/hosts"

#-------------------------------------------------------------------------------------EINDE uitvoeren van SCRIPTS WORDPRESS-----------------------------------------------------------------
#------------------------------------------------------------------------------------- WACHTEN TOT DEBIAN SERVER IS OPGESTART--------------------------------------------------------------------------------------------------------------
while ($true) {
    # Voer de VBoxManage-opdracht uit en leid de uitvoer naar $null
    $null = VBoxManage --nologo guestcontrol "Debian server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org'" --quiet --no-verbose >$null 2>&1
    
    # Controleer de exitcode van de opdracht
    if ($LASTEXITCODE -eq 0) {
        # Als de exitcode 0 is, betekent dit dat de opdracht succesvol is uitgevoerd
        Write-Host "Debian server is opgestart!!!"
        break  # Verlaat de lus
    } else {
        # Als de exitcode niet 0 is, wacht een paar seconden voor een nieuwe poging
        Write-Host "Wachten tot Debian server aan staat..."
        Start-Sleep -Seconds 5
    }
}

#------------------------------------------------------------------------------------- EINDE WACHTEN TOT DEBIAN SERVER IS OPGESTART--------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------uitvoeren van SCRIPTS CHAMILO -----------------------------------------------------------------
write-host "---------------------------uitvoeren van script2.sh op Debian server-----------------------------------------------------------------"
Start-Sleep -Seconds 5
VBoxManage --nologo guestcontrol "Debian server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S cp /media/sf_gedeelde_map/script2.sh /home/osboxes/script2.sh"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Debian server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S cp /media/sf_gedeelde_map/script2.sh /home/osboxes/script2.sh"
Start-Sleep -Seconds 3
VBoxManage --nologo guestcontrol "Debian server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S chmod +x /home/osboxes/script2.sh"
Start-Sleep -Seconds 5
VBoxManage --nologo guestcontrol "Debian server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S /home/osboxes/script2.sh"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Debian server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S /home/osboxes/script2.sh"

# Initialiseer de variabele $DOMAIN_NAME_CHAMILO
$DOMAIN_NAME_CHAMILO = ""
write-host "---------------------------ophalen van domein naam van Debian server-----------------------------------------------------------------"
# Voer het commando uit totdat $DOMAIN_NAME_CHAMILO niet meer leeg is
while (-not $DOMAIN_NAME_CHAMILO) {
    $DOMAIN_NAME_CHAMILO = $(VBoxManage --nologo guestcontrol "Debian server" run --exe "/bin/bash" --username osboxes --password osboxes.org --wait-stderr --wait-stdout -- -c "echo 'osboxes.org' | sudo -S grep -oP 'ServerName \K.*' /etc/apache2/sites-available/chamilo.conf")
    Start-Sleep -Seconds 1  # Wacht een seconde voordat je het opnieuw probeert
}
# hosts file aanpasen nu met nodig egegevens MET ROOT
write-host "---------------------------------------------------------hosts file aanpassen--------------------------------------"
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username root --password osboxes.org  --wait-stdout  -- -c "echo $ipAddressDebian $DOMAIN_NAME_CHAMILO >> /etc/hosts"
#-------------------------------------------------------------------------------------EINDE uitvoeren van SCRIPTS CHAMILO -----------------------------------------------------------------
#--------------------------------------------------------------CONTROLE OUTPUT----------------------------------------------------------------------------------------------------------------

Write-Host "------------------EINDE SCRIPT; CONTROLEER OF BEIDE WAARDES HIERONDER CORRECT WORDEN WEERGEGEVEN----------------------"
# -----------------------------------CHAMILO DEBIAN:--------------------
Write-Host "CHAMILO: IP-adres van Debian-server (mag niet leeg zijn): $ipAddressDebian"
Write-Host "CHAMILO: domein naam van chamilo  webserver (mag niet leeg zijn): $DOMAIN_NAME_CHAMILO"
# ------------------------------------wordpress UBUNTU:-------------------------------
Write-Host "WORDPRES: IP-adres van Ubuntu-server (mag niet leeg zijn): $ipAddressUbuntu"
Write-Host "WORDPRES: domein naam van wordpress webserver (mag niet leeg zijn): $DOMAIN_NAME"
Read-Host "druk enter om af te sluiten!!!!!!"