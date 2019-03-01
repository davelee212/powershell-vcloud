# A quick fix to ensure all VMs in a Resource Pool have a CD-ROM attached.  This was written specifically
# to deal with a problem with VMs failed over by Zerto which do not have CD-ROM drives.

# Example:
# Connect to vCenter server and run this bit of code.  Substitute in your own resource pool.

$VMs = Get-ResourcePool | where {$_.Name -like "My Resource Pool"} | Get-VM
 
foreach ($vm in $VMs) {
  if (-NOT ($vm | Get-CDDrive) ) {
    Write-Host (Get-Date -Format HH:mm:ss) ":   CD-ROM Drive was not found on $vm. Adding CD-ROM drive..."
    $vm | New-CDDrive | Out-Null
  }
  else {
     Write-Host (Get-Date -Format HH:mm:ss) ":   CD-ROM already present on VM $vm"
  }
}