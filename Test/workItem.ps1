#!/usr/bin/env pwsh
Import-Module Newtonsoft.Json
$client_id = $env:CLIENT_ID
$client_secret = $env:CLIENT_SECRET
#Place your activity

$activity = 'adesk.HelloWorld+prod'
 

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
Write-Output "Get Activity Details ${activity}"
$headers = @{}
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", $bearer)

try {
    $response = Invoke-WebRequest -Uri "https://developer.api.autodesk.com/da/us-east/v3/activities/${activity}" -Method GET -Headers $headers -ContentType 'application/json'
}
catch {
    if (!$?) {
        throw $_.ErrorDetails.Message
    }
}

$response = $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 100
Write-Output $response
$signTxt = Get-Content ".\sign.txt"
Write-Output "Running Workitem"
$workItem = "{""activityId"":""$activity"", ""signatures"":{""activityId"":""$signTxt""}}"
$status = @('Cancelled',
    'FailedDownload',
    'FailedInstructions',
    'FailedLimitDataSize',
    'FailedUpload',
    'Success'    
)
#Type to get Workitem Status information
class Stats {
    [System.DateTimeOffset] $timeQueued
    [System.DateTimeOffset] $timeDownloadStarted
    [System.DateTimeOffset] $timeInstructionsStarted
    [System.DateTimeOffset] $timeInstructionsEnded
    [System.DateTimeOffset] $timeUploadEnded
    [System.DateTimeOffset] $timeFinished
}
class WorkItemStatus {
    [string] $status
    [string] $reportUrl
    [Stats]  $stats
    [string] $id
}
class WSResponse {
    [string] $action
    [WorkItemStatus] $data
}

try {
    $shouldExit = $false
    $URL = 'wss://websockets.forgedesignautomation.io'
    $WS = New-Object System.Net.WebSockets.ClientWebSocket                                                
    $CT = New-Object System.Threading.CancellationToken
    $WS.Options.UseDefaultCredentials = $true
    #Get connected
    $Conn = $WS.ConnectAsync($URL, $CT)
    While (!$Conn.IsCompleted) { 
        Start-Sleep -Milliseconds 100 
    }
    Write-Output "Connected to $($URL)"
    $Size = 4096
    $Array = [byte[]] @(, 0) * $Size
    $body = "{""action"":""post-workitem"", ""data"":$workItem,""headers"": {""Authorization"":""$bearer""}}" | ConvertFrom-Json | ConvertTo-Json  
    Write-Output $body
    #Send Starting Request
    $Command = [System.Text.Encoding]::UTF8.GetBytes($body)
    $Send = New-Object System.ArraySegment[byte] -ArgumentList @(, $Command)            
    $Conn = $WS.SendAsync($Send, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $CT)   
    Write-Output "Finished Sending Request"        
    #Start reading the received items
    While (!$shouldExit) {                        

        $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(, $Array)
        $Conn = $WS.ReceiveAsync($Recv, $CT)
        While (!$Conn.IsCompleted) { 
            #Write-Host "Sleeping for 100 ms"
            Start-Sleep -Milliseconds 100 
        }
        Write-Output "Finished Receiving Request"
        $response = [System.Text.Encoding]::utf8.GetString($Recv.array)
        if ($response.Contains("progress")) {
            #we are not interested here, lets skip.
            continue
        }
        $jsonSettings = [Newtonsoft.Json.JsonSerializerSettings]::new()
        $jsonSettings.MaxDepth = $response.Length
        $response = [Newtonsoft.Json.JsonConvert]::DeserializeObject($response, [WSResponse], $jsonSettings)
        $action = $response.action       
        if ($action -eq "error") {
            Write-Output $response.ToString()
            $shouldExit = $true
            break
        }
        if ($action -eq "status") {
            $data = $response.data
            Write-Output $data.status
            switch ($response.data.status) {              
                $status[0..4] {
                    Write-Output $response.data.status
                    $shouldExit = $true
                    break
                }
                $status[5] {
                    $shouldExit = $true
                    Write-Output "Downloading Report log.."
                    Invoke-RestMethod -Uri $response.data.reportUrl -OutFile ".\report.log"                    
                    break
                }             
            }
        }
    }    
}
finally {
    if ($WS) { 
        Write-Host "Closing websocket"
        $WS.Dispose()
    }
}