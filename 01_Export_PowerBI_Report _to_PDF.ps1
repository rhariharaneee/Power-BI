#Author - Hariharan Rajendran MVP.
#Version - 1.1
#Title - Export Power BI Report into PDF
#Description - Use this script to export the report into pdf and save the pdf file in your local folder. 

# Parameters - fill these in before running the script!

$clientId = "Enter your Power BI App Client ID"
$Group_ID="Enter your Workspace ID"
$Report_ID="Enter your Report ID"
$Folder="Your local folder path"

# Authentication
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
# Building Rest API header with authorization token
$auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}
 
# Export REST API
# ==================================================================


# Export File - set the file format as pdf, ppt or png
 $uri = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/ExportTo"
 $body = "{`"format`":`"pdf`"}"
 $FileExport = Invoke-RestMethod -Uri $uri –Headers $auth_header –Method POST -body $body

# Get File Status
 $id = $FileExport.id
 $uri = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/Exports/$id"
 $FileStatus = Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET 

# Download the file
 $uri = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/Exports/$id/file"
 $File = Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET -OutFile $Folder+"_new.pdf"

 # ==============================
 # Code Completed

