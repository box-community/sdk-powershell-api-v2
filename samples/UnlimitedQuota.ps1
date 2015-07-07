# SetQuota.ps1
#
# This will set all users within a Box tenant to have an unlimited quota


## Edit below this line before use ##

$c_id = "" #replace with your client id
$c_secret = "" #replace with your client secret

Import-Module C:\Box\Box.psm1 #replace with the path to Box.psm1

$quota = -1 #set to desired quota in bytes. -1 sets a user to unlimited

## Edit above this line before use ##

$dev_token = Get-BoxToken -clientID $c_id -client_secret $c_secret

$users = Get-BoxAllUsers -token $dev_token

foreach($user in $users)
{
    Set-BoxUser -id $user.id -quota $quota -token $dev_token
}