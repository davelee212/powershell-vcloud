$global:spolrefs = @{}
# Change to be appropriate for your scenario:
$cloudURL = "vcd2.redcentricplc.com"
$cloudOrg = "10000"
 
# Check if we are already logged-in (interactive session) and if not, prompt for login:
if (!$session.IsConnected) {
 $creds = Get-Credential -Message "Authenticate to $cloudOrg Cloud Service"
 $session = Connect-CIServer -Server $cloudURL -Credential $creds
# $session = Connect-CIServer -Server $cloudURL -Org $cloudOrg -Credential $creds
}
 
# PS Function to query the vCloud Director REST API
# ('Borrowed' from Matt Vogt's blog at: http://blog.mattvogt.net/)
function Get-vCloudREST($href)
{
 $request = [System.Net.HttpWebRequest]::Create($href)
 $request.Accept = "application/*+xml;version=20.0" # For vCloud Director 8.xx or later API
 $request.Headers.add("x-vcloud-authorization",$global:session.sessionID)
 $response = $request.GetResponse()
 $streamReader = new-object System.IO.StreamReader($response.getResponseStream())
 $xmldata = $streamReader.ReadToEnd()
 $streamReader.Close()
 $response.Close()
 return $xmldata
}
 
# Function to get Storage Profile name from its Href (if not already known/cached in a global hash)
# if already known we don't need to call the API again and can just return the value from the hash
function Get-SPName($storage_href)
{
 if ($global:spolrefs.ContainsKey($storage_href)) {
 return $global:spolrefs.Get_Item($storage_href)
 } else {
 [xml]$sp = Get-vCloudREST($storage_href)
 $global:spolrefs.Add($storage_href, $sp.VdcStorageProfile.name)
 return $sp.VdcStorageProfile.name
 }
}
 
# Function to retrieve the disk information for a VM:
function Get-VMDisks($VM)
{
 $VMDisks = @() # Start with an empty array
 $queryHref = $VM.Href + "/virtualHardwareSection/disks" # API path for VM disk information
 [xml]$xml = Get-vCloudRESt($queryHref)
 $disks = $xml.RasdItemsList.Item | Where-Object {$_.ResourceType -eq 17} # Resource Type 17 = Hard disk drive
 foreach ($disk in $disks)
 {
 $sp = Get-SPName($disk.HostResource.storageProfileHref)
 $diskobj = New-Object -TypeName PSObject
 $diskobj | Add-Member -Type NoteProperty -Name "Name" -Value ([String]$disk.ElementName)
 $diskobj | Add-Member -Type NoteProperty -Name "StorageProfile" -Value ([String]$sp)
 $diskobj | Add-Member -Type NoteProperty -Name "Quantity" -Value ([Int64]$disk.VirtualQuantity)
 $diskobj | Add-Member -Type NoteProperty -Name "QuantityUnits" -Value ([String]$disk.VirtualQuantityUnits)
 $VMDisks += $diskobj
 }
 return $VMDisks
}
 
function Get-VMInfo($VM)
{
 $vmobj = New-Object -TypeName PSObject
 $vmobj | Add-Member -Type NoteProperty -Name "VMName" -Value ([String]$VM.Name)
 $vmobj | Add-Member -Type NoteProperty -Name "Id" -Value ([String]$VM.ExtensionData.Id)
 $vmobj | Add-Member -Type NoteProperty -Name "Status" -Value ([String]$VM.Status)
 $vmobj | Add-Member -Type NoteProperty -Name "vRAM" -Value ([Decimal]$VM.MemoryGB)
 $vmobj | Add-Member -Type NoteProperty -Name "vCPU" -Value ([Int]$VM.CpuCount)
 $vmobj | Add-Member -Type NoteProperty -Name "HWVersion" -Value ([String]$VM.VMVersion)
 $vmobj | Add-Member -Type NoteProperty -Name "vAppName" -Value ([String]$VM.VApp.Name)
 $vmobj | Add-Member -Type NoteProperty -Name "GuestOS" -Value ([String]$VM.GuestOsFullName)
 [PSCustomObject]$disks = Get-VMDisks($VM)
 $vmobj | Add-Member -Type NoteProperty -Name "Disks" -Value $disks
 return $vmobj
}
 
# Get all VMs in our Cloud Organization:
$vms = Get-Org $cloudOrg | Get-CIVM
 
# Initialise an array for returned objects:
$vmobjs = @()
 
# For each VM, build our object:
foreach ($vm in $vms) {
 $vmobjs += Get-VMinfo($vm)
}
 
# Output our object to console:
$vmobjs

