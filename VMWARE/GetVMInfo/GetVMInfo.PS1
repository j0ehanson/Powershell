# ******************************************************************************
# ******************************************************************************
# **
# **  Title:      		GetVMInfo.PS1
# **  Jira#:
# **  Created By:     	Joe Hanson
# **  Date Created:   	3/18/15
# **  Last Modified:    4/24/15
# **
# **  Description:    This will output the capacity, free space, and provisioned
# **					space for all data stores, RAM, and CPU Usage.
# **
# **  Notes:
# **		* stored vm creds local to the machine running the script:
# **		  New-VICredentialStoreItem -Host inf-mark-vcenter-0.netprospex.com -user djhanson@vsphere.local -password <***hidden***>

$strVCenterSrv = "<server_name>"
$OUTSERVER = "<server_name>"


# ******************************************************************
# Set HTML Tags
# ******************************************************************
# Tag for DataStore
$strDSTAG = "<style>"
$strDSTAG = $strDSTAG + "BODY{background-color:peachpuff;}"
$strDSTAG = $strDSTAG + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$strDSTAG = $strDSTAG + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
$strDSTAG = $strDSTAG + "TD{border-width: 1px;padding: 9px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
$strDSTAG = $strDSTAG + "</style>"
# Tag for RAM
$strMEMTAG = "<style>"
$strMEMTAG = $strMEMTAG + "BODY{background-color:peachpuff;}"
$strMEMTAG = $strMEMTAG + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$strMEMTAG = $strMEMTAG + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
$strMEMTAG = $strMEMTAG + "TD{border-width: 1px;padding: 9px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
$strMEMTAG = $strMEMTAG + "</style>"
# Tag for CPU
$strCPUTAG = "<style>"
$strCPUTAG = $strCPUTAG + "BODY{background-color:peachpuff;}"
$strCPUTAG = $strCPUTAG + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$strCPUTAG = $strCPUTAG + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
$strCPUTAG = $strCPUTAG + "TD{border-width: 1px;padding: 9px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
$strCPUTAG = $strCPUTAG + "</style>"

# ******************************************************************
# Import PowerCLI Module & connect to VI Server
# ******************************************************************
If(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
	Add-PSSnapin VMware.VimAutomation.Core}

#Set-PowercliConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | Out-Null

# Update the title bar
$host.ui.rawui.WindowTitle="PowerShell [PowerCLI Module Loaded]"

# Connect to the vcenter server
If (-not($defaultVIServer)) {
	Connect-VIServer $strVCenterSrv
}
Else {
	Write "Already connected to the vCenter Server: $defaultVIServer"
}
If (-not ($PSBoundParameters.ContainsKey('VMhosts')) ) {
#	$VMhosts = Get-VMHost
}
$OvercommitInfoCollection = @()




$strNOW = Get-Date

# ******************************************************************
# Get DataStore Info
# ******************************************************************
function Get-DS {

$datastores = get-datastore | get-view
#$datastores | select -expandproperty summary | select name, @{N="Capacity (GB)"; E={[math]::round($_.Capacity/1GB,2)}}, @{N="FreeSpace (GB)"; E={[math]::round($_.FreeSpace/1GB,2)}}, @{N="Provisioned (GB)"; E={[math]::round(($_.Capacity - $_.FreeSpace + $_.Uncommitted)/1GB,2) }}| sort -Property Name | ConvertTo-HTML -head $strDSTAG -body "<H2>VMWare DataStore Information</H2>" -PostContent "Last Updated: $strNOW"| OUT-File \\<server_name>\vmreport\DStore.htm
$datastores | select -expandproperty summary | select name, @{N="Capacity (GB)"; E={[math]::round($_.Capacity/1GB,2)}}, @{N="FreeSpace (GB)"; E={[math]::round($_.FreeSpace/1GB,2)}}, @{N="Provisioned (GB)"; E={[math]::round(($_.Capacity - $_.FreeSpace + $_.Uncommitted)/1GB,2) }}| sort -Property Name

}

# ******************************************************************
# Get Mem Info
# ******************************************************************
function Get-RAM {

$VMhosts = Get-VMHost

Foreach ($VMhost in $VMhosts) {
	$PhysRAM = [Math]::Round($VMhost.MemoryTotalGB,2)
	$HostPoweredOnvRAM = [Math]::Round((Get-VM -Location $VMhost | Where-Object {$_.PowerState -eq "PoweredOn" } | Measure-Object MemoryGB -Sum).Sum, 2)
#	Write "PhysRAM for $VMhost is : $PhysRAM"
#	Write "HostPoweredOnvRAM for $VMhost is : $HostPoweredOnvRAM"




# Build properties for custom object:
$OvercommitInfoProperties = @{'ESXi Host'=$VMhost.Name
	'Physical RAM (GB)'=$PhysRAM
	'Total vRAM (GB)'=[Math]::Round((Get-VM -Location $VMhost | Measure-Object MemoryGB -Sum).Sum,2)
	'PoweredOn vRAM (GB)'=if ($HostPoweredOnvRAM) {$HostPoweredOnvRAM} Else { 0 -as [int] }
	'vRAM/Physical RAM ratio'=if ($HostPoweredOnvRAM) {[Math]::Round(($HostPoweredOnvRAM / $PhysRAM), 3)} Else { $null }
	'RAM Overcommit (%)'=if ($HostPoweredOnvRAM) {[Math]::Round(100*(($HostPoweredOnvRAM - $PhysRAM) / $PhysRAM), 2)} Else { $null }
	}

# Build custom object from list of properties:
$OvercommitInfoObj = New-Object -TypeName PSObject -Property $OvercommitInfoProperties

$OvercommitInfoObj
	}
}


Get-DS | ConvertTo-HTML -head $strDSTAG -body "<H2>VMWare DataStore Information</H2>" -PostContent "Last Updated: $strNOW" | OUT-File \\<server_name>\vmreport\DStore.htm
Get-RAM | sort -Property 'ESXi Host' | ConvertTo-HTML -head $strMEMTAG -body "<H2>VMWare RAM Information</H2>" -PostContent "Last Updated: $strNOW" | OUT-File \\<server_name>\vmreport\MEM.htm
#Get-CPU | ConvertTo-HTML -head $strCPUTAG -body "<H2>VMWare CPU Information</H2>" -PostContent "Last Updated: $strNOW" | OUT-File \\<server_name>\vmreport\CPU.htm

# todo: 
#   * Add logging and error handling.  specifically loading vmware powershell cli
#	* references: http://vniklas.djungeln.se/2012/05/08/powercli-report-on-datastores-overprovision-and-number-of-powered-on-vm%C2%B4s/
#	* references: http://virtirl.com/?p=64
#


#   * references: Info for html out: https://technet.microsoft.com/en-us/library/ff730936.aspx
#	* references: Info for mem function: https://github.com/MathieuBuisson/Powershell-VMware/blob/master/vSphereOvercommit/vSphereOvercommit.psm1
#	* refereences: Infor for adding snap in & pass creds: http://www.kellestine.com/load-powercli-modules/
