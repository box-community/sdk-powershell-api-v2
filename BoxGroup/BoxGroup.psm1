# Group Functions
function New-BoxGroup()
{
    param(
    [Parameter(Mandatory=$true)] [string] $token,
    [Parameter(Mandatory=$true)] [string] $name,
    [string] $description,
    [string] $external_id,
    [string] $provenance,
    [string] $invitability,
    [string] $viewability
    ) 

    #create a new Box group with the name given in $name
    #returns the groupid

    $uri = "https://api.box.com/2.0/groups"
    $headers = @{"Authorization"="Bearer $token"}

    $json = '{"name": "' + $name + '"}'
    
    $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "applicaiton/json"

    return $return.id
}

function Remove-BoxGroup($token, $groupID)
{
    #deletes the given group based on group ID

    $uri = "https://api.box.com/2.0/groups/$groupID"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
}

function Add-BoxGroupMember($token, $userID, $groupID)
{
    #adds selected member to given group
    #return group member detail

    $uri = "https://api.box.com/2.0/group_memberships"
    $headers = @{"Authorization"="Bearer $token"}
    $json = '{ "user": { "id": "' + $userID + '"}, "group": { "id": "' + $groupID + '" } }'

    $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "applicaiton/json"
    
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

    $return = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
}

function Get-BoxGroupMembers($groupID, $token)
{
    $members = Get-BoxGroupDetails -token $token -groupID $groupID

    $var = @{}

    foreach($member in $members.user)
    {
        $var.Add($member.login,$member.id)
    }

    return $var
}

function Get-BoxAllGroups($token)
{
    $uri = "https://api.box.com/2.0/groups"
    $headers = @{"Authorization"="Bearer $token"}
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
    
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
            $uri = "https://api.box.com/2.0/groups?limit=1000&offset=$returned"
            $more_return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
            $groups += $more_return.entries
            $returned += $more_return.limit
        }
        return $groups
    }
}

function Get-BoxGroupDetails($token, $groupID)
{
    #input: group id
    #output: group details including member list
    $uri = "https://api.box.com/2.0/groups/$groupID/memberships"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
    
    return $return.entries
}