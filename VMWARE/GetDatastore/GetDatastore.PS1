# ******************************************************************************
# ******************************************************************************
# **
# **  Title:      		GetDatastore.PS1    
# **  Document #:     
# **  Created By:     	Joe Hanson
# **  Date Created:   	1/15/14
# **  Last Modified:  
# **
# **  Description:    This will output the capacity, free space, and provisioned
# **					space for all data stores withe VNX in the name.

$datastores = get-datastore | where-object {$_.name -match "VNX"} | get-view
$datastores | select -expandproperty summary | select name, @{N="Capacity (GB)"; E={[math]::round($_.Capacity/1GB,2)}}, @{N="FreeSpace (GB)"; E={[math]::round($_.FreeSpace/1GB,2)}}, @{N="Provisioned (GB)"; E={[math]::round(($_.Capacity - $_.FreeSpace + $_.Uncommitted)/1GB,2) }}| sort -Property Name

# todo: 
#   * Test csv out:  use the following at the end of the line above.  | Export-Csv -Path <put your path here and file name with extension .csv> -NoTypeInformation -UseCulture
#	* references: http://vniklas.djungeln.se/2012/05/08/powercli-report-on-datastores-overprovision-and-number-of-powered-on-vm%C2%B4s/
#	* references: http://virtirl.com/?p=64
#
