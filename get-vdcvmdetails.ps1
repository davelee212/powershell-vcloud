# Adapted from original code from http://geekafterfive.com/2013/03/21/simple-vm-reporting-in-vcloud-with-powercli/
# Added MAC Address, Network Connection, Storage Profile and setup as a function

function Get-VDCVMDetails {

    $objects = @()
    $vms = $input | Get-CIVM
 
    foreach($vm in $vms)
    {
     $hardware = $vm.ExtensionData.GetVirtualHardwareSection()
     $diskMB = (($hardware.Item | where {$_.resourcetype.value -eq "17"}) | %{$_.hostresource[0].anyattr[0]."#text"} | Measure-Object -Sum).sum
     $primaryMACAddress = ($hardware.Item | where {$_.resourcetype.value -eq "10"}).Address.value.ToString()
     $primaryNetConn = ($hardware.Item | where {$_.resourcetype.value -eq "10"}).connection.value.ToString()
     $row = New-Object PSObject -Property @{ `
        "vapp" = $vm.vapp; `
        "name"=$vm.Name; `
        "guestos"=$vm.GuestOSFullName; `
        "Status"=$vm.Status; `
        "cpuCount"=$vm.CpuCount; `
        "memoryGB"=$vm.MemoryGB; `
        "primaryMACAddress"=$primaryMACAddress; `
        "primaryNetConn"=$primaryNetConn; `
        "storageGB"=($diskMB/1024); `
        "storageProfile"=$vm.ExtensionData.storageProfile.name;
     }
     $objects += $row
    }
     
    # Use select object to get the column order right. Sort by vApp. Force table formatting and auto-width.
    $objects |  select-Object name,status,vapp,guestos,cpuCount,memoryGB,primaryMACAddress,primaryNetConn,storageGB,storageProfile
}