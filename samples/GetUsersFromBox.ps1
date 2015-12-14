# GetUsersFromBox.ps1
#
# Get all users from box into a CSV for import processing

##edit below this line##

$outputFile = "C:\box_user_list.dat"
$rundate = Get-Date
$ClientID = "your-client-id"
$ClientSecret = "your-client-secret"
#add the PSModulePath where the PSM files exist for the project
$env:PSModulePath = $env:PSModulePath + ";c:\box-powershell-sdk-v2"

##edit above this line##

#Import Box modules
Echo "-- Importing Module Box Auth --"
ipmo BoxAuth
Echo "-- Importing Module Box User --"
ipmo BoxUser

Echo "-- Starting to get data from box.com via API on: $rundate --"

try{ $token = Get-BoxToken $ClientID $ClientSecret 
}
catch{
    write-host "Error getting a token from Box - $_"
    Exit 1
}

try { $users = Get-BoxAllUsers($token) 
}
catch {
    write-host "Error getting all users from Box - $_"
    Exit 1
}

try {
    $users | Select-Object "id","name","login","space_amount","type","can_see_managed_users","is_sync_enabled","status" | Export-Csv -NoTypeInformation $outputFile
}
catch {
    write-host "Error getting all users exported to the csv - $_"
    Exit 1
}

$rundate = Get-Date
echo "-- Finished getting data from Box.com at $rundate --"