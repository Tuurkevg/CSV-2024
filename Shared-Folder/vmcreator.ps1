#C:\Users\Arthur\Downloads\Kali Linux 2024.1 (64bit).vdi
#C:\Users\Arthur\Downloads/Ubuntu Server 23.04 (64bit).vdi
#C:\Users\Arthur\Documents\Github\CSV-2024\Shared-Folder
# Functie om het absolute pad van een bestand te krijgen
write-host "-----------------VM CREATOR-----------------"
Write-Host "installeren dependencys powershell lokaal!"
Install-Module -Name Posh-SSH -Scope CurrentUser -Force
function Get-AbsolutePath {
    param([string]$Path)
    $AbsolutePath = Convert-Path $Path
    return $AbsolutePath
}

# Vraag om het absolute pad van het Kali Linux VDI
$KaliLinuxVDIPath = Read-Host "Geef het absolute pad van het Kali Linux VDI-bestand in: "
# Controleer of het opgegeven pad geldig is
if (-not (Test-Path $KaliLinuxVDIPath)) {
    Write-Host "Het opgegeven pad is ongeldig."
    exit
}
# Krijg het absolute pad van het bestand
$KaliLinuxVDIPath = Get-AbsolutePath -Path $KaliLinuxVDIPath

# Vraag om het absolute pad van de Ubuntu Server VDI
$UbuntuServerVDIPath = Read-Host "Geef het absolute pad van het Ubuntu Server VDI-bestand in: "
# Controleer of het opgegeven pad geldig is
if (-not (Test-Path $UbuntuServerVDIPath)) {
    Write-Host "Het opgegeven pad is ongeldig."
    exit
}
# Krijg het absolute pad van het bestand
$UbuntuServerVDIPath = Get-AbsolutePath -Path $UbuntuServerVDIPath

# Vraag om het absolute pad van de gedeelde map
$SharedFolderPath = Read-Host "Geef het absolute pad van de gedeelde map in: "
# Controleer of het opgegeven pad geldig is
if (-not (Test-Path $SharedFolderPath)) {
    Write-Host "Het opgegeven pad is ongeldig."
    exit
}

# Krijg het absolute pad van de gedeelde map
$SharedFolderPath = Get-AbsolutePath -Path $SharedFolderPath
#inhoud kopieren van updaten guestediiotions
$guestupdatesh = Get-Content -Path "$SharedFolderPath/guestupdate.sh" -Raw
#username voor ssh login
$username = "osboxes"
#password voor ssh login
$password = "osboxes.org" | ConvertTo-SecureString -AsPlainText -Force
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

# Controleer of de Kali Linux VM al bestaat
$kaliVMExists = & VBoxManage showvminfo "Kali Linux" --machinereadable 2>$null
if ($kaliVMExists) {
    Write-Host "De VM 'Kali Linux' bestaat al."
} else {
    Write-Host "Aanmaken van Kali Linux VM."
    VBoxManage createvm --name "Kali Linux" --ostype "Linux_64" --register
    VBoxManage modifyvm "Kali Linux" --memory 2048 --vram 256 --graphicscontroller vmsvga --draganddrop bidirectional --clipboard bidirectional --nic1 bridged --bridgeadapter1 $selectedInterface
    VBoxManage storagectl "Kali Linux" --name "SATA Controller" --add sata
    VBoxManage storageattach "Kali Linux" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $KaliLinuxVDIPath
    VBoxManage sharedfolder add "Kali Linux" --name "gedeelde_map" --hostpath $SharedFolderPath --automount
}


# Controleer en start de Ubuntu Server VM
if ((& VBoxManage showvminfo "Ubuntu server" --machinereadable | Select-String "VMState" | ForEach-Object {$_ -match 'VMState="(.+?)"'; $Matches[1]}) -ne "running") {
    Write-Host "Ubuntu Server VM wordt gestart..."
    & VBoxManage startvm "Ubuntu server"
}

# Controleer en start de Kali Linux VM
if ((& VBoxManage showvminfo "Kali Linux" --machinereadable | Select-String "VMState" | ForEach-Object {$_ -match 'VMState="(.+?)"'; $Matches[1]}) -ne "running") {
    Write-Host "Kali Linux VM wordt gestart..."
    & VBoxManage startvm "Kali Linux"
}






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

