function Get-UADGroups()
{
    $parent = Get-ADGroup BoxSyncedGroups #Looks for the Active Directory group named BoxSyncedGroups
    $members = Get-ADGroupMember $parent #finds all member groups

    return $members
}

function Get-UADGroupMembers($name)
{
    $username = @()
    $admembers = (Get-ADGroupMember $name).name
    return $admembers
}

function New-GroupHashfromAD($groups)
{
    $new_hash = @{}
	
	#adds each group in AD to a hash table that contains the group SID
    foreach($group in $groups)
    {
        $new_hash.Add($group.name,$group.SID.Value)
    }
    return $new_hash
}

function New-GroupHashfromBox($groups)
{
    $new_hash = @{}
	
	#adds each group in Box to a hash table that contains the group id
    foreach($group in $groups)
    {
        $new_hash.Add($group.name,$group.id)
    }
    return $new_hash 
}
function New-GroupMemberHashFromBox($group){
    $new_hash = @{}
    foreach($member in $group)
    {
        $new_hash.Add($member.user.login,$member.user.id)
    }
    return $new_hash
}
function New-UserHashfromBox($users)
{
    $new_hash = @{}
    
	#create a hash table of all users in Box and their id's
    foreach($user in $users)
    {
        $new_hash.Add($user.login,$user.id)
    }
    return $new_hash
}
function Get-HasModified($datetime)
{
    #this function will compare the datetime in the parameter to the last time the task ran
    #returns true if the parameter is prior to the task last runt ime

    $lastRun = (Get-ScheduledTaskInfo -TaskName "Temp Test Task").lastruntime

    if($datetime -gt $lastRun)
    {
        return $flase
    }
    else
    {
       return $true
    }
}


function SyncBoxGroups($token)
{
    $log = ""

    #check to see if the AD group has been modified since last script run
    $modifiedDate = $(Get-ADGroup BoxSyncedGroups -Properties @("whenChanged")).whenChanged

    if(Get-HasModified -datetime $modifedDate)
    {
        #the AD group has been modified since the last run, sync groups

        $adgroups = Get-UADGroups #returns all AD groups that should be synced
        $boxgroups = Get-BoxAllGroups -token $dev_token #returns all existing groups in Box using Box Powershell SDK v2

        $adHash = New-GroupHashfromAD($adgroups) #builds a hash table of all identified AD groups and their corresponding SIDs
        $boxHash = New-GroupHashfromBox($boxgroups) #builds a hash table of all identified Box groups and their corresponding id's

        # build the list of groups in AD but not Box
        $addList = @()

        foreach($group in @($adHash.keys))
        {
            if(-not $boxHash.Contains($group))
            {
                $addList += $group
            }
        }

        $log += "Found $($addList.count) groups to create in Box.`r`n"

        #build the list of groups in Box but not AD
        $delList = @()

        foreach($group in @($boxHash.keys))
        {
            if(-not $adHash.Contains($group))
            {
                $delList += $group
            }
        }

        $log += "Found $($delList.count) groups to delete in Box.`r`n"

        #add missing groups to Box
        foreach($group in $addList)
        {
            $log += "Creating group $group in Box..."
            $gid = New-BoxGroup -token $dev_token -name $group #create a new group in Box using the Box Powershell SDK v2
            $log += "Done!`r`n"
        }

        #remove groups from Box that are not in AD
        foreach($group in $delList)
        {
            $log += "Deleting group $group from Box..."
            Remove-BoxGroup -token $dev_token -groupID $boxHash[$group] #delete the Box group using the Box Powershell SDK v2
            $log += "Done!`r`n"
        }

    }
    else
    {
        $log += "No changes since last run - not syncing groups."
    }

    return $log
}

function SyncBoxGroupMembers($token)
{
    $total = 0
    $boxusers = Get-BoxAllUsers -token $dev_token #return all users in Box using the Box Powershell SDK v2
    $boxuserhash = New-UserHashfromBox -users $boxusers #build a hash table of the returned users and their id's

    $boxgroups = Get-BoxAllGroups -token $dev_token #return all groups in Box using the Box Powershell SDK v2
    $boxHash = New-GroupHashfromBox($boxgroups) #build a hash table of the returned groups and their id's

    $adgroups = Get-UADGroups #returns all AD groups that should be synced
    $adHash = New-GroupHashfromAD($adgroups) #build a hash table of the returned groups and their SID's

    $log += "Beginning group membership update...`r`n"
	
	#iterate through each AD group
    foreach($adgroup in @($adHash.Keys))
    {
        $log += "Updating membership of $adgroup.`r`n"

        $boxmembers = Get-BoxGroupDetails -token $token -groupID $boxHash[$adgroup]
        $admembers = (Get-ADGroupMember $adgroup -Recursive).samaccountname

        $boxGroupID = $boxHash[$adgroup]

        $boxmemberhash = New-GroupMemberHashFromBox -group $boxmembers

        ## get list of users to add
        $addList = @()

        foreach($user in $admembers)
        {
            $login = $user + "@<your-domain>"
            if(-not $boxmemberhash.Contains($login))
            {
                $addList += $login
            }
        }
        $log += "$($addList.Count) members to add to group $adgroup.`r`n"

        #get list of users to delete
        $delList = @{}

        foreach($user in @($boxmemberhash.Keys))
        {
            $account = $user.Substring(0,$user.IndexOf('@'))
            if(-not $admembers.Contains($account.ToUpper()))
            {
                $delList.Add($user,$boxmemberhash[$user])
            }
        }
        $log += "$($delList.Count) members to remove from group $adgroup.`r`n"

        #add users to Box group
        foreach($user in $addList)
        {
            #only add the user if they exist in Box, otherwise, skip
            if($boxuserhash.Contains($user))
            {
                #add to group
                $add = Add-BoxGroupMember -token $token -groupID $boxGroupID -userID $boxuserhash[$user]
                $log += "$user added to Box group $adgroup.`r`n"
            }
            else
            {
                $log += "$user not found in Box, cannot add to $adgroup.`r`n"
            }
        }

        #delete users from Box group
        foreach($username in @($delList.Keys))
        {
            Remove-BoxGroupMember -token $token -userID $delList[$username] -groupID $boxGroupID
            $log += "$username removed from Box group $adgroup.`r`n"
        }
        $total++
    }
    
    $log += "Done!  Updated $($adhash.count) groups.`r`n"

    return $log
}

$start = Get-date #used for log tracking

$clientID = "" #put your clientID here
$secret = "" #put your client secret here

$dev_token = Get-BoxToken -clientID $clientID -client_secret $secret #use Box Powershell SDK to get a valid token

$log = "Start time: $start`r`n"

###  Add/Remove the groups in Box ###
# Assumes all groups to sync are contained in an Active Directory group BoxSyncedGroups
$log += SyncBoxGroups -token $dev_token
# at this point the identified groups in AD now exist in Box - no more or less

## Update group memberships
$log += SyncBoxGroupMembers -token $dev_token
# at this point the identified groups in AD have a synced membership in Box

$end = Get-date
$log +="End time: $end`r`n"

$log | Out-File boxgroupsync.txt -Append #append to logfile boxgroupsync.txt
