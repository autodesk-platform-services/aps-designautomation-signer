Import-Module Newtonsoft.Json
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
Write-Output "Creating a nickname 'adesk'"
$headers = @{}
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
try {
	$response = Invoke-WebRequest -Uri "https://developer.api.autodesk.com/authentication/v1/authenticate" -Method POST -Headers $headers -ContentType "application/x-www-form-urlencoded" -Body "client_id=${client_id}&scope=data%3Awrite%20data%3Aread%20bucket%3Aread%20bucket%3Aupdate%20bucket%3Acreate%20code%3Aall&grant_type=client_credentials&client_secret=${client_secret}&="
}
catch {
	if (!$?) {
		throw $_.ErrorDetails.Message
	} 
}

$response = ConvertFrom-Json -InputObject $response.Content
$bearer = "Bearer $($response.access_token)"
$activityName = "HelloWorld"
$headers = @{}
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", $bearer)
 
try {
	$response = Invoke-RestMethod -Uri 'https://developer.api.autodesk.com/da/us-east/v3/forgeapps/me' -Method GET -Headers $headers -ContentType 'application/json'
	if ($response -eq $client_id ) {
		$response = Invoke-RestMethod -Uri 'https://developer.api.autodesk.com/da/us-east/v3/forgeapps/me' -Method PATCH -Headers $headers -ContentType 'application/json' -Body '{
			"nickname": "adesk"
		}'
	}
	Write-Output $response
}
catch {
	if (!$?) {
		throw $_.ErrorDetails.Message
	} 
}

Write-Output "Create activity"

$body = '{"commandLine":"$(engine.path)\\accoreconsole.exe /s \"$(settings[script].path)\"","engine":"Autodesk.AutoCAD+24","settings":{"script":"(print \"Hello World!\")\n"},"description":"Send String To Execute Test","id":"activityName"}'
$body = $body.Replace('activityName', $activityName)
try {
	$response = Invoke-WebRequest -Uri 'https://developer.api.autodesk.com/da/us-east/v3/activities' -Method POST -Headers $headers  -ContentType 'application/json' -Body $body
}
catch {
	if (!$?) {
		throw $_.ErrorDetails.Message
	} 
}
Write-Output $response
$headers = @{}
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", $bearer)
try {
	$response = Invoke-WebRequest -Uri "https://developer.api.autodesk.com/da/us-east/v3/activities/$activityName/aliases" -Method POST -Headers $headers -WebSession $session -ContentType 'application/json' -Body '{
		"version": 1,
		"id": "prod"
	}'
}
catch {
	if (!$?) {
		throw $_.ErrorDetails.Message
	} 
}
Write-Output $response