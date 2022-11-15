# Author: rcorradetti@littler.com

Write-Host "Please login to Azure PowerShell..."
Start-Sleep -Seconds 1
# connect to Azure PowerShell
try {
    Login-AzAccount -ErrorAction Stop
}
catch {
    Write-Host "Login-AZAccount failed with a terminating error. Exiting in 5 seconds..."
    Start-Sleep -Seconds 5
    Exit
}
Write-Host "Successfully logged into Azure PowerShell..."

#csv must be located in working directory
$csv = "ListofCerts2BeDeleted.csv"

# ask if preview or not
Function PreviewOrNah {
    $type = Read-Host "
    1 - Preview Mode
    2 - Live Mode
    Please choose"
    Switch ($type) {
        1 { $choice = "preview" }
        2 { $choice = "live" }
    }
    return $choice
}

$choiceresult = PreviewOrNah
# preview section
If ($choiceresult -eq "preview") {
    Import-CSV -Path $csv | ForEach-Object {  
        try {
            $current_sub_id = (Get-AzContext).Subscription.id
            # Check if current az context is set to correct sub if not set to correct sub    
            if ($_.subscription -ne $current_sub_id ) {
                Write-Host "Setting current subscription id to - $_.subscription..."
                Set-AzContext -Subscription $_.subscription -ErrorAction Stop
                Write-Host "Set context to $_.subscription..."
            }
            Write-Host "Deleting cert with $_.thumbprint..."  
            # what if delete certificate from app svc     
            Remove-AzWebAppCertificate -ResourceGroupName $_.resourcegroup -Thumbprint $_.thumbprint -WhatIf -ErrorAction Stop
            Write-Host "Success! Deleted cert with $_.thumbprint..."       
        }
        catch {
            Write-Host "Deleting cert with thumbprint: $_.thumbprint or Setting AZ context failed with a terminating error...waiting 5 seconds and attempting next certificate in list..."
            Start-Sleep -Seconds 5
        } 
    }
}
# live section
else {
    Import-CSV -Path $csv | ForEach-Object {
        try {
            $current_sub_id = (Get-AzContext).Subscription.id
            # Check is current az context is set to correct sub if not set to correct sub
            if ($_.subscription -ne $current_sub_id ) {
                Write-Host "Setting current subscription id to - $_.subscription..."
                Set-AzContext -Subscription $_.subscription -ErrorAction Stop
            }
            Write-Host "Deleting cert with $_.thumbprint..."       
            # delete certificate from app svc     
            Remove-AzWebAppCertificate -ResourceGroupName $_.resourcegroup -Thumbprint $_.thumbprint -Force
            Write-Host "Success! Deleted cert with $_.thumbprint..."       
        }
        catch {
            Write-Host "Deleting cert with thumbprint: $_.thumbprint or Setting AZ context failed with a terminating error...waiting 5 seconds and attempting next certificate in list..."
            Start-Sleep -Seconds 5
        } 
    }      
}