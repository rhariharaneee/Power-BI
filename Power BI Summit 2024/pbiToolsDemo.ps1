[CmdletBinding()] 
param 
( 
        [Parameter(Mandatory = $true)]         
[string] $Server, 
        [Parameter(Mandatory = $true)]         
[string] $Database  
) 
Write-Host "" 
Write-Host "Analysis Services instance: " -NoNewline 
Write-Host "$Server" -ForegroundColor Yellow 
Write-Host "Dataset name: " -NoNewline 
Write-Host "$Database" -ForegroundColor Green 
Write-Host "" 
Read-Host -Prompt 'Press [Enter] to close this window'  