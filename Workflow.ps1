# This script is to perform the CSR workflow for Power BI Reports
# It performs various activity and it varies based on the report workflow.
# We are using Power BI REST API to perform these workflows. For full documentation on the REST APIs, see:
# https://msdn.microsoft.com/en-us/library/mt203551.aspx 

# Instructions:
# 1. Install PowerShell (https://msdn.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell) and the Azure PowerShell cmdlets (https://aka.ms/webpi-azps)
# 2. Fill in the parameters below
# 3. Run the PowerShell script


###############################################################################
##
##  ##  Revision History:
##
##  DATE    DEVELOPER   COMMENTS
## -------- ----------- -----------------------------------------------
## 29-Dec-20 Hariharan Created script
## 
############################################################################### 
###############################################################################

function GetAuthToken
{
    $clientId = "dde615b4-27d7-4a8f-8b98-a727197ff1b7" #Changeit

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

#Generic Retry logic
function Retry-Command($Command,$Action) {
    $currentRetry = 0;
    $success = $false;
    
        do {
        try 
        { 
            $result = & $Command;
            $success = $true;
            return $result
        } 
        catch [System.Exception] 
        {
          if ($currentRetry -gt 3) {
          $message = "Tried 3 times and Can not perform " + $Action +". The error: " + $_.Exception.ToString();
          #WriteLog($message)
          
          ###Send Email to Admin to take action.
          #$To = ".com"
          #$Attachment = $LogFile
          #$Subject = "CDDR Workflow Failure -" + $report_name 
          #$Body = "Please re-run the CSR workflow script. Go through the attached log for more information"
          #mailwithattachment -To $To -Subject $Subject -Body $Body -Attachment $Attachment

          throw $message;
          $success = $false;
          return $success
            } else {
                #Log-Debug "Sleeping before $currentRetry retry of command";
                Start-Sleep -s 1;
            }
            $currentRetry = $currentRetry + 1;
        }
    } while (!$success)
    }

#Check Dataset Refresh Status
function GetQuickReportRefreshStatus($uri, $auth_header) {
    $Refresh_status_call = "Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET –Verbose"
    WriteLog ("Quick Refresh_status_call:{0} " -f $Refresh_status_call )
    
    $command={Invoke-RestMethod -Uri $uri –Headers $auth_header –Method GET –Verbose}
    $result=Retry-Command -Command $command -Action "Quick Refresh Status"
    $reports = $result.value[0]
    $report_status = $reports.status
      
    Return $report_status
}

#Export the report
function CallReportExport($body,$Exporturi,$ExportStatusuri,$Filefullname,$auth_header) {

  $Export_call = "Invoke-RestMethod -Uri $Exporturi –Headers $auth_header –Method POST -Body $body –Verbose"
  #WriteLog ("Export_call:{0} " -f  $Export_call )
  $command={Invoke-RestMethod -Uri $Exporturi –Headers $auth_header –Method POST -Body $body –Verbose}
  $FileExport=Retry-Command -Command $command -Action "Export Call"
  $export_id = $FileExport.id
  #WriteLog ("Result from File Export Call: {0}" -f $FileExport)
  #Write-Host ("Result from File Export Call : {0}" -f $FileExport) -ForegroundColor White -BackgroundColor Blue
        
  #Get export File Status
  $export_status_uri = "$ExportStatusuri/$export_id"
  $export_stat_cmd =  "Invoke-RestMethod -Uri $export_status_uri –Headers $auth_Header –Method GET"
  #WriteLog ("Export File Status:{0} " -f  $export_stat_cmd )
  
  #Check the file status in a loop until status changed to Succeeded
  
  do {
      #sleep -s 2
      Start-sleep -milliseconds 2000
      $command={Invoke-RestMethod -Uri $export_status_uri –Headers $auth_Header –Method GET}
      $FileStatus=Retry-Command -Command $command -Action "Export Call Status"
      $ExportStatus=$FileStatus.status
      Write-Host($ExportStatus) -ForegroundColor White -BackgroundColor Blue
      #WriteLog($ExportStatus)
     }until ($ExportStatus -eq "Succeeded" -or $ExportStatus -eq "Failed" )
    
  #Download the file
  if($ExportStatus -eq "Succeeded")
   {
     $download_uri = "$export_status_uri/file"
     $file_path_uri = "Invoke-RestMethod -Uri $download_uri –Headers $auth_Header –Method GET -OutFile $Filefullname"
    # WriteLog ("Download file call:{0} " -f  $file_path_uri )
     
     $command={Invoke-RestMethod -Uri $download_uri –Headers $auth_Header –Method GET -OutFile $Filefullname}
     $File=Retry-Command -Command $command -Action "Download File"
     #WriteLog ("**********File Downloaded successfully - Result from the call:{0}" -f $File)
     Write-Host ("*******File Downloaded Successfully.") -ForegroundColor White -BackgroundColor Green
    }
    else{
      #    WriteLog ("Error: File Status:{0} File not Downloaded" -f $status)
          Write-Host ("Error: File Status:{0} File not Downloaded $FileStatus.error" -f $ExportStatus) -ForegroundColor White -BackgroundColor DarkRed
            
        }
    Return $ExportStatus
}


############## Main Script

#-------Workflow 1 -----------

#Step 1 - Get Auth Token
$token = GetAuthToken
$auth_header = @{
    'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
    }

#Step 2 - Get Dataset Refresh
$Group_ID ="625e3089-da3c-4ea5"
$DatasetID ="10a4d495-c4f2-480e-9a92"
$refresh_uri = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/datasets/$DatasetID/refreshes?%24top=1"

Invoke-RestMethod -Uri $refresh_uri –Headers $auth_header –Method GET –Verbose

#Step 3 - Export Report

$Report_ID="a14adcad-52da0ec2b6d4ef"
$Exporturi = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/ExportTo"
$ExportStatusuri="https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/Exports"
$filefullnameDC = "D:\Exports\ExportReport_New.xlsx"


$StartDate = (get-date (get-date).addDays(-1) -UFormat "%Y-%m-%d")
$body = "{`"format`":`"XLSX`", 
           `"paginatedReportConfiguration`":{
           `"parameterValues`":[
            {`"name`":`"EnterDate`",`"value`":""$StartDate""}
           
            ]
            }
           }"
    
CallReportExport -Body $body -Exporturi $Exporturi -ExportStatusuri $ExportStatusuri -Filefullname $filefullnameDC -auth_header $auth_header

    