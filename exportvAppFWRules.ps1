# Run from a PowerCLI shell that has been logged into the vCloud Director instance using “Connect-CIServer -server url” 
# and then run the script passing the following parameters:
#  -file or -f   =   The CSV file to export rules to
#  -vOrg or -o  =  The Organisation Name (assumes the org only has one Org VDC)
#  -vAppName or -v  =  The name of the vApp containing the vApp Network
#  -vAppNet or -n  =  The name of the vApp Network to export firewall rules from

# Example:
#   ./ExportvAppFWRules.ps1 -f myrules.csv -o MyOrg -v My_vApp -n My_vAppNetwork

param(
  [parameter(Mandatory = $true, HelpMessage="CSV Path")][alias("-file","f")][ValidateNotNullOrEmpty()][string]$csvFile,
  [parameter(Mandatory = $true, HelpMessage="Organisation VDC Name")][alias("-OrgvDC","o")][ValidateNotNullOrEmpty()][string]$orgVDCName,  
  [parameter(Mandatory = $true, HelpMessage="vApp Name")][alias("-vAppName","v")][ValidateNotNullOrEmpty()][string]$vAppName,  
  [parameter(Mandatory = $true, HelpMessage="vApp Network Name")][alias("-vAppNet","n")][ValidateNotNullOrEmpty()][string]$vAppNet
)

$vAppNetwork = Get-OrgVDC $orgVDCName | Get-CIVapp $vAppName | Get-CIvAppNetwork $vAppNet

$fwrules = $vAppNetwork.ExtensionData.Configuration.Features.FirewallRule
$fwruleinfo = @()

foreach ($rule in $fwrules)
{
  $rule | Add-Member -MemberType NoteProperty -Name "Proto_Any" -Value $rule.Protocols.Any
  $rule | Add-Member -MemberType NoteProperty -Name "Proto_ICMP" -Value $rule.Protocols.ICMP
  $rule | Add-Member -MemberType NoteProperty -Name "Proto_UDP" -Value $rule.Protocols.UDP
  $rule | Add-Member -MemberType NoteProperty -Name "Proto_TCP" -Value $rule.Protocols.TCP
  $fwruleinfo += $rule
}

$fwruleinfo | Export-CSV -Path $csvFile -NoTypeInformation