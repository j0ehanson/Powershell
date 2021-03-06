#####################################################################################
#v1.0 25 September 2011	: A script is born
#
#
#
#
#	
#
# ::This script polls a machine for its virtual applications and displays it in a GUI
#   ::You can then refresh or unload a selected app
#
#Written By Joe Hanson
#####################################################################################

#Common Variables:
$AppName = "APPVUtil.ps1"
$AppVer  = "v1.0 [25 September 2011]"

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

#####################################################################################
#Ping Machine
#####################################################################################
Function IsPingable{param($strWSID) Test-Connection -ComputerName $strWSID -Count 2 -Quiet}
#####################################################################################
#Get OS
#####################################################################################
Function GetOSVer{
	$script:usrOS = Get-WmiObject -class win32_OperatingSystem -namespace "root/CIMV2" -ComputerName $strWSID
	If ($usrOS.Version -eq "6.1.7601"){
	$script:usrPath = "\\$strWSID\C$\Users"
	$script:usrUAppPath = "\\$strWSID\C$\ProgramData\Microsoft\Application Virtualization Client\SoftGrid Client\AppFS Storage"
	}
	If ($usrOS.Version -eq "5.1.2600"){
	$script:usrPath = "\\$strWSID\C$\Documents and Settings"
	$script:usrUAppPath = "\\$strWSID\C$\Documents and Settings\All Users\Documents\SoftGrid Client\AppFS Storage"
	}
}
#####################################################################################
#Get Users from local machine
#####################################################################################
Function GetUsers{
	[array]$usrDropDownArray = (Get-ChildItem "$usrPath" -exclude Admin*, *a, Public)
			
	ForEach ($usrItem in $usrDropDownArray) {
	$uName = $usrItem.Name
    $usrDropDown.Items.Add($uName) | Out-Null}}
