# Author: Rudy Corradetti

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

#storage account sku we are changing all storage accounts in $csv to
$sku = "Standard_GRS"

#csv must be located in working directory
$csv = "Convert2GRS.csv"

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
            Write-Host "Setting $_.storageaccount to Standard-GRS..." 
            # Convert storage account to $sku      
            Set-AzStorageAccount -ResourceGroupName $_.resourcegroup -Name $_.storageaccount -SkuName $sku -WhatIf -ErrorAction Stop
        }
        catch {
            Write-Host "$_.storageaccount failed with a terminating error...waiting 5 seconds and attempting next storage account in list..."
            Start-Sleep -Seconds 5
        } 
    }
}
# live section
else {
    Import-CSV -Path $csv | ForEach-Object {
        try {
            $current_sub_id = (Get-AzContext).Subscription.id
            # Check if current az context is set to correct sub if not set to correct sub
            if ($_.subscription -ne $current_sub_id ) {
                Write-Host "Setting current subscription id to - $_.subscription..."
                # Convert storage account to $sku     
                Set-AzContext -Subscription $_.subscription -ErrorAction Stop
                Write-Host "Set context to $_.subscription..."
            }
            Write-Host "Setting $_.storageaccount to Standard-GRS..."       
            Set-AzStorageAccount -ResourceGroupName $_.resourcegroup -Name $_.storageaccount -SkuName $sku -ErrorAction Stop
            Write-Host "Success! Converted $_.storageaccount to $sku..."
        }
        catch {
            Write-Host "$_.storageaccount failed with a terminating error...waiting 5 seconds and attempting next storage account in list..."
            Start-Sleep -Seconds 5
        } 
    }      
}