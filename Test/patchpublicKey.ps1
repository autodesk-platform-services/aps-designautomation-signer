$client_id = $env:CLIENT_ID
$client_secret = $env:CLIENT_SECRET
if ([System.String]::IsNullOrEmpty($client_id)) {
    $client_id = Read-Host -Prompt "Enter Forge Client Id"
    $env:CLIENT_ID = $client_id
}

if ([System.String]::IsNullOrEmpty($client_secret)) {
    $client_secret = Read-Host -Prompt "Enter Forge Client Secret"
    $env:CLIENT_SECRET = $client_secret
}
$headers = @{}
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
try {
    $response = Invoke-WebRequest -Uri "https://developer.api.autodesk.com/authentication/v1/authenticate" -Method POST -Headers $headers  -ContentType "application/x-www-form-urlencoded" -Body "client_id=${client_id}&scope=data%3Awrite%20data%3Aread%20bucket%3Aread%20bucket%3Aupdate%20bucket%3Acreate%20code%3Aall&grant_type=client_credentials&client_secret=${client_secret}&="
}
catch {
    if (!$?) {
        throw $_.ErrorDetails.Message
    } 
}
$response = ConvertFrom-Json -InputObject $response.Content
$bearer = "Bearer $($response.access_token)"
$headers = @{}
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", $bearer)
$publicKey = Get-Content ".\mypublickey.json"
$body = "{'publicKey':$publicKey}"
try {
    $response = Invoke-WebRequest -Uri 'https://developer.api.autodesk.com/da/us-east/v3/forgeapps/me' -Method PATCH -Headers $headers  -ContentType 'application/json' -Body $body
}
catch {
    if (!$?) {
        throw $_.ErrorDetails.Message
    } 
}

Write-Output $response