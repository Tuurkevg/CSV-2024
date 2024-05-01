Install-Module -Name Posh-SSH -Scope CurrentUser -Force
$password = "osboxes.org" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $password
$sshSession = New-SSHSession -ComputerName "$ipAddressUbuntu" -Credential $credential
$commandResult = Invoke-SSHCommand -SSHSession $sshSession -Command "$guestupdatesh > guestupdate.sh && chmod +x guestupdate.sh && echo 'osboxes.org'| sudo -S bash guestupdate.sh"
Write-Output $commandResult.Output
Remove-SSHSession -SessionId $sshSession.SessionId