#####################################################################################
#Get Users from the drop down
#####################################################################################
Function GetUsrDrpDwn{
	$script:uSelected = $usrDropDown.SelectedItem.ToString()
	If ($uSelected){
		If ($usrOS.Version -eq "6.1.7601"){
		$script:usrRAppPath = "\\$strWSID\C$\Users\$uSelected\AppData\Roaming\SoftGrid Client"
		}
		If ($usrOS.Version -eq "5.1.2600"){
		$script:usrRAppPath = "\\$strWSID\C$\Documents and Settings\$uSelected\Application Data\SoftGrid Client"
		}
	GetUserApps
	}
}
#####################################################################################
#Get Selected Users Applications
#####################################################################################
Function GetUserApps{
	$usrTable.clear()
	$aaTable.Rows | ForEach-Object {
	$PGuid = $_["Package GUID"].substring(0,18)
	$xPackageGuid = $_["Package GUID"]
	$xName = $_["Name"]
	$xIsRunning = $_["Is Running"]
		$GCitem = Get-ChildItem "$usrRAppPath" -name
		$GCCount = 0
		ForEach ($CI in $GCitem){
		If ($CI.Length -gt 18){
			If ($CI -match $PGuid){
				#Write-Host $CI
				$xFullPath = $CI
				$usrTable.Rows.Add($xName,$xFullPath,$xPackageGuid,$xIsRunning) | Out-Null
				$GCCount = $GCCount + 1
				}
			}
		}
		If ($GCCount -gt 0){
		$btnUNLOAD.Visible = $True
		$btnREPAIR.Visible = $True
		}
	}		
}
#####################################################################################
#Unload selected application
#####################################################################################
Function Unload{
$usrUSelectedAppRun = $usrTable.DefaultView[$usrDataGrid.CurrentCell.RowIndex][3]
$usrUSelectedApp = $usrTable.DefaultView[$usrDataGrid.CurrentCell.RowIndex][1]
	If ($usrUSelectedAppRun -eq $True){
	[System.Windows.Forms.MessageBox]::Show("Selected application is running and cannot be unloaded until it is stopped") | Out-Null
	}
	Else{
		$usrUResult = [Windows.Forms.MessageBox]::Show("Are you sure you want to continue?", "APP-V Util", [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Question)
		If ($usrUResult -eq [Windows.Forms.DialogResult]::Yes) {
			#Write-Host "$usrUSelectedApp selected to be unloaded"
			$TstUPath = Test-Path "$usrUAppPath\$usrUSelectedApp\"
				If ($TstUPath){
					Remove-Item "$usrUAppPath\$usrUSelectedApp\*.*"
					[System.Windows.Forms.MessageBox]::Show("Selected application has been unloaded") | Out-Null
				}
		}
	}
}
#####################################################################################
#Repair selected application
#####################################################################################
Function Repair{
$usrRSelectedAppRun = $usrTable.DefaultView[$usrDataGrid.CurrentCell.RowIndex][3]
$usrRSelectedApp = $usrTable.DefaultView[$usrDataGrid.CurrentCell.RowIndex][1]
	If ($usrRSelectedAppRun -eq "True"){
	[System.Windows.Forms.MessageBox]::Show("Selected application is running and cannot be repaired until it is stopped") | Out-Null
	}
	Else{
		$usrRResult = [Windows.Forms.MessageBox]::Show("Are you sure you want to continue?", "APP-V Util", [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Question)
		If ($usrRResult -eq [Windows.Forms.DialogResult]::Yes) {
			$TstRPath = Test-Path "$usrRAppPath\$usrRSelectedApp\UsrVol_sftfs_v1.pkg"
				If ($TstRPath){
				$newName = Get-Date -format MMddyy-hhmmss
				Rename-Item -path "$usrRAppPath\$usrRSelectedApp\UsrVol_sftfs_v1.pkg" -newname "$newName.BAK"
				[System.Windows.Forms.MessageBox]::Show("Selected application has been repaired") | Out-Null
				}
		}
	}
}
#####################################################################################
#Get Data for All Installed App-V Apps
#####################################################################################
Function GetAllApps{
$aaTable.clear()
$ColItems = Get-WmiObject -class package -namespace "root/microsoft/appvirt/client" -computer $strWSID
	ForEach ($objItem in $ColItems) {
	#Write-Host "Name: " $objItem.Name
	#Write-Host "InUse: " $objItem.InUse
	#Write-Host "PackageGUID: " $objItem.PackageGUID}

	$yName = $objItem.Name
	$yInUse = $objItem.InUse
	$yPackageGUID = $objItem.PackageGUID 

	$aaTable.Rows.Add($yName,$yInUse,$yPackageGUID) | Out-Null }
}
#####################################################################################
#Main Form
#####################################################################################
Function Main{
$Form = New-Object System.Windows.Forms.Form
$Form.Width = 680
$Form.Height = 540
$Form.Text = "APP-V Util"
#$Form.backcolor = "#5D8AA8"

#####################################################################################
#Labels
#####################################################################################
$lblWSID = New-Object System.Windows.Forms.Label
$lblWSID.Location = New-Object System.Drawing.Size(545,1)
$lblWSID.Size = New-Object System.Drawing.Size(35,20)
$lblWSID.TextAlign = "MiddleCenter"
$lblWSID.Text = "WSID"
$Form.Controls.Add($lblWSID)

$lblUSER = New-Object System.Windows.Forms.Label
$lblUSER.Location = New-Object System.Drawing.Size(525,25)
$lblUSER.Size = New-Object System.Drawing.Size(55,20)
$lblUSER.TextAlign = "MiddleCenter"
$lblUSER.Text = "User ID"
$Form.Controls.Add($lblUSER)

$lblAbout           = New-Object System.Windows.Forms.Label
$lblAbout.Location  = New-Object System.Drawing.Size(15,15)
$lblAbout.Size      = New-Object System.Drawing.Size(260,100)
$lblAbout.Text      = $appName + " " + $AppVer + "`n`nCreated by Joe Hanson"
#####################################################################################
#Buttons
#####################################################################################
$btnGETUSR = New-Object System.Windows.Forms.Button
$btnGETUSR.Location = New-Object System.Drawing.Size(550,100)
$btnGETUSR.Size = New-Object System.Drawing.Size(100,23)
$btnGETUSR.Text = "Get User Apps"
$btnGETUSR.Add_Click({Try{GetUsrDrpDwn}Catch{[Windows.Forms.MessageBox]::Show("Select User ID from the DropDown.")}})
$Form.Controls.Add($btnGETUSR)

$btnUNLOAD = New-Object System.Windows.Forms.Button
$btnUNLOAD.Location = New-Object System.Drawing.Size(120,10)
$btnUNLOAD.Size = New-Object System.Drawing.Size(100,23)
$btnUNLOAD.Text = "UnLoad"
$btnUNLOAD.Visible = $False
$btnUNLOAD.Add_Click({Unload})
#$tabUsrApps.Controls.Add($btnUNLOAD) -- ** Moved this below due to the buttons coming before the tabs in load

$btnREPAIR = New-Object System.Windows.Forms.Button
$btnREPAIR.Location = New-Object System.Drawing.Size(10,10)
$btnREPAIR.Size = New-Object System.Drawing.Size(100,23)
$btnREPAIR.Text = "Repair"
$btnREPAIR.Visible = $False
$btnREPAIR.Add_Click({Repair})
#$tabUsrApps.Controls.Add($btnREPAIR) -- ** Moved this below due to the buttons coming before the tabs in load
#####################################################################################
#Text Boxes
#####################################################################################
$txtWSID = New-Object System.Windows.Forms.TextBox
$txtWSID.Location = New-Object System.Drawing.Size(580,1)
$txtWSID.Size = New-Object System.Drawing.Size(70,20)
$txtWSID.Text = $strWSID
$Form.Controls.Add($txtWSID)
#####################################################################################
#User DropDown
#####################################################################################
$usrDropDown = new-object System.Windows.Forms.ComboBox
$usrDropDown.Location = new-object System.Drawing.Size(580,25)
$usrDropDown.Size = new-object System.Drawing.Size(70,30)
#####################################################################################
#Tabs
#####################################################################################
$tab = new-object System.Windows.Forms.tabcontrol
$tab.Location = New-object System.Drawing.Point(1,150)
$tab.Size = New-object System.Drawing.Size(650,300)
$tabUsrApps   = new-object System.Windows.Forms.tabpage
$tabUsrApps.Text     = "User Apps"
$tabUsrApps.Size     = New-object System.Drawing.Size(200,100)
$tab.controls.add($tabUsrApps)
$tabUsrApps.Controls.Add($btnUNLOAD)
$tabUsrApps.Controls.Add($btnREPAIR)

$tabAllApps   = new-object System.Windows.Forms.tabpage
$tabAllApps.Text     = "All Apps"
$tabAllApps.Size     = New-object System.Drawing.Size(200,100)
$tab.controls.add($tabAllApps)

$tabAbout   = new-object System.Windows.Forms.tabpage
$tabAbout.Text     = "About"
$tabAbout.Size     = New-object System.Drawing.Size(200,100)
$tab.controls.add($tabAbout)
$tabAbout.Controls.Add($lblAbout)
#####################################################################################
#Data Tables
#####################################################################################
$Dataset = New-Object System.Data.DataSet
$aaTable = New-Object System.Data.DataTable
$aaTable.TableName = "AllApps"
$aaTable.Columns.Add("Name")
$aaTable.Columns.Add("Is Running")
$aaTable.Columns.Add("Package GUID")
$Dataset.tables.add($aaTable)

$usrTable = New-Object System.Data.DataTable
$usrTable.TableName = "UserApps"
$usrTable.Columns.Add("Name")
$usrTable.Columns.Add("Full Path")
$usrTable.Columns.Add("Package GUID")
$usrTable.Columns.Add("Is Running")
$Dataset.tables.add($usrTable)

$aaDataGrid = new-object System.windows.forms.DataGridView
$aaDataGrid.Location = new-object System.Drawing.Size(10,50) 
$aaDataGrid.size = new-object System.Drawing.Size(600,220)
$aaDataGrid.AutoSizeColumnsMode = "AllCells"
$aaDataGrid.ScrollBars = "Both"
$aaDataGrid.DataSource = $aaTable
$tabAllApps.Controls.Add($aaDataGrid)

$usrDataGrid = new-object System.windows.forms.DataGridView
$usrDataGrid.Location = new-object System.Drawing.Size(10,50) 
$usrDataGrid.size = new-object System.Drawing.Size(600,220)
$usrDataGrid.AutoSizeColumnsMode = "AllCells"
$usrDataGrid.ScrollBars = "Both"
$usrDataGrid.DataSource = $usrTable
$tabUsrApps.Controls.Add($usrDataGrid)
#####################################################################################
#
#####################################################################################
GetOSVer
GetUsers
GetAllApps

$Form.Controls.Add($tab)
$Form.Controls.Add($usrDropDown)
    
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
}
#####################################################################################
# This is what gets run on load
#####################################################################################
$strWSID = [Microsoft.VisualBasic.Interaction]::InputBox("Please Enter the WSID")
    If (IsPingable($strWSID)) {
        Main
    } Else {
		[System.Windows.Forms.MessageBox]::Show("Machine is Offline") | Out-Null
    }