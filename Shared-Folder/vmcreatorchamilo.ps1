#C:\Users\Arthur\Downloads\Kali Linux 2024.1 (64bit).vdi
#C:\Users\Arthur\Downloads/Debian Server 23.04 (64bit).vdi
#C:\Users\Arthur\Documents\Github\CSV-2024\Shared-Folder
# Functie om het absolute pad van een bestand te krijgen
write-host "-----------------VM CREATOR-----------------"
function Get-AbsolutePath {
    param([string]$Path)
    $AbsolutePath = Convert-Path $Path
    return $AbsolutePath
}

# Vraag om het absolute pad van het Kali Linux VDI
$DebianServerVDIPath = Read-Host "Geef het absolute pad van het DebianServer VDI-bestand in: "
# Controleer of het opgegeven pad geldig is
if (-not (Test-Path $DebianServerVDIPath)) {
    Write-Host "Het opgegeven pad is ongeldig."
    exit
}
# Krijg het absolute pad van het bestand
$DebianServerVDIPath = Get-AbsolutePath -Path $DebianServerVDIPath

# Vraag om het absolute pad van de gedeelde map
$SharedFolderPath = Read-Host "Geef het absolute pad van de gedeelde map in: "
# Controleer of het opgegeven pad geldig is
if (-not (Test-Path $SharedFolderPath)) {
    Write-Host "Het opgegeven pad is ongeldig."
    exit
}

# Krijg het absolute pad van de gedeelde map
$SharedFolderPath = Get-AbsolutePath -Path $SharedFolderPath


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
Write-Host "installeren dependencys powershell lokaal!"
Install-Module -Name Posh-SSH -Scope CurrentUser -Force
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


# Controleer en start de Debian Server VM
if ((& VBoxManage showvminfo "Debian server" --machinereadable | Select-String "VMState" | ForEach-Object {$_ -match 'VMState="(.+?)"'; $Matches[1]}) -ne "running") {
    Write-Host "Debian Server VM wordt gestart..."
    & VBoxManage startvm "Debian server"
}



# Variables
Write-Host "Het IP-adres van de Debian-server wordt opgehaald..."
$ipAddressDebian = $(VBoxManage guestproperty get "Debian server" "/VirtualBox/GuestInfo/Net/0/V4/IP").Replace("Value: ", "").Trim()

Write-Host "-------------------------------INSTALEREN VAN GUEST EDITIONS DEBIAN SERVER------------------------------------------------"
# Voer het Bash-script uit op de Linux VM met SSH en wachtwoord authenticatie
#Write-Host "------------------------GEEF HET WACHTWOORD OSBOXES.ORG IN!!!!! Debian Server---------------------------------------------------"
#ssh -o StrictHostKeyChecking=no $Username@$ipAddressDebian "$guestupdatesh > guestupdate.sh && chmod +x guestupdate.sh && echo 'osboxes.org'| sudo -S bash guestupdate.sh"



$password = "osboxes.org" | ConvertTo-SecureString -AsPlainText -Force
#username voor ssh login
$username = "osboxes"
# Create credential object
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password 
# Establish SSH session
$sshSession = New-SSHSession -ComputerName "$ipAddressDebian" -Credential $credential -Force
# Create shell stream for command execution
$stream = $sshSession.Session.CreateShellStream("BASH-SHH", 0, 0, 0, 0, 100000)
write-host "--------------------------SSH SESSION GESTART--------------------------------- DIT KAN EVENTJES DUREN"
# Read initial data from the stream
$stream.Read()

Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for ${username}:" -SecureAction $password
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "cp /media/sf_gedeelde_map/guestupdate.sh /home/osboxes/guestupdate.sh"
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "chmod +x /home/osboxes/guestupdate.sh"
Invoke-SSHStreamShellCommand -ShellStream $stream -Command "bash /home/osboxes/guestupdate.sh && echo 'plopkoek'"

$stream.Expect("plopkoek")


# Remove the SSH session
Remove-SSHSession -SSHSession $sshSession
write-host "EINDE SSH SESSION WACHT OP REBOOT..."
# --------------------------Oneindige lus tot de VM is opgestart----------------------------
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

