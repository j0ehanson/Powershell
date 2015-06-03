# ******************************************************************************
# ******************************************************************************
# **
# **  Title:          	GetUsrPWExp.PS1
# **  Created By:		    Joe Hanson
# **  Date Created:  	  10/08/13
# **  Last Modified:  	06/02/15
# **
# **				***Change List at Bottom***
# **
# **  Description:    	This will pull users from Active Directory and report their
# **					password expiration date.
# **
# **  Usage:			.\GetUsrPassExp.PS1
# **					Will return all users passwords expiring after 7 days
# **					and email them
# **
# **					.\GetUsrPassExp.PS1 <user alias>
# **					Will return on users password expiration
# ******************************************************************************
# ******************************************************************************
##################################################################################
#	Variables
##################################################################################
$msgFrom = "joehanson@.com"
$msgCc = "joehanson@.com"

$SMTPServer = "webmail.com"

##################################################################################
#	Functions
##################################################################################

Function SendMail{
	Send-MailMessage -To $msgTo -From $msgFrom -subject $msgSubj -Cc $msgCc -Body $msgBody -BodyAsHtml -SmtpServer $SMTPServer
}
Function GetSingleUsr{
	Import-Module ActiveDirectory
	$strUsrList = Get-ADUser -Identity "$strArgUsr" -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed", "mail"
	ForEach ($strUsr in $strUsrList) {
		$strUsrExp = ([datetime]::FromFileTime($strUsr."msDS-UserPasswordExpiryTimeComputed")).DateTime
		$strUsrDayExp = (([datetime]::FromFileTime($strUsr."msDS-UserPasswordExpiryTimeComputed"))-(Get-Date)).Days

		$strUsr.DisplayName
		$strUsr.mail
		$strUsrExp
		Write-Host "Users Password Expires in:" $strUsrDayExp "Days"
	}
}

