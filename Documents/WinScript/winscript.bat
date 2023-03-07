#da qui inizia a funzionare al netto di alcune cose che non ci interessano
Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Name, Domain | Format-Table -AutoSize
echo "Windows Version"
echo "----"
(Get-WmiObject -Class Win32_OperatingSystem).caption | Format-Table -AutoSize
#CPU e RAM
$c = Get-WmiObject Win32_ComputerSystem; write-host "CPU " $c.NumberOfProcessors; write-host "Core " $c.NumberOfLogicalProcessors; write-host "RAM " @([math]::round($c.TotalPhysicalMemory/1GB))GB
##Disks
Get-CimInstance -ClassName Win32_Volume| select DriveLetter, BlockSize, Capacity, FreeSpace | Select-Object DriveLetter, @{Name="Size(GB)";Expression={[math]::round($_.capacity/1GB)}}, @{Name="Free(GB)";Expression={[math]::round($_.freeSpace/1GB)}}, BlockSize | Format-Table -AutoSize
##users
Get-LocalUser | Format-Table -AutoSize $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj in $InstalledSoftware){write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - " -NoNewline; write-host $obj.GetValue('DisplayVersion')}
