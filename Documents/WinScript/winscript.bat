if ($env:UserName -eq "systemadm") 
    {
        $report_file = "C:\Users\Administrator\Desktop\report.txt"
    } 
    else 
        {
            $report_file = "C:\Users\$env:UserName\Desktop\report.txt"
        }


$report_check = $test_URL_rew = test-path -path $report_file
if(($report_check))
    {
        Remove-Item -Path $report_file -Force
    }

# Registrazione a dominio 
echo "Nome VM e Dominio" | Out-File -append $report_file
echo "----" | Out-File -append $report_file
Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Name, Domain | Format-Table -AutoSize | findstr.exe "W" | Out-File -append $report_file
echo "" | Out-File -append $report_file
# versione di Windows
echo "Versione di Windows" | Out-File -append $report_file
echo "----" | Out-File -append $report_file
(Get-WmiObject -Class Win32_OperatingSystem).caption | Format-Table -AutoSize | findstr.exe "W" | Out-File -append $report_file
echo "" | Out-File -append $report_file

# Licenza
echo "Licenza di Windows: 1 = registrata / 0 = non registrata" | Out-File -append $report_file
echo "----" | Out-File -append $report_file
Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | 
where { $_.PartialProductKey } | select Description, LicenseStatus  | findstr.exe "Windows" | Out-File -append $report_file
echo "" | Out-File -append $report_file

# Hardware della VM
echo "Hardware, CPU, Core e RAM e Dischi" | Out-File -append $report_file
echo "----" | Out-File -append $report_file
$c = Get-WmiObject Win32_ComputerSystem; echo "CPU " $c.NumberOfProcessors | Out-File -append $report_file; echo "Core " $c.NumberOfLogicalProcessors | Out-File -append $report_file; echo "RAM " @([math]::round($c.TotalPhysicalMemory/1GB))GB | Out-File -append $report_file
#Dischi
Get-CimInstance -ClassName Win32_Volume| select DriveLetter, BlockSize, Capacity, FreeSpace | Select-Object DriveLetter, @{Name="Size(GB)";Expression={[math]::round($_.capacity/1GB)}}, @{Name="Free(GB)";Expression={[math]::round($_.freeSpace/1GB)}}, BlockSize | Format-Table -AutoSize | Out-File -append $report_file
echo "" | Out-File -append $report_file

#users
echo "Utenti" | Out-File -append $report_file
echo "----" | Out-File -append $report_file
Get-LocalUser | foreach-object {
  $data = $_ -split " "
  "{0} {1} {2} {3} {4} {5} {6} {7}" -f $data[2],$data[3],$data[0],$data[5],$data[1],
    $data[4],$data[6],$data[7]
}  | ?{$_ -notmatch 'DefaultAccount'} | ?{$_ -notmatch 'Guest'} | ?{$_ -notmatch 'SiemensService'} | Out-File -append $report_file
echo "" | Out-File -append $report_file

# Software
echo "Software" | Out-File -append $report_file
echo "----" | Out-File -append $report_file
$SoftWares="Web-Server"
foreach($SW in $SoftWares) 
{
    if ((Get-WindowsFeature $SW).InstallState -eq "Installed") {
        echo "$SW is installed" | Out-File -append $report_file
    } 
    else {
        echo "$SW is not installed" | Out-File -append $report_file
    }
}

#  .NET Framework Version
$test_NET_frame = test-path -path "Registry::HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
if(($test_NET_frame = $true)){
    $release = Get-ItemPropertyValue -LiteralPath 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release
    switch ($release) 
    {
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
    echo ".NET Framework Version: $version" | Out-File -append $report_file
    }
    else    {
        echo ".NET Framework NON trovato" | Out-File -append $report_file
            }

# Controllo Microsoft .NET Core Windows Server Hosting Bundle
$test_ASP = test-path -path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Updates\.NET Core"
if(($test_ASP)){
    $DotNETCoreUpdatesPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Updates\.NET Core"
    $DotNetCoreItems = Get-Item -ErrorAction Stop -Path $DotNETCoreUpdatesPath
    $NotInstalled = $True
    $DotNetCoreItems.GetSubKeyNames() | Where { $_ -Match "Microsoft .NET Core.*Windows Server Hosting" } | ForEach-Object 
        {
            $NotInstalled = $False
        echo "The host has installed $_"   | Out-File -append $report_file
        }
    else
        echo "Can not find ASP.NET Core installed on the host"  | Out-File -append $report_file
}
# Controllo IIS url Rewrite
$test_URL_rew = test-path -path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IIS Extensions\URL Rewrite"
if(($test_URL_rew)){
    echo "IIS URL Rewrite installed on the host"  | Out-File -append $report_file
    else
    echo "Can not find IIS URL Rewrite installed on the host"  | Out-File -append $report_file
}
# Controllo SQL Server
$test_SQL_server = test-path -path "Registry::HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"
if(($test_SQL_server))
    {
        echo "SQL server installed on the host"  | Out-File -append $report_file
        $inst = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
        foreach ($i in $inst)
            {
                $p =    (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$i | Out-File -append $report_file
                        (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Edition | Out-File -append $report_file
                        (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Version | Out-File -append $report_file
            }
        else
            echo "Can not find SQL server installed on the host"  | Out-File -append $report_file
    }

# Network
echo "Network" | Out-File -append $report_file
echo "----" | Out-File -append $report_file
Get-NetAdapter -Name * | findstr.exe "vmxnet3" | Out-File -append $report_file
echo "e sono rispettivamente:" | Out-File -append $report_file
(Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq "True"}).FullDNSRegistrationEnabled | Out-File -append $report_file
