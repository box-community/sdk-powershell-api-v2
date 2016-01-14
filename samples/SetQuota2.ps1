# SetQuota2.ps1 - using attribute based solution + secure directory credentials
#
# This will set all users within a Box tenant to have an unlimited quota

## Edit below this line before use ##
$c_id = "" #replace with your client id
$c_secret = "" #replace with your client secret
$s_dir = "" #set secure directory
$attribute = "quota" # attribute to be adjusted
$value = -1 #set to desired value, for quota in bytes. -1 sets a user to unlimited quota

#add the PSModulePath where the PSM files exist for the project
$env:PSModulePath = $env:PSModulePath + ";c:\box-powershell-sdk-v2"

## Edit above this line before use ##

Echo "-- Importing Module Box Auth --"
ipmo BoxAuth
Echo "-- Importing Module Box User --"
ipmo BoxUser

$dev_token = Get-BoxToken -clientID $c_id -client_secret $c_secret -secure_dir $s_dir

$users = Get-BoxAllUsers -token $dev_token

foreach($user in $users)
{
    Set-BoxUser -id $user.id -attribute $attribute -value $value -token $dev_token
}
