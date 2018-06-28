#retuns the specified folder
function Get-BoxFolder($token, $id)
{
    $uri = "https://api.box.com/2.0/folders/$id"
    $headers = @{"Authorization"="Bearer $token"}
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    return $return
}

#returns the items contained in a specified folder
function Get-BoxFolderItems($token, $id)
{
    $uri = "https://api.box.com/2.0/folders/$id/items"
    $headers = @{"Authorization"="Bearer $token"}
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    return $return.entries
}

#returns the folder collaborators
function Get-BoxFolderCollabs($token, $id)
{
    $uri = "https://api.box.com/2.0/folders/$id/collaborations"
    $headers = @{"Authorization"="Bearer $token"}
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"
    
    return $return.entries
}

#creates a new folder under the provided parent
function New-BoxFolder($token, $parent, $name)
{
    $uri = "https://api.box.com/2.0/folders"
    $headers = @{"Authorization"="Bearer $token"}

    $json = '{'
    $json += '"name": "' + $name + '",'
    $json += '"parent": {"id":"' + $parent + '"}'
    $json += '}'

    $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "application/json"

    return $result.id
}

#copy all of a users content
