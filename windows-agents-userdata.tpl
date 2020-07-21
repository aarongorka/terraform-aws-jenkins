<powershell>
# Download and silent install Java Runtime Environement
# working directory path
$workd = "c:\temp"
# Check if work directory exists if not create it
If (!(Test-Path -Path $workd -PathType Container))
{ 
New-Item -Path $workd  -ItemType directory 
}
# Create config file for silent install
$text = '
INSTALL_SILENT=Enable
AUTO_UPDATE=Enable
SPONSORS=Disable
REMOVEOUTOFDATEJRES=1
'
$text | Set-Content "$workd\jreinstall.cfg"   
# Download executable, this is the small online installer
$source = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=242060_3d5a2bb8f8d4428bbe94aed7ec7ae784"
$destination = "$workd\jreInstall.exe"
$client = New-Object System.Net.WebClient
$client.DownloadFile($source, $destination)
# Install silently
Start-Process -FilePath "$workd\jreInstall.exe" -ArgumentList INSTALLCFG="$workd\jreinstall.cfg"
# Wait 120 Seconds for the installation to finish
Start-Sleep -s 120
# Remove the installer
rm -Force $workd\jre*
# Download and install AWS cli
Invoke-WebRequest -Uri https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi -OutFile C:\aws.msi
Start-Process -Wait -FilePath "C:\aws.msi" -ArgumentList '/qn' -passthru
#Download and install jenkins
Invoke-WebRequest -Uri http://mirrors.jenkins-ci.org/windows-stable/latest -OutFile C:\temp\jenkins.zip
Expand-Archive -LiteralPath C:\temp\jenkins.zip -DestinationPath C:\temp\
Start-Process -Wait -FilePath "C:\temp\jenkins.msi" -ArgumentList '/qn' -passthru
# Create swarm directory
New-Item -Path "C:\" -Name "Swarm" -ItemType Directory
# Download swarm agent
Invoke-WebRequest -Uri https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.9/swarm-client-3.9.jar -OutFile C:\Swarm\swarm.jar
# Download WinSM wrapper to run the swarm client as a service
Invoke-WebRequest -Uri https://github.com/winsw/winsw/releases/download/v2.8.0/WinSW.NET461.exe  -OutFile C:\Swarm\winsw.exe
Set-Content -Path JENKINS_AGENTS_PASSWORD -Value "$((C:\Progra~1\Amazon\AWSCLI\bin\aws.exe --region=ap-southeast-2 ssm get-parameters --names "/jenkins/${account_name}/JENKINS_AGENTS_PASSWORD"  --with-decryption | ConvertFrom-Json).parameters.Value)"
$swarmd = "c:\Swarm"
$text = '
<service>
  <id>swarm</id>
  <name>swarm</name>
  <description>This service runs swarm client </description>
  <executable>"C:\Progra~1\Java\jre1.8.0_251\bin\javaw.exe"</executable>
  <arguments>-jar C:\Swarm\swarm.jar -master http://${dns_name}-master.${dns_base_name}:8080 -tunnel :43863 -fsroot C:\Jenkins -executors 1 -username agents -password JENKINS_AGENTS_PASSWORD</arguments>
  <logmode>rotate</logmode>
</service>
'
$text | Set-Content "$swarmd\winsw.xml"
(Get-Content -path C:\Swarm\winsw.xml -Raw) -replace 'JENKINS_AGENTS_PASSWORD',"$(Get-Content -Path JENKINS_AGENTS_PASSWORD)" | Set-Content -Path C:\Swarm\winsw.xml
Start-Process -Wait -FilePath "C:\Swarm\winsw.exe" -ArgumentList 'install'
Start-Process -Wait -FilePath "C:\Swarm\winsw.exe" -ArgumentList 'start'
</powershell>