<powershell>
Set-Content -Path JENKINS_AGENTS_PASSWORD -Value "$((aws.exe --region=ap-southeast-2 ssm get-parameters --names "/jenkins/${account_name}/JENKINS_AGENTS_PASSWORD"  --with-decryption | ConvertFrom-Json).parameters.Value)"
$swarmd = "c:\Swarm"
$text = '
<service>
  <id>swarm</id>
  <name>swarm</name>
  <description>This service runs swarm client </description>
  <executable>"javaw.exe"</executable>
  <arguments>-jar C:\Swarm\swarm.jar -master http://${dns_name}-master.${dns_base_name}:8080 -tunnel :43863 -labels windows -t Default="C:\Program Files\Git\bin\git.exe" -fsroot C:\Jenkins -executors 1 -username agents -password JENKINS_AGENTS_PASSWORD</arguments>
  <logmode>rotate</logmode>
</service>
'
$text | Set-Content "$swarmd\winsw.xml"
(Get-Content -path C:\Swarm\winsw.xml -Raw) -replace 'JENKINS_AGENTS_PASSWORD',"$(Get-Content -Path JENKINS_AGENTS_PASSWORD)" | Set-Content -Path C:\Swarm\winsw.xml
Start-Process -Wait -FilePath "C:\Swarm\winsw.exe" -ArgumentList 'install'
Start-Process -Wait -FilePath "C:\Swarm\winsw.exe" -ArgumentList 'start'
</powershell>