Function GetAllUsr{
	Import-Module ActiveDirectory
	$strUsrList = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq  $False} -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed", "mail" |  Where-Object {$_.DisplayName -ne $null}
	ForEach ($strUsr in $strUsrList) {
		$strUsrExp = ([datetime]::FromFileTime($strUsr."msDS-UserPasswordExpiryTimeComputed")).DateTime
		$strUsrDayExp = (([datetime]::FromFileTime($strUsr."msDS-UserPasswordExpiryTimeComputed"))-(Get-Date)).Days

		# This is to add some logic to date expiration: If negative number, equals zero, or 7days or less
		$strUsrSwitch = 0
		If (($strUsrDayExp -le 7) -and ($strUsrDayExp -gt 0)){
			$strUsrSwitch = 1
		}
		If ($strUsrDayExp -eq 0){
			$strUsrSwitch = 2
		}
		If ($strUsrDayExp -lt 0){
			$strUsrSwitch = 3
		}
		# The Switch statment is an alternate way to evaluate expressions.  It is
		# a substitution to an If ElseIf Else block.
		# example http://www.powershellpro.com/powershell-tutorial-introduction/powershell-tutorial-conditional-logic/
		switch($strUsrSwitch){
			1{
				If ($strUsr.mail -ne $null){
					$strFNUsr = $strUsr.DisplayName
					$strUsr.mail
					$strUsrExp
					$strUsrDayExp
					$msgTo = $strUsr.mail
					$msgSubj = "Password Expires in $strUsrDayExp Days"
					$msgBody = "$strFNUsr, <br />
					This is just a friendly reminder that your domain password will expire in $strUsrDayExp Days. <br />
					If you are on a windows machine and on the domain, just hit CTRL-ALT-DEL and you can select <br />
					change a password.
					If you are outside a branch office, not on the domain, and or on a Mac;  You can use OWA <br />
					(https://webmail.com) to change your password.  If you do not have a company email <br />
					please send email to joehanson@.com to request a new password. <br />
					Thank you, <br />
					Joe Hanson
					"
					SendMail
				} Else {
					$strFNUsr = $strUsr.DisplayName
					$strUsr.mail
					$strUsrExp
					$strUsrDayExp
					$msgTo = "joehanson@.com"
					$msgSubj = "Password Expires in $strUsrDayExp Days"
					$msgBody = "$strFNUsr, <br />
					Password will expire in $strUsrDayExp Days. <br />
					"
					sendMail
				}
			}
			2{
				If ($strUsr.mail -ne $null){
					$strFNUsr = $strUsr.DisplayName
					$strUsr.mail
					$strUsrExp
					$strUsrDayExp
					$msgTo = $strUsr.mail
					$msgSubj = "Password Expires Today"
					$msgBody = "$strFNUsr, <br />
					This is just a friendly reminder that your domain password will expire Today. <br />
					If you are on a windows machine and on the domain, just hit CTRL-ALT-DEL and you can select <br />
					change a password.
					If you are outside a branch office, not on the domain, and or on a Mac;  You can use OWA <br />
					(https://webmail.com) to change your password.  If you do not have a company email <br />
					please send email to joehanson@.com to request a new password. <br />
					Thank you, <br />
					Joe Hanson
					"
					SendMail
				} Else {
					$strFNUsr = $strUsr.DisplayName
					$strUsr.mail
					$strUsrExp
					$strUsrDayExp
					$msgTo = "joehanson@.com"
					$msgSubj = "Password Expires in $strUsrDayExp Days"
					$msgBody = "$strFNUsr, <br />
					Password will expire Today. <br />
					"
					sendMail
				}
			}
			3{
				If ($strUsr.mail -ne $null){
					$strFNUsr = $strUsr.DisplayName
					$strUsr.mail
					$strUsrExp
					$strUsrDayExp
					$msgTo = "joehanson@.com"
					$msgSubj = "Password Expires in $strUsrDayExp Days"
					$msgBody = "$strFNUsr, <br />
					This is just a friendly reminder that your password will expire in $strUsrDayExp Days. <br />
					Thank you, <br />
					Joe Hanson
					"
					SendMail
				} Else {
					$strFNUsr = $strUsr.DisplayName
					$strUsr.mail
					$strUsrExp
					$strUsrDayExp
					$msgTo = "joehanson@.com"
					$msgSubj = "Password Expires in $strUsrDayExp Days"
					$msgBody = "$strFNUsr, <br />
					Password will expire in $strUsrDayExp Days. <br />
					"
					sendMail
				}
			}
		}
	}
}

##################################################################################
#	Usage
##################################################################################
$GetUsage = @"
Will get password expiration for all users in AD or just a single user.

--------------------------EXAMPLE 1--------------------------------------------

.\GetUsrPassExp.PS1

Description
-----------
This will go through the AD for each user and report on all users password expiration less than 7 days and email the user.

--------------------------EXAMPLE 2--------------------------------------------

.\GetUsrPassExp.PS1 <user alias>

.\GetUsrPassExp.PS1 joehanson

Description
-----------
This will get the password expiration for just one user.  In the example above, Joe Hanson's password.
Output will be just to screen, no email
"@

# This is to verify that you have installed the active directory tools
# AD tools gives you the get-aduser cmdlets
If (Test-Path C:\Windows\System32\WindowsPowerShell\v1.0\Modules\ActiveDirectory) {
	# Pass
} Else {
	Write-Host "You may need to install the ActiveDirectory tools to use this script."
	Exit 1
}

If ($args.count -gt 0){
	If ($args -eq "?" -or $args -eq "/?") {
		$GetUsage
		#Write-Host "This will call usage of script"
	} Else {
		$strArgUsr = $args
		GetSingleUsr
	}
} Else {
	GetAllUsr
}

#
# ******************************************************************************
# **  Changes:
# **			06/02/15: updated
# **			04/16/15: updated.
# **
# ** 			11/1/13:  updated email option to users with negative expiration date
# **				on their passwords.
# **
# **			10/31/13:  Added logic to handle negative and 0 day password
# **				age.
# ******************************************************************************
#
