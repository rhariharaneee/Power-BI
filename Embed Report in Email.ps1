function GetAuthToken
{
    $clientId = "your App client id" #Changeit

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


function mailwithattachment ($To,$Subject,$Body,$Attachment) {

 $SendMailHash = @{
                'From' = $From   
                'To' = $To
                'Subject' = $Subject
                'Priority' = 'Normal'
                'smtpServer' = $SMTPServer
                'BodyAsHTML' = $true
            }
  $MailStatus="Not sent"
 
         $SendMailHash.Body = $Body
         $SendMailHash.Attachments = $Attachment
         $SendMailHash.Credential = $cred
       
 $mail_count = 1
 do {
      try {   
            send-mailmessage @SendMailHash -ErrorAction Stop
            Write-Host("Email sent successfully")
            WriteLog ("Email sent successfully")
            $MailStatus="Sent Successfully"
            break
           }
      catch [System.Exception] {
           $mail_count++
           #$err_val = $($Error[0])
           $err_val = $_.Exception.Message
           Write-Host("Failed to send message Trial:{0} Error:{1} " -f $mail_count, $err_val)
           if ($mail_count -eq 3)   {
                    Write-Host("Error: Max trails {0}  reached, Failed to send Email : Error:{1}" -f $mail_count, $err_val)
                    WriteLog ("Error: Max trails {0}  reached, Failed to send Email : Error:{1}" -f $mail_count, $err_val)
                    }
             }
   }until ($mail_count -eq 3)

   Return $MailStatus

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
          $To = "Email Address"
          $Attachment = $LogFile
          $Subject = "Sample Failure"
          $Body = "Take action"
          mailwithattachment -To $To -Subject $Subject -Body $Body -Attachment $Attachment

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
   #   WriteLog($ExportStatus)
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

#Convert the word document into html
function WordtoHtml ($path,$htmlfilename){
    $word_app = New-Object -ComObject Word.Application
    $document = $word_app.Documents.Open($path)
    #WriteLog "Converting ${htmlfilename} ..." 
    Write-Host "Converting ${htmlfilename} ..." 
    $saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatFilteredHTML");
    $document.SaveAs([ref] $htmlfilename, [ref] $saveFormat)
    $document.Close()
    Write-Host "Complete converting word document to html " -BackgroundColor "Green" -ForegroundColor "Black";
    #WriteLog("*********Complete converting word document to html ") -BackgroundColor "Green" -ForegroundColor "Black";
    $word_app.Quit()
}

####################### Main Script
## Export


    $token = GetAuthToken
    $auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
    }

    $Group_ID="your workspace id"
    $Report_ID="your paginated report id"
    $Exporturi = "https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/ExportTo"
    $ExportStatusuri="https://api.powerbi.com/v1.0/myorg/groups/$Group_ID/reports/$Report_ID/Exports"
    $filefullnameDC = "D:\EmbedReport.docx"


    $StartDate = (get-date (get-date).addDays(-1) -UFormat "%Y-%m-%d")
    $body = "{`"format`":`"DOCX`", 
           `"paginatedReportConfiguration`":{
           `"parameterValues`":[
            {`"name`":`"EnterDate`",`"value`":""$StartDate""}
           
            ]
            }
           }"
    
    $ReportExportStatus_1=CallReportExport -Body $body -Exporturi $Exporturi -ExportStatusuri $ExportStatusuri -Filefullname $filefullnameDC -auth_header $auth_header

    $Path = $filefullnameDC
    $htmlfilename = "D:\EmbedReport.html"
    WordtoHtml -path $Path -htmlfilename $htmlfilename

     $Subject = "Smaple Embed - "+$Timestamp 
     $Body = Get-Content $htmlfilename -Raw
  
     $MailStatus= mail -To $To -Subject $Subject -Body $Body
    