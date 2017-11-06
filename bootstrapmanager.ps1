# https://chocolatey.org/docs/how-to-set-up-chocolatey-server

Write-Host "Is chocolatey installed?"
if (-Not(Get-Command "choco.exe" -errorAction SilentlyContinue))
{
    Write-Host "Install chocolatey"
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}
else
{
    Write-Host "Yes chocolatey is installed"
}

$iis = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($iis -eq $NULL)
{
    "IIS not found"
    choco install IIS-WebServer --source windowsfeatures -y
}
else
{
    Write-Host "IIS already installed"
}

choco install IIS-ASPNET45 --source windowsfeatures -y

choco install chocolatey.server -y

refreshenv

Import-Module WebAdministration

Write-Host "Disabling and stopping default website"

Set-ItemProperty "IIS:\Sites\Default Web Site" serverAutoStart False

Stop-Website "Default Web Site"

$iisAppName = "localchocolatey" 
$iisAppPoolName = $iisAppName  
$iisAppPoolDotNetVersion = "v4.0"
$directoryPath = 'C:\tools\chocolatey.server'

cd IIS:\AppPools\

#check if the app pool exists
if (!(Test-Path $iisAppPoolName -pathType container))
{
    #create the app pool
    $appPool = New-Item $iisAppPoolName
    $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
    $appPool | Set-ItemProperty -Name "enable32BitAppOnWin64" -Value "true"
}

cd IIS:\Sites\

if (Test-Path $iisAppName -pathType container)
{
    "$iisAppName already exists"
}
else
{
    #create the site
    $iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation="*:8888:"} -physicalPath "$directoryPath" # poort aan te passen
    $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
}

cd  c:/

$Command = "icacls ""$directoryPath"" /grant ""IIS_IUSRS"":(OI)(CI)(R)"
cmd.exe /c $Command

$Command = "icacls ""$directoryPath"" /grant ""IUSR"":(OI)(CI)(R)"
cmd.exe /c $Command

$Command = "icacls ""$directoryPath"" /grant ""IIS AppPool\$iisAppPoolName"":(OI)(CI)(R)"
cmd.exe /c $Command


$Command = "icacls ""$directoryPath\App_Data"" /grant ""IIS_IUSRS"":(OI)(CI)(M)"
cmd.exe /c $Command

$Command = "icacls ""$directoryPath\App_Data"" /grant ""IIS AppPool\$iisAppPoolName"":(OI)(CI)(M)"
cmd.exe /c $Command