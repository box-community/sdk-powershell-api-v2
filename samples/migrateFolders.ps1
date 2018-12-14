# Content Functions

function Move-BoxFolder($token, $newParent, $folderID)
{
    $uri = "https://api.box.com/2.0/folders/$folderID/"
    $headers = @{"Authorization"="Bearer $token"}
 
    $json = '{"parent": {"id": "' + $newParentID + '"}}'
   
    $return = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $json -ContentType "application/x-www-form-urlencoded"
}

function Copy-BoxFolder($token, $newParentID, $folderID)
{
    $uri = "https://api.box.com/2.0/folders/$folderID/copy"
    $headers = @{"Authorization"="Bearer $token"}
 
    $json = '{"parent": {"id": "' + $newParentID + '"}}'
   
    $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "application/x-www-form-urlencoded"
}

function Get-BoxSubItems($token, $parent)
{
    #returns all items in the given parent folder
    $uri = "https://api.box.com/2.0/folders/$parent/items"
    $headers = @{"Authorization"="Bearer $token"}
    $return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"

    if($return.total_count -le $return.limit)
    {
        return $return.entries
    }
    else
    {
        #handle paging when over 1000 entries are returned
        $returned = $return.limit

        $folders = $return.entries

        while($returned -le $return.total_count)
        {
            #get the next page of folders
            $uri = "https://api.box.com/2.0/users?limit=1000&offset=$returned"
            $more_return = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "applicaiton/x-www-form-urlencoded"
            $folders += $more_return.entries
            $returned += $more_return.limit
        }
        return $folders
    }
}


#takes iterates through each sub-folder any copies the folder to a username with the same name

#the parent migration folder
$parent = "61105381618"

#return all sub items of the parent
$subfolders = Get-BoxSubItems -token $token -parent $parent

foreach($item in $subfolders)
{
    if($item.type -eq "folder")
    {
        #the item is a folder
        #get the destination user ID
        $copyToID = Get-BoxUserID -token $token -username $item.name

        #create a new collaboration
        $uri = "https://api.box.com/2.0/collaborations"
        $headers = @{"Authorization"="Bearer $token"}
 
        $json = '{"item":{"id": "' + $item.id + '","type": "folder"},"accessible_by":{"id":"' + $copyToID + '","type":"user"},"role":"co-owner"}'

        $return = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json -ContentType "application/x-www-form-urlencoded"

        #new collaboration created, now set the collaborator as the owner

        $collabID = $return.id

        $uri = "https://api.box.com/2.0/collaborations/$collabID"
 
        $json = '{"role":"owner"}'
        $collab = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $json -ContentType "application/x-www-form-urlencoded"

        #remove previous collaborator
        $folderID = $item.id

        $uri = "https://api.box.com/2.0/folders/$folderID/collaborations"
        $collab = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType "application/x-www-form-urlencoded"

        $collabID = $collab.entries[0].id
        $uri = "https://api.box.com/2.0/collaborations/$collabID"
        Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers -ContentType "application/x-www-form-urlencoded"
    }
}