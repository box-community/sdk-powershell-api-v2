## If you use a proxy, define it here (ie 'http://server.domain.tld:port')
#$PSDefaultParameterValues = @{'Invoke-RestMethod:Proxy' = 'http://server.domain.tld:1234'}

function New-BoxGroup($token, $name)
{
    #create a new Box group with the name given in $name
    #returns the groupid

    $uri = "https://api.box.com/2.0/groups"
    $headers = @{"Authorization"="Bearer $token"}

    $json = '{"name": "' + $name + '"}'
    
    $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "applicaiton/json"

    return $return.id
}

function New-BoxGroup2($token, $name)
{
    #create a new Box group with the name given in $name
    #returns the groupid

    $uri = "https://api.box.com/2.0/groups"
    $headers = @{"Authorization"="Bearer $token"}

    $json = '{"name": "' + $name + '","provenance": "MSAD","invitability_level": "all_managed_users","member_viewability_level": "admins_and_members"}'
    
    $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "applicaiton/json"

    return $return.id
}

function Get-BoxGroup($token, $groupID)
{
    $uri = "https://api.box.com/2.0/groups/$($groupID)?fields=provenance,invitability_level,member_viewability_level"
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
    
    return $return
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

function Get-BoxAllUsers($token)
{
    $uri = "https://api.box.com/2.0/users"
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

        $users = $return.entries

        while($returned -le $return.total_count)
        {
            #get the next batch of groups
            $uri = "https://api.box.com/2.0/users?limit=1000&offset=$returned"
            $more_return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
            $users += $more_return.entries
            $returned += $more_return.limit
        }
        return $users
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

function Get-BoxUserID($username, $token)
{
    #returns the Box user id number for a given username
    $uri = "https://api.box.com/2.0/users?filter_term=" + $username + "&fields=id"
    $headers = @{"Authorization"="Bearer $token"} 
    
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
    
    if($return.total_count -eq 0){return $null}
    else {return $return.entries.id}
}

function Get-BoxUser($username, $token)
{
    #returns the Box user id number for a given username
    $uri = "https://api.box.com/2.0/users?filter_term=" + $username
    $headers = @{"Authorization"="Bearer $token"} 
    
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
    
    if($return.total_count -eq 0){return $null}
    else {return $return.entries}
}

function Set-BoxUser($id, $quota, $token)
{
    #sets information about the user.  Currently will set the quota.  A value of -1 sets it to unlimited. $quota is a value in GB
    $uri = "https://api.box.com/2.0/users/" + $id
    $headers = @{"Authorization"="Bearer $token"} 

    if($quota -ne -1)
    {
        $quota = $quota * 1073741824
    }

    $json = '{ "space_amount": "' + $quota + '"}'

    $return = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $json -ContentType "applicaiton/json"

}
function New-BoxoAUTHCode($clientID)
{
    $sec_token_sent = "security_token%3DKnhMJatFipTAnM0nHlZA"
    $uri = "https://www.box.com/api/oauth2/authorize?response_type=code&client_id=$clientID&state=$sec_token_sent"

    Write-Host "Please visit the URL, authorize the app and note the code value returned."
    Write-Host "You have 30 seconds to paste the resulting URL." -ForegroundColor Yellow
    Write-Host "The URL is $uri"

    $val = Read-Host "Ready? [Y - launch a browser to URL, N - Do it manually]"
    if($val.ToUpper() -eq "Y")
    {
        Start-Process $uri
    }

    $response = Read-Host "Paste return URL."

    $sec_token = $response.Split('=')[1].Substring(0,$response.Split('=')[1].Length - 5)
    if($sec_token_sent -ne $sec_token)
    {
        Write-Host "Warning: Security tokens do not match!" -ForegroundColor Red
    }

    return $response.Split('=')[2]
}

function New-BoxAccessTokens($clientID, $client_secret,$code)
{
    $data = "grant_type=authorization_code&code=" + $code + "&client_id=" + $clientID + "&client_secret=" + $client_secret
    $uri = "https://www.box.com/api/oauth2/token"

    $json = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/x-www-form-urlencoded" -Body $data
    

    $reg_key = "HKLM:\SOFTWARE\BoxAPI"

    if(-not (Test-Path $reg_key))
    {
        $response = Read-Host "Registry key $reg_key does not exist. Create (requires Administrative rights)? [Y/N]"
        if($response.ToUpper() -eq "Y")
        {
            try{
                $reg = New-Item $reg_key -ItemType Registry -Force
            }
            catch
            {
                Write-Host "Unable to write to registry."
                return $false
            }
        }
        else {return $false}
    }

    #write registry entries
    $reg = New-ItemProperty -Path $reg_key -Name "access_token" -Value $json.access_token -Force
    $reg = New-ItemProperty -Path $reg_key -Name "refresh_token" -Value $json.refresh_token -Force
    $reg = New-ItemProperty -Path $reg_key -Name "token_time" -Value (Get-date -Format "yyyy-MM-dd HH:mm:ss") -Force

    return $true
}
function Get-BoxToken($clientID, $client_secret)
{
    ## $debug_log can be used to dump verbose information regarding token issues. By default it does not write the debug to the log.

    $debug_log = ""
    $reg_key = "HKLM:\SOFTWARE\BoxAPI"

    $last_refresh = Get-ItemProperty -Path $reg_key -Name "token_time"

    $debug_log += "Last refresh time was $($last_refresh.token_time)`r`n"
    $debug_log += "Current token is $($(Get-ItemProperty -Path $reg_key -Name "access_token").access_token) `r`n"
    $debug_log += "Current refresh token is $($(Get-ItemProperty -Path $reg_key -Name "refresh_token").refresh_token)`r`n"

    #check the last refresh
    if(((Get-Date $last_refresh.token_time).AddHours(1)) -le (Get-Date))
    {
        $debug_log += "Current token is expired - current time is $(Get-Date)`r`n"

        #if the token age is over a hour, we need to refresh
        $refresh_token = (Get-ItemProperty -Path $reg_key -Name "refresh_token").refresh_token
        $uri = "https://www.box.com/api/oauth2/token”
        $data = "grant_type=refresh_token&refresh_token=" + $refresh_token + "&client_id=" + $clientID + "&client_secret=" + $client_secret

        try{
            $json = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/x-www-form-urlencoded" -Body $data
        }
        catch{

            $debug_log += "Error on API call:`r`n$_`r`n"
            #$debug_log | Out-File c:\scripts\box\debug.txt -Append


            return $null
        }

        $debug_log += "Query sent. Result:`r`n $json"

        #update registry values
        $reg = Set-ItemProperty -Path $reg_key -Name "refresh_token" -Value $json.refresh_token -Force
        $reg = Set-ItemProperty -Path $reg_key -Name "token_time" -Value (Get-date -Format "yyyy-MM-dd HH:mm:ss") -Force
        $reg = Set-ItemProperty -Path $reg_key -Name "access_token" -Value $json.access_token -Force

        $debug_log += "New refresh time is $($(Get-ItemProperty -Path $reg_key -Name "token_time").token_time)`r`n"
        $debug_log += "New token is $($(Get-ItemProperty -Path $reg_key -Name "access_token").access_token)`r`n"
        $debug_log += "New refresh token is $($(Get-ItemProperty -Path $reg_key -Name "refresh_token").refresh_token)`r`n"

        #$debug_log | Out-File c:\scripts\box\debug.txt -Append

       return $json.access_token
    }
    else
    {
        $debug_log += "Current time is $(Get-Date)`r`n"
        $debug_log += "Current token is still valid`r`n"

        #$debug_log | Out-File c:\scripts\box\debug.txt -Append

       #the token is still valid
       return (Get-ItemProperty -Path $reg_key -Name "access_token").access_token
    }
}