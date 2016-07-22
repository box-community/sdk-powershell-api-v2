# Function to get initial OAuth token
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
# Function to get new OAuth tokens saved to registry
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
# Function to get new OAuth tokens, but save tokens to a secure directory
function New-BoxAccessTokens($clientID,$client_secret,$code,$secure_dir)
{
    $data = "grant_type=authorization_code&code=" + $code + "&client_id=" + $clientID + "&client_secret=" + $client_secret
    Write-Host $data
    $uri = "https://www.box.com/api/oauth2/token"

    $json = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/x-www-form-urlencoded" -Body $data
    Write-Host $json

    if(-not (Test-Path $secure_dir))
    {
        $response = Read-Host "Secured directory $secure_dir does not exist. Create (requires Administrative rights)? [Y/N]"
        if($response.ToUpper() -eq "Y")
        {
            try{
                $dir = New-Item -path $secure_dir -ItemType "directory"
            }
            catch
            {
                Write-Host "Unable to create directory."
                return $false
            }
        }
        else {return $false}
    }

    $second = ConvertTo-SecureString -AsPlainText (Get-date -Format "yyyy-MM-dd HH:mm:ss") -Force
    $unsecure_date = (Get-date -Format "yyyy-MM-dd HH:mm:ss")
    $secure_date = ConvertTo-SecureString -AsPlainText $unsecure_date -Force

    $secure_access_token = ConvertFrom-SecureString $json.access_token
    $secure_refresh_token = ConvertFrom-SecureString $json.refresh_token
    $secure_token_time = ConvertFrom-SecureString -SecureString $secure_date

    #write secure files out
    $dir = New-ItemProperty -Path $secure_dir -Name "access_token" -Value $json.access_token -Force
    $dir = New-ItemProperty -Path $secure_dir -Name "refresh_token" -Value $json.refresh_token -Force
    $dir = New-ItemProperty -Path $secure_dir -Name "token_time" -Value (Get-date -Format "yyyy-MM-dd HH:mm:ss") -Force

    return $true
}
# Function to check existing access token and decide if a new one is needed, if so get it using refresh token and update them in registry
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
# Function to check existing access token and decide if a new one is needed, if so get it using refresh token and update in secure_dir files
function Get-BoxTokenFromFile($cid, $cs, $secure_dir)
{

    $debug_log = ""
    $token_time_file = "$secure_dir\token-time"
    $refresh_token_file = "$secure_dir\refresh-token"
    $access_token_file = "$secure_dir\access-token"
    $last_refresh = Get-Content -Path $token_time_file
    $refresh_token = Get-Content -Path $refresh_token_file
    $access_token = Get-Content -Path $access_token_file
    $debug_file = "e:\scripts\box\debug.txt"
    
    #$last_refresh

    $debug_log += "Last refresh time was $last_refresh`r`n"
    #$debug_log += "Current token is $access_token`r`n"
    #$debug_log += "Current refresh token is $refresh_token`r`n"

    #check the last refresh
    if(((Get-Date $last_refresh).AddMinutes(58)) -le (Get-Date))
    {
        $debug_log += "Current token is expired - current time is $(Get-Date)`r`n"

        #if the token age is over a hour, we need to refresh
        $uri = "https://app.box.com/api/oauth2/token”
        $data = "grant_type=refresh_token&refresh_token=$refresh_token&client_id=$cid&client_secret=$cs"

        try{
            $json = Invoke-RestMethod -Uri $uri -Method Post -Body $data
        }
        catch{

            $debug_log += "Error on API call:`r`n$_`r`n"
            $debug_log | Out-File $debug_file -Append


            return $null
        }

        $debug_log += "Query sent. Result:`r`n $json"

        #update files with new oauth data
        $json.refresh_token > $refresh_token_file
        $new_token_time = (Get-date -Format "yyyy-MM-dd HH:mm:ss")
        $new_token_time > $token_time_file
        $json.access_token > $access_token_file

        $debug_log += "New refresh time is $new_token_time`r`n"
        #$debug_log += "New token is $json.access_token`r`n"
        #$debug_log += "New refresh token is $json.refresh_token`r`n"

        $debug_log | Out-File $debug_file -Append

       return $json.access_token
    }
    else
    {
        $debug_log += "Current time is $(Get-Date)`r`n"
        $debug_log += "Current token is still valid`r`n"

        $debug_log | Out-File $debug_file -Append

       #the token is still valid
       return $access_token
    }
}