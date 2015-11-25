# This script will aquire a new authorization code and access tokens. This will launch a browser 
# and request that you authorize your app to grant the oAuth code. This must happen quickly due
# to timeouts (30 seconds). Paste the return URL in the powershell windows when prompted and 
# the tokens will be aquired using the code and stored in the registry. Creating the registry 
# keys will require the script be run as an administrator.


$c_id = "<your client ID>"
$c_secret = "<your client secret>"

$code = New-BoxoAUTHCode -clientID $c_id

New-BoxAccessTokens -clientID $c_id -client_secret $c_secret -code $code