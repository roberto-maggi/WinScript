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