# Variables
Write-Host "Het IP-adres van de Ubuntu-server wordt opgehaald..."
$ipAddressUbuntu = $(VBoxManage guestproperty get "Ubuntu server" "/VirtualBox/GuestInfo/Net/0/V4/IP").Replace("Value: ", "").Trim()


Write-Host "-------------------------------UPDATEN VAN GUEST EDITIONS UBUNTU SERVER------------------------------------------------"
# Voer het Bash-script uit op de Linux VM met SSH en wachtwoord authenticatie
#Write-Host "------------------------GEEF HET WACHTWOORD OSBOXES.ORG IN!!!!! Ubuntu Server---------------------------------------------------"
#ssh -o StrictHostKeyChecking=no $Username@$ipAddressUbuntu "$guestupdatesh > guestupdate.sh && chmod +x guestupdate.sh && echo 'osboxes.org'| sudo -S bash guestupdate.sh"

Write-Host "installeren dependencys powershell lokaal!"
$ipAddressUbuntu = $(VBoxManage guestproperty get "Ubuntu server" "/VirtualBox/GuestInfo/Net/0/V4/IP").Replace("Value: ", "").Trim()
# Create credential object
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password 
# Establish SSH session
$sshSession = New-SSHSession -ComputerName "$ipAddressUbuntu" -Credential $credential -Force
# Create shell stream for command execution
$stream = $sshSession.Session.CreateShellStream("BASH-SHH", 0, 0, 0, 0, 100000)
# Read initial data from the stream
$stream.Read()
Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for ${username}:" -SecureAction $password
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "$guestupdatesh > guestupdate.sh"
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "chmod +x guestupdate.sh"
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "sudo -S bash guestupdate.sh"
# Remove the SSH session
Remove-SSHSession -SSHSession $sshSession

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
Write-Host " #--------------------------UITVOEREN VAN bash scripts---------------------------------------#"
write-host "---------------------------uitvoeren van script1.sh op Ubuntu server-----------------------------------------------------------------"
VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout  -- -c "echo 'osboxes.org' | sudo -S  /media/sf_gedeelde_map/script1.sh"
Start-Sleep -Seconds 2
# geef root rechten aan osboxes voor aanpasssen hosts file...
write-host "----------------------------------------rootpromotie.sh script kopieren naar Kali Linux----------------------------------------------------"
VBoxManage --nologo guestcontrol "Kali Linux" copyto "$SharedFolderPath/rootpromotie.sh" "/home/osboxes/rootpromotie.sh" --username osboxes --password osboxes.org

Start-Sleep -Seconds 2
# haal het domein naam op en verwerk deze voor in de host file van Kali Linux
write-host "-----------------------------------------domain naam ophalen-----------------------------"
$DOMAIN_NAME =$(VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stderr --wait-stdout  -- -c "grep -oP 'ServerName \K.*' /etc/apache2/sites-available/wordpress.conf")
Start-Sleep -Seconds 2
$DOMAIN_NAME =$(VBoxManage --nologo guestcontrol "Ubuntu server" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stderr --wait-stdout  -- -c "grep -oP 'ServerName \K.*' /etc/apache2/sites-available/wordpress.conf")

Start-Sleep -Seconds 2

Write-Host "-----------------------------rootpromotie.sh script uitvoeren----------------------"
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout -- "/home/osboxes/rootpromotie.sh"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username osboxes --password osboxes.org  --wait-stdout -- "/home/osboxes/rootpromotie.sh"

# hosts file aanpasen nu met nodig egegevens MET ROOT
write-host "---------------------------------------------------------hosts file aanpassen--------------------------------------"
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username root --password osboxes.org  --wait-stdout  -- -c "echo $ipAddressUbuntu $DOMAIN_NAME >> /etc/hosts"
Start-Sleep -Seconds 2
VBoxManage --nologo guestcontrol "Kali Linux" run --exe "/bin/bash" --username root --password osboxes.org  --wait-stdout  -- -c "echo $ipAddressUbuntu $DOMAIN_NAME >> /etc/hosts"


# Schrijf het IP-adres naar de console
Write-Host "------------------EINDE SCRIPT; CONTROLEER OF BEIDE WAARDES HIERONDER CORRECT WORDEN WEERGEGEVEN----------------------"
Write-Host "IP-adres van Ubuntu-server (mag niet leeg zijn): $ipAddressUbuntu"
#schrijf domain naam eens af om te controelren of dit klopt
Write-Host "domein naam van Ubuntu-server webserver (mag niet leeg zijn): $DOMAIN_NAME"
