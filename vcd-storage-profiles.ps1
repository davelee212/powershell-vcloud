# This script is intended to be used as part of a script to automatically create Organisation VDCs in vCloud Director.

# Find the Storage Profile in the Provider vDC to be added to the Org vDC
$BronzePvDCProfile = search-cloud -QueryType ProviderVdcStorageProfile -Name "Bronze Storage" | Get-CIView
 
# Create a new object of type VdcStorageProfileParams and fill in the parameters for the new Org vDC passing in the href of the Provider vDC Storage Profile
$spParams = new-object VMware.VimAutomation.Cloud.Views.VdcStorageProfileParams 
$spParams.Limit = 512000 
$spParams.Units = "MB"
$spParams.ProviderVdcStorageProfile = $BronzePvDCProfile.href 
$spParams.Enabled = $true
$spParams.Default = $false
 
# Create an UpdateVdcStorageProfiles object and put the new parameters into the AddStorageProfile element
$UpdateParams = new-object VMware.VimAutomation.Cloud.Views.UpdateVdcStorageProfiles 
$UpdateParams.AddStorageProfile = $spParams
 
# Get my test Org vDC
$orgVdc = Get-OrgVdc -Name DLTestOrg 
 
# Create the new Storage Profile entry in my test Org vDC
$orgVdc.ExtensionData.CreateVdcStorageProfile($UpdateParams)