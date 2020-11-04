# This script helps to export the report excel extract

# Parameters used in the below script
$clientId = "38dc2b75-bc97-4250-8952-c245348461c9"
$Group_ID="f4f55e16-8232-4d16-94b0-8745950b9988"
$Report_ID="19623b3e-ab6d-45bf-96b8-19b6fc41acc6"
$Folder="E:\CTS\Excel\"
$StatusCheck=0
$auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}

$Exporturi = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/ExportTo"
$body = "{`"format`":`"XLSX`", 
           `"paginatedReportConfiguration`":{
           `"parameterValues`":[
            {`"name`":`"CalDate`",`"value`":`"5/31/2011 12:00:00 AM`"}
            ]
            }
           }"

$filename = $Folder + "Unapproved.xlsx"
 

# End Parameters =======================================


 

# PART 1: Authentication
# ==================================================================
function GetAuthToken
{
    if(-not (Get-Module AzureRm.Profile)) {
      Import-Module AzureRm.Profile
    }
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://analysis.windows.net/powerbi/api"
    $authority = "https://login.microsoftonline.com/common/oauth2/authorize";
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
    return $authResult
}

# calling the GetAuthToken to generate the token
$token = GetAuthToken

 

## Call Export to File REST API
 try {
     $FileExport = Invoke-RestMethod -Uri $Exporturi –Headers $auth_header –Method POST -body $body 
     $id = $FileExport.id
   
} catch {
    # Dig into the exception to get the Response details.
    # Note that value__ is not a typo.
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    $StatusCheck = 1
    if($_.Exception.Response.StatusDescription -eq "unauthorized")
    {
     Write-Host "Check the report availability or access in the workspace"
    }
    elseif ($_.Exception.Response.StatusDescription -eq "Not Found")
    {
      Write-Host "Check the connection to Power BI Service"

    }

}

if($StatusCheck -eq 0)
{
#Get export File Status

 
 $Statusuri = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/Exports/$id"
 $FileStatus = Invoke-RestMethod -Uri $Statusuri –Headers $auth_header –Method GET 

#Check the file status in a loop until status changed to Succeeded
 DO
 {
 
   sleep -s 2
   $FileStatus = Invoke-RestMethod -Uri $Statusuri –Headers $auth_header –Method GET 
   $Status=$FileStatus.status
 
 }until ($status -eq "Succeeded" -or $status -eq "Failed" )
  

#Download the file
if($status -eq "Succeeded")
 
{
 
 $uri = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/Exports/$id/file"
 $Result = Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET -OutFile $filename

}
 else {
 Write-Host "File not Downloaed"
 }
}
 


