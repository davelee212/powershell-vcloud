# Run from a PowerCLI shell that has been logged into the vCloud Director instance using “Connect-CIServer -server url” 
# and then run the script passing the following parameters:
#  -file or -f   =   The CSV file to import rules from
#  -vOrg or -o  =  The Organisation Name (assumes the org only has one Org VDC)
#  -vAppName or -v  =  The name of the vApp to import rules into
#  -vAppNet or -n  =  The name of the vApp Network to import firewall rules into

# Example:
# ./ImportvAppFWRules.ps1 -f myrules.csv -o MyOrg -v My_vApp -n My_vAppNetwork

param(  
  [parameter(Mandatory = $true, HelpMessage="CSV Path")][alias("-file","f")][ValidateNotNullOrEmpty()][string[]]$csvFile,
  [parameter(Mandatory = $true, HelpMessage="Organisation Name")][alias("-vOrg","o")][ValidateNotNullOrEmpty()][string[]]$orgName,
  [parameter(Mandatory = $true, HelpMessage="vApp Name")][alias("-vAppName","v")][ValidateNotNullOrEmpty()][string[]]$vAppName,
  [parameter(Mandatory = $true, HelpMessage="vApp Network Name")][alias("-vAppNet","n")][ValidateNotNullOrEmpty()][string[]]$vAppNet
)
 
$csv = Import-CSV -Path $csvFile
 
$CIvApp = Get-Org $orgName | Get-OrgVDC | Get-CIVapp $vAppName
$networkConfigSection = $CIvApp.ExtensionData.GetNetworkConfigSection()
$vAppNetwork = $networkConfigSection.NetworkConfig | where {$_.networkName -eq $vAppNet}
 
$fwService = New-Object vmware.vimautomation.cloud.views.firewallservice
$fwService.DefaultAction = "drop"
$fwService.LogDefaultAction = $false
$fwService.IsEnabled = $true
$fwService.FirewallRule = New-Object vmware.vimautomation.cloud.views.firewallrule
 
$ruleNumber = 0
 
foreach ($rule in $csv)
{
 
    if ($ruleNumber -ne 0) 
    {
        $fwService.FirewallRule += New-Object vmware.vimautomation.cloud.views.firewallrule 
    }
 
    write-host $rule.Description
 
    $fwService.FirewallRule[$ruleNumber].description = $rule.Description
    $fwService.FirewallRule[$ruleNumber].protocols = New-Object     vmware.vimautomation.cloud.views.firewallRuleTypeProtocols
    
    # This sets a protocol to $false if it's not $true.  This causes problems.
    # $fwService.FirewallRule[$ruleNumber].protocols.ANY = if ($rule.Proto_ANY -eq "TRUE") {$true} else {$false}
    # $fwService.FirewallRule[$ruleNumber].protocols.ICMP = if ($rule.Proto_ICMP -eq "TRUE") {$true} else {$false}
    # $fwService.FirewallRule[$ruleNumber].protocols.TCP = if ($rule.Proto_TCP -eq "TRUE") {$true} else {$false}
    # $fwService.FirewallRule[$ruleNumber].protocols.UDP = if ($rule.Proto_UDP -eq "TRUE") {$true} else {$false}
    
    # This works better - if something isn't set to $true then it doesn't set it at all
    if ($rule.Proto_ANY -eq "TRUE") { $fwService.FirewallRule[$ruleNumber].protocols.ANY = $true }
    if ($rule.Proto_ICMP -eq "TRUE") { $fwService.FirewallRule[$ruleNumber].protocols.ICMP = $true }
    if ($rule.Proto_TCP -eq "TRUE") { $fwService.FirewallRule[$ruleNumber].protocols.TCP = $true }
    if ($rule.Proto_UDP -eq "TRUE") { $fwService.FirewallRule[$ruleNumber].protocols.UDP = $true }
    
    $fwService.FirewallRule[$ruleNumber].policy = $rule.Policy
    $fwService.FirewallRule[$ruleNumber].port = $rule.Port
    $fwService.FirewallRule[$ruleNumber].destinationportrange = $rule.destinationportrange
    $fwService.FirewallRule[$ruleNumber].destinationIp = $rule.DestinationIP
    $fwService.FirewallRule[$ruleNumber].sourceport = $rule.SourcePort
    $fwService.FirewallRule[$ruleNumber].sourceportrange = $rule.SourcePortRange
    $fwService.FirewallRule[$ruleNumber].sourceip = $rule.SourceIP
    $fwService.FirewallRule[$ruleNumber].EnableLogging = if ($rule.EnableLogging -eq "TRUE") {$true} else {$false}
    $fwService.FirewallRule[$ruleNumber].isenabled = if ($rule.IsEnabled -eq "TRUE") {$true} else {$false}
 
    $ruleNumber++
}
 
$vAppNetwork.Configuration.Features = $vAppNetwork.Configuration.Features | where {!($_ -is [vmware.vimautomation.cloud.views.firewallservice])}
$vAppNetwork.configuration.features += $fwService
$networkConfigSection.UpdateServerData()