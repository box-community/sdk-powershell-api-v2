# Function to get all users back for an Enterprise
function Get-BoxAllUsers($token)
{
    $uri = "https://api.box.com/2.0/users"
    $headers = @{"Authorization"="Bearer $token"}
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    #by default, only 100 user are returned. If more groups exist, they must be iterated through in sets of 1000
    $totUsers = $return.total_count

    # CAUTION: Adding echo statements for debugging will output to returned result

    if($return.total_count -le $return.limit)
    {
        return $return.entries
    }
    else
    {
        $returned = $return.limit
        #$returned = 100000

        $users = $return.entries
        while($returned -le $return.total_count)
        {
            #get the next batch of users
            $rd = Get-Date
            $uri = "https://api.box.com/2.0/users?limit=1000&offset=$returned"
            $more_return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
            $users += $more_return.entries
            $returned += $more_return.limit
        }
        
        return $users
    }
}
# Function to get a Box UserID for a given Box Username
function Get-BoxUserID($username, $token)
{
    #returns the Box user id number for a given username
    $uri = "https://api.box.com/2.0/users?filter_term=" + $username + "&fields=id"
    $headers = @{"Authorization"="Bearer $token"} 
    
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    if($return.total_count -eq 0){return $null}
    else {return $return.entries.id}
}
# Function to get a user object back for a given username
function Get-BoxUser($username, $token)
{
    #returns the Box user id number for a given username
    $uri = "https://api.box.com/2.0/users?filter_term=" + $username
    $headers = @{"Authorization"="Bearer $token"} 
    
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
    
    if($return.total_count -eq 0){return $null}
    else {return $return.entries}
}
# Function to get a user object back for a given ID
function Get-BoxUser-FromId($id, $token)
{
    #returns the Box user information for a given id
    $uri = "https://api.box.com/2.0/users/" + $id
    $headers = @{"Authorization"="Bearer $token"}
    
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    return $return
}

# Function to create a new user
function New-BoxUser($login, $name, $token)
{
    $uri = "https://api.box.com/2.0/users"
    $headers = @{"Authorization"="Bearer $token"}

    $json = '{'
    $json += '"login": "' + $login + '",'
    $json += '"name": "' + $name + '"'
    $json += '}'

    $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "application/json"

    return $result.id
}

# function to remove a Box user
function Remove-BoxUser($id, $token)
{
    #sets the given attribute to be the value passed
    $uri = "https://api.box.com/2.0/users/" + $id
    $headers = @{"Authorization"="Bearer $token"}

    $return = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"

    return $return
}

# Function to set an attribute on a user object
function Set-BoxUser($id, $attribute, $value, $token)
{
    #sets the given attribute to be the value passed
    $uri = "https://api.box.com/2.0/users/" + $id
    $headers = @{"Authorization"="Bearer $token"}

    $json = '{ "' + $attribute + '": "' + $value + '"}'

    $return = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $json -ContentType "application/json"

}