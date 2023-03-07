$report = C:\Users\Administrator\Desktop\report.txt


# Registrazione a dominio 
echo "Nome Dominio" | Out-File -append C:\Users\Administrator\Desktop\report.txt
echo "----" | Out-File -append C:\Users\Administrator\Desktop\report.txt
Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Name, Domain | Format-Table -AutoSize | Out-File -append C:\Users\Administrator\Desktop\report.txt

# versione di Windows
echo "Versione di Windows" | Out-File -append C:\Users\Administrator\Desktop\report.txt
echo "----" | Out-File -append C:\Users\Administrator\Desktop\report.txt
(Get-WmiObject -Class Win32_OperatingSystem).caption | Format-Table -AutoSize | findstr.exe "W" | Out-File -append C:\Users\Administrator\Desktop\report.txt

# Licenza
echo "Licenza di Windows: 1 = registrata / 0 = non registrata" | Out-File -append C:\Users\Administrator\Desktop\report.txt
echo "----" | Out-File -append C:\Users\Administrator\Desktop\report.txt
Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | 
where { $_.PartialProductKey } | select Description, LicenseStatus  | findstr.exe "Windows" | Out-File -append C:\Users\Administrator\Desktop\report.txt

# Hardware della VM
echo "Hardware, CPU, Core e RAM e Dischi" | Out-File -append C:\Users\Administrator\Desktop\report.txt
echo "----" | Out-File -append C:\Users\Administrator\Desktop\report.txt
$c = Get-WmiObject Win32_ComputerSystem; write-host "CPU " $c.NumberOfProcessors; write-host "Core " $c.NumberOfLogicalProcessors; write-host "RAM " @([math]::round($c.TotalPhysicalMemory/1GB))GB | Out-File -append C:\Users\Administrator\Desktop\report.txt
#Dischi
Get-CimInstance -ClassName Win32_Volume| select DriveLetter, BlockSize, Capacity, FreeSpace | Select-Object DriveLetter, @{Name="Size(GB)";Expression={[math]::round($_.capacity/1GB)}}, @{Name="Free(GB)";Expression={[math]::round($_.freeSpace/1GB)}}, BlockSize | Format-Table -AutoSize | Out-File -append C:\Users\Administrator\Desktop\report.txt

#users
echo "Utenti" | Out-File -append C:\Users\Administrator\Desktop\report.txt
echo "----" | Out-File -append C:\Users\Administrator\Desktop\report.txt
Get-LocalUser | foreach-object {
  $data = $_ -split " "
  "{0} {1} {2} {3} {4} {5} {6} {7}" -f $data[2],$data[3],$data[0],$data[5],$data[1],
    $data[4],$data[6],$data[7]
}  | ?{$_ -notmatch 'DefaultAccount'} | ?{$_ -notmatch 'Guest'} | ?{$_ -notmatch 'SiemensService'} | Out-File -append C:\Users\Administrator\Desktop\report.txt

# Software
echo "Software" | Out-File -append C:\Users\Administrator\Desktop\report.txt
echo "----" | Out-File -append C:\Users\Administrator\Desktop\report.txt
$SoftWares="Web-Server",
foreach($SW in $SoftWares) 
{
    if ((Get-WindowsFeature $SW).InstallState -eq "Installed") {
        echo "$SW is installed" | Out-File -append C:\Users\Administrator\Desktop\report.txt
    } 
    else {
        echo "$SW is not installed" | Out-File -append C:\Users\Administrator\Desktop\report.txt
    }
}
#  .NET Framework Version
$release = Get-ItemPropertyValue -LiteralPath 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release
switch ($release) {
    { $_ -ge 533320 } { $version = '4.8.1 or later'; break }
    { $_ -ge 528040 } { $version = '4.8'; break }
    { $_ -ge 461808 } { $version = '4.7.2'; break }
    { $_ -ge 461308 } { $version = '4.7.1'; break }
    { $_ -ge 460798 } { $version = '4.7'; break }
    { $_ -ge 394802 } { $version = '4.6.2'; break }
    { $_ -ge 394254 } { $version = '4.6.1'; break }
    { $_ -ge 393295 } { $version = '4.6'; break }
    { $_ -ge 379893 } { $version = '4.5.2'; break }
    { $_ -ge 378675 } { $version = '4.5.1'; break }
    { $_ -ge 378389 } { $version = '4.5'; break }
    default { $version = $null; break }
}
echo ".NET Framework Version: $version" | Out-File -append C:\Users\Administrator\Desktop\report.txt

# Microsoft .NET Core Windows Server Hosting Bundle
$DotNETCoreUpdatesPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Updates\.NET Core"
$DotNetCoreItems = Get-Item -ErrorAction Stop -Path $DotNETCoreUpdatesPath
$NotInstalled = $True
$DotNetCoreItems.GetSubKeyNames() | Where { $_ -Match "Microsoft .NET Core.*Windows Server Hosting" } | ForEach-Object {
    $NotInstalled = $False
    echo "The host has installed $_"   | Out-File -append C:\Users\Administrator\Desktop\report.txt
}
$test = test-path -path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Updates\.NET Core"
if(-not($test)){
    echo "Can not find ASP.NET Core installed on the host"  | Out-File -append C:\Users\Administrator\Desktop\report.txt
}