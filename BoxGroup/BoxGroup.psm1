# Group Functions
function New-BoxGroup()
{
    param(
    [Parameter(Mandatory=$true)] [string] $token,
    [Parameter(Mandatory=$true)] [string] $name,
    [string] $description,
    $external_id,
    $provenance,
    $invitability,
    $viewability
    ) 

    #invitability_level and member_viewability_level support the following options:
    #admins_only
    #admins_and_members
    #all_managed_users

    #create a new Box group with the name given in $name
    #returns the groupid

    $uri = "https://api.box.com/2.0/groups"
    $headers = @{"Authorization"="Bearer $token"}

    #build JSON - name is the only mandatory field
    $json = '{'
    $json += '"name": "' + $name

    if($provenance){ $json += '", "provenance": "' + $provenance}
    if($description){ $json += '", "description": "' + $description}
    if($external_id){ $json += '", "external_sync_identifier": "' + $external_id}
    if($invitability){ $json += '", "invitability_level": "' + $invitability}
    if($viewability){ $json += '", "member_viewability_level": "' + $viewability}

    $json += '"}'
    
    $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "application/json"

    return $return.id
}

function Set-BoxGroup()
{
    param(
    [Parameter(Mandatory=$true)] [string] $token,
    [Parameter(Mandatory=$true)] [string] $groupID,
    $name,
    [string] $description,
    $external_id,
    $provenance,
    $invitability,
    $viewability
    ) 

    #invitability_level and member_viewability_level support the following options:
    #admins_only
    #admins_and_members
    #all_managed_users

    #create a new Box group with the name given in $name
    #returns the groupid

    $uri = "https://api.box.com/2.0/groups/" + $groupID
    $headers = @{"Authorization"="Bearer $token"}

    #build JSON - no mandatory fields

    $json = '{'

    if($name){$json += '"name": "' + $name + '", '}
    if($provenance){ $json += '"provenance": "' + $provenance + '", '}
    if($description){ $json += '"description": "' + $description + '", '}
    if($external_id){ $json += '"external_sync_identifier": "' + $external_id + '", '}
    if($invitability){ $json += '"invitability_level": "' + $invitability + '", '}
    if($viewability){ $json += '"member_viewability_level": "' + $viewability + '", '}

    $json = $json.Substring(0,$json.Length - 3)

    $json += '"}'
    
    $return = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $json -ContentType "application/json"

    return $return.id
}

function Remove-BoxGroup($token, $groupID)
{
    #deletes the given group based on group ID

    $uri = "https://api.box.com/2.0/groups/$groupID"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers -ContentType "application/x-www-form-urlencoded"
}

function Add-BoxGroupMember($token, $userID, $groupID)
{
    #adds selected member to given group
    #return group member detail

    $uri = "https://api.box.com/2.0/group_memberships"
    $headers = @{"Authorization"="Bearer $token"}
    $json = '{ "user": { "id": "' + $userID + '"}, "group": { "id": "' + $groupID + '" } }'

    $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "application/json"
    
}

function Remove-BoxGroupMember($token, $userID, $groupID)
{
    $members = Get-BoxGroupDetails -token $token -groupID $groupID

    for($i =  0; $i -lt $members.Count; $i++)
    {
        if($members[$i].user.id -eq $userID)
        {
            $membershipID = $members[$i].id
            $i = $members.Count + 1
        }
    }

    $result = Remove-BoxGroupMembership -token $token -membershipID $membershipID
}

function Remove-BoxGroupMembership($token, $membershipID)
{
    #deletes the given membership based on membership ID

    $uri = "https://api.box.com/2.0/group_memberships/$membershipID"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers -ContentType "application/x-www-form-urlencoded"
}

function Get-BoxGroupMembers($groupID, $token)
{
    #input: group id, token
    #output: group membership in hash table of name, ID 

    $uri = "https://api.box.com/2.0/groups/$groupID/memberships"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"

    $var = @{} #variable to hold the member hash table

    #this is the base case of the first 100 members

    $members = $return.entries
        
    foreach($member in $members.user)
    {
        $var.Add($member.login,$member.id)
    }

    if($return.total_count -le $return.limit)
    {
        #there are no more than 100 members, no need to make additional API calls
        return $var
    }
    else
    {
        #more than 100 members exist so additional API calls are needed until total_count is reached

        $returned = $return.limit #update the number returned so far

        #iterate through the remaining entries in 100 member pages
        while($returned -le $return.total_count)
        {
            $uri = "https://api.box.com/2.0/groups/$groupID/memberships?offset=$returned"
            $more_return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
            $members = $more_return.entries
            $returned += $more_return.limit

            foreach($member in $members.user)
            {
                $var.Add($member.login,$member.id)
            }
        }

        return $var
    }
}

function Get-BoxAllGroups($token)
{
    $uri = "https://api.box.com/2.0/groups?fields=name,description,provenance,external_sync_identifier,invitability_level,member_viewability_level"
    $headers = @{"Authorization"="Bearer $token"}
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    #by default, only 100 groups are returned. If more groups exist, they must be iterated through in sets of 1000
    if($return.total_count -le $return.limit)
    {
        return $return.entries
    }
    else
    {
        $returned = $return.limit

        $groups = $return.entries

        while($returned -le $return.total_count)
        {
            #get the next batch of groups
            $uri = "https://api.box.com/2.0/groups?fields=name,description,provenance,external_sync_identifier,invitability_level,member_viewability_level,limit=1000&offset=$returned"
            $more_return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
            $groups += $more_return.entries
            $returned += $more_return.limit
        }
        return $groups
    }
}

function Get-BoxGroupDetails($token, $groupID)
{
    #input: group id
    #output: group details including partial member list
    $uri = "https://api.box.com/2.0/groups/$groupID/memberships"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    return $return.entries
}

function Get-BoxGroup($token, $groupID)
{
	#input: group id
    #output: group fields
    $uri = "https://api.box.com/2.0/groups/$groupID" + "?fields=name,description,provenance,external_sync_identifier,invitability_level,member_viewability_level"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    return $return
}
