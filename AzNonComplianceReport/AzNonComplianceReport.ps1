# author: Rudy Corradetti

param (
    [switch]$BypassPrompts
)

# Filter section
$filterResourceTypes = @(
    'Microsoft.Resources/subscriptions',
    'Microsoft.Compute/virtualMachines',
    'Microsoft.Authorization/roleDefinitions'
)

# SQL Server Details (not working yet)
$SqlServerName = '<SQL Server Name>'
$DatabaseName = '<Database Name>'
$SqlUsername = '<SQL Username>'
$SqlPassword = '<SQL Password>'
$TableName = '<Table Name>'

# Welcome graphic
function ShowWelcomeGraphic {
    Write-Host @"
    ___        _   __            ______                      ___                       ____                        __ 
    /   |____  / | / /___  ____  / ____/___  ____ ___  ____  / (_)___ _____  ________  / __ \___  ____  ____  _____/ /_
   / /| /_  / /  |/ / __ \/ __ \/ /   / __ \/ __ `__ \/ __ \/ / / __ `/ __ \/ ___/ _ \/ /_/ / _ \/ __ \/ __ \/ ___/ __/
  / ___ |/ /_/ /|  / /_/ / / / / /___/ /_/ / / / / / / /_/ / / / /_/ / / / / /__/  __/ _, _/  __/ /_/ / /_/ / /  / /_  
 /_/  |_/___/_/ |_/\____/_/ /_/\____/\____/_/ /_/ /_/ .___/_/_/\__,_/_/ /_/\___/\___/_/ |_|\___/ .___/\____/_/   \__/                              
"@
}

# Call the welcome graphic function
ShowWelcomeGraphic

# Function to run the noncompliance report
function RunComplianceReport {
    param (
        [string]$ManagementGroupName,
        [string]$SubscriptionId,
        [string]$PolicyAssignmentName,
        [PSCredential]$SqlCredential
    )

    # Set output file path with the current date and tenant display name
    $tenantName = (Get-AzTenant | Select-Object -ExpandProperty Name) -replace ' ', '_'
    $fileNamePrefix = if ($ManagementGroupName -eq 'all' -or $SubscriptionId -eq 'all' -or $PolicyAssignmentName -eq 'all') {
        "AllPA_$tenantName"
    }
    else {
        "$ManagementGroupName-$SubscriptionId-$PolicyAssignmentName-$tenantName"
    }
    $outputFile = Join-Path -Path (Get-Location) -ChildPath "$fileNamePrefix-$((Get-Date -Format 'yyyyMMddHHmm')).csv"

    # Function to extract ResourceName from ResourceId
    function Get-ResourceNameFromId {
        param (
            [string]$ResourceId
        )

        # Extract ResourceName from ResourceId
        $parts = $ResourceId -split '/'
        $resourceNameIndex = $parts.Length - 1
        $resourceName = $parts[$resourceNameIndex]
        return $resourceName
    }

    # Function to retrieve PolicyDefinitionName
    function Get-PolicyDefinitionName {
        param (
            [string]$PolicyDefinitionId
        )

        $parts = $PolicyDefinitionId -split '/'
        $policyDefinitionNameIndex = $parts.Length - 1
        $policyDefinitionName = $parts[$policyDefinitionNameIndex]
        return $policyDefinitionName
    }

    # Get all management groups
    $managementGroups = if ($ManagementGroupName -eq 'all') { Get-AzManagementGroup } else { Get-AzManagementGroup | Where-Object { $_.Name -eq $ManagementGroupName } }

    # Initialize the progress bar for management groups
    $totalManagementGroups = $managementGroups.Count
    $currentManagementGroup = 0

    # Stats for management groups
    $totalManagementGroupResources = 0
    $totalManagementGroupNonCompliantResources = 0
    $duplicateManagementGroupResources = 0

    # Hashtable to track duplicate resources at the management group level
    $duplicateManagementGroupResourcesTable = @{}

    # Loop over all management groups
    foreach ($managementGroup in $managementGroups) {
        Write-Host "Checking management group $($managementGroup.Name)..." -ForegroundColor Cyan

        # Update the progress bar for management groups
        Write-Progress -Activity 'Checking Management Groups' -Status "$currentManagementGroup out of $totalManagementGroups done" -PercentComplete (($currentManagementGroup / $totalManagementGroups) * 100)
        $currentManagementGroup++

        # Get all non-compliant resources for the management group and policy assignment
        $nonCompliantResources = Get-AzPolicyState -ManagementGroupName $managementGroup.Name -Filter "ComplianceState eq 'NonCompliant'"
        if ($PolicyAssignmentName -ne 'all') {
            $nonCompliantResources = $nonCompliantResources | Where-Object { $_.PolicyAssignmentName -eq $PolicyAssignmentName }
        }

        # Filter out the specified resource types
        $nonCompliantResources = $nonCompliantResources | Where-Object { $_.ResourceType -notin $filterResourceTypes }

        # Modify the ResourceId and add ResourceName property
        $modifiedResources = $nonCompliantResources | ForEach-Object {
            $modifiedResourceId = $_.ResourceId.ToLower()  # Convert ResourceId to lowercase
            $resourceName = Get-ResourceNameFromId $modifiedResourceId  # Extract ResourceName from ResourceId

            # Retrieve the Policy Definition associated with the resource
            $policyDefinition = Get-AzPolicyDefinition -Id $_.PolicyDefinitionId

            # Create a custom object with the modified properties
            [PSCustomObject]@{
                SubscriptionId       = $_.SubscriptionId
                PolicyAssignmentName = $_.PolicyAssignmentName
                PolicyDefinitionName = $policyDefinition.Properties.DisplayName
                ResourceGroup        = $_.ResourceGroup
                ResourceType         = $_.ResourceType
                ResourceId           = $modifiedResourceId
                ResourceName         = $resourceName
            }
        }

        # Count non-compliant resources for the management group
        $nonCompliantCount = $modifiedResources.Count
        $totalManagementGroupResources += $nonCompliantCount
        $totalManagementGroupNonCompliantResources += $nonCompliantCount

        # Check if non-compliant resources were found and provide feedback
        if ($nonCompliantCount -gt 0) {
            Write-Host "Found $nonCompliantCount non-compliant resource(s) in management group $($managementGroup.Name)." -ForegroundColor Yellow
        }

        # Update the hashtable with duplicate resources
        $modifiedResources | ForEach-Object {
            $resourceId = $_.ResourceId
            if ($duplicateManagementGroupResourcesTable.ContainsKey($resourceId)) {
                $duplicateManagementGroupResourcesTable[$resourceId]++
            }
            else {
                $duplicateManagementGroupResourcesTable[$resourceId] = 1
            }
        }

        # Append non-compliant resources to the CSV file
        $existingData = @()
        if (Test-Path -Path $outputFile) {
            $existingData = Import-Csv -Path $outputFile
        }
        $modifiedResources | Where-Object { $existingData.ResourceId -notcontains $_.ResourceId } |
        Export-Csv -Path $outputFile -NoTypeInformation -Append -Force
    }

    # Get all subscriptions
    $subscriptions = if ($SubscriptionId -eq 'all') { Get-AzSubscription } else { Get-AzSubscription | Where-Object { $_.Id -eq $SubscriptionId } }

    # Initialize the progress bar for subscriptions
    $totalSubscriptions = $subscriptions.Count
    $currentSubscription = 0

    # Stats for subscriptions
    $totalSubscriptionResources = 0
    $totalSubscriptionNonCompliantResources = 0
    $duplicateSubscriptionResources = 0

    # Hashtable to track duplicate resources at the subscription level
    $duplicateSubscriptionResourcesTable = @{}

    # Loop over all subscriptions
    foreach ($subscription in $subscriptions) {
        Write-Host "Checking subscription $($subscription.Name)..." -ForegroundColor Cyan

        # Update the progress bar for subscriptions
        Write-Progress -Activity 'Checking Subscriptions' -Status "$currentSubscription out of $totalSubscriptions done" -PercentComplete (($currentSubscription / $totalSubscriptions) * 100)
        $currentSubscription++

        # Select the subscription to use for subsequent commands
        Set-AzContext -Subscription $subscription.Id

        Start-Sleep -Seconds 2

        # Get all non-compliant resources for the subscription and policy assignment
        $nonCompliantResources = Get-AzPolicyState -SubscriptionId $subscription.Id -Filter "ComplianceState eq 'NonCompliant'"
        if ($PolicyAssignmentName -ne 'all') {
            $nonCompliantResources = $nonCompliantResources | Where-Object { $_.PolicyAssignmentName -eq $PolicyAssignmentName }
        }

        # Filter out the specified resource types
        $nonCompliantResources = $nonCompliantResources | Where-Object { $_.ResourceType -notin $filterResourceTypes }

        # Modify the ResourceId and add ResourceName property
        $modifiedResources = $nonCompliantResources | ForEach-Object {
            $modifiedResourceId = $_.ResourceId.ToLower()  # Convert ResourceId to lowercase
            $resourceName = Get-ResourceNameFromId $modifiedResourceId  # Extract ResourceName from ResourceId

            # Retrieve the Policy Definition associated with the resource
            $policyDefinition = Get-AzPolicyDefinition -Id $_.PolicyDefinitionId

            # Create a custom object with the modified properties
            [PSCustomObject]@{
                SubscriptionId       = $_.SubscriptionId
                PolicyAssignmentName = $_.PolicyAssignmentName
                PolicyDefinitionName = $policyDefinition.Properties.DisplayName
                ResourceGroup        = $_.ResourceGroup
                ResourceType         = $_.ResourceType
                ResourceId           = $modifiedResourceId
                ResourceName         = $resourceName
            }
        }

        # Count non-compliant resources for the subscription
        $nonCompliantCount = $modifiedResources.Count
        $totalSubscriptionResources += $nonCompliantCount
        $totalSubscriptionNonCompliantResources += $nonCompliantCount

        # Check if non-compliant resources were found and provide feedback
        if ($nonCompliantCount -gt 0) {
            Write-Host "Found $nonCompliantCount non-compliant resource(s) in subscription $($subscription.Name)." -ForegroundColor Yellow
        }

        # Update the hashtable with duplicate resources
        $modifiedResources | ForEach-Object {
            $resourceId = $_.ResourceId
            if ($duplicateSubscriptionResourcesTable.ContainsKey($resourceId)) {
                $duplicateSubscriptionResourcesTable[$resourceId]++
            }
            else {
                $duplicateSubscriptionResourcesTable[$resourceId] = 1
            }
        }

        # Append non-compliant resources to the CSV file with subscription name and policy definition display name
        $existingData = @()
        if (Test-Path -Path $outputFile) {
            $existingData = Import-Csv -Path $outputFile
        }
        $modifiedResources | Where-Object { $existingData.ResourceId -notcontains $_.ResourceId } |
        Select-Object SubscriptionId, PolicyAssignmentName, PolicyDefinitionName, ResourceGroup, ResourceType, ResourceId, ResourceName |
        Export-Csv -Path $outputFile -NoTypeInformation -Append -Force
    }

    # Completion message
    Write-Host "Noncompliance report generated successfully and saved to $outputFile" -ForegroundColor Green

    # Output stats for management groups and subscriptions combined
    Write-Host "`nNon-Compliant Resource Stats:"
    Write-Host "  Total Management Group Non-Compliant Resources: $totalManagementGroupNonCompliantResources"
    Write-Host "  Total Subscription Non-Compliant Resources: $totalSubscriptionNonCompliantResources"

    # Count duplicate resources at the management group level
    $duplicateManagementGroupResourcesTable.GetEnumerator() | ForEach-Object {
        $duplicateCount = $_.Value
        if ($duplicateCount -gt 1) {
            $duplicateManagementGroupResources += $duplicateCount - 1
        }
    }
    Write-Host "  Duplicate Management Group Resources: $duplicateManagementGroupResources"

    # Count duplicate resources at the subscription level
    $duplicateSubscriptionResourcesTable.GetEnumerator() | ForEach-Object {
        $duplicateCount = $_.Value
        if ($duplicateCount -gt 1) {
            $duplicateSubscriptionResources += $duplicateCount - 1
        }
    }
    Write-Host "  Duplicate Subscription Resources: $duplicateSubscriptionResources"

    # Insert data into SQL database (not working yet)
    if ($BypassPrompts) {
        $sqlConnection = Connect-SqlServer -ServerInstance $SqlServerName -Credential $SqlCredential
        $query = "INSERT INTO $TableName (SubscriptionId, SubscriptionName, PolicyAssignmentName, PolicyDefinitionName, ResourceGroup, ResourceType, ResourceName) SELECT SubscriptionId, PolicyAssignmentName, PolicyDefinitionName, ResourceGroup, ResourceType, ResourceName FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Text;Database=$(Split-Path -Parent $outputFile);HDR=YES;', 'SELECT * FROM $(Split-Path -Leaf $outputFile)')"
        Invoke-Sqlcmd -ServerInstance $sqlConnection -Database $DatabaseName -Query $query
        Disconnect-SqlServer -ServerInstance $sqlConnection
    }
}

# Function to handle user input for reauthentication or tenant switch
function PromptForAuth {
    $reAuthenticate = Read-Host 'Before we begin, do you need to authenticate to Azure? (Y/N)'
    if ($reAuthenticate -eq 'Y') {
        Connect-AzAccount
    }
}

# Main Script Execution
# Ask user if they want to get all noncompliant resources for their tenant
$getAllNoncompliant = Read-Host 'Do you want to get all noncompliant resources for your tenant? (Y/N)'
if ($getAllNoncompliant -eq 'Y') {
    # Authenticate to Azure
    PromptForAuth

    # Create SQL credential
    $SqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SqlUsername, ($SqlPassword | ConvertTo-SecureString -AsPlainText -Force)

    $managementGroupName = 'all'
    $subscriptionId = 'all'
    $policyAssignmentName = 'all'
    RunComplianceReport -ManagementGroupName $managementGroupName -SubscriptionId $subscriptionId -PolicyAssignmentName $policyAssignmentName -SqlCredential $SqlCredential
}
else {
    # Authenticate to Azure
    PromptForAuth

    do {
        # Ask user for input
        Write-Host 'Please select the management group for the noncompliance report:'
        Write-Host '[0] All Management Groups'

        $managementGroups = Get-AzManagementGroup
        for ($i = 0; $i -lt $managementGroups.Count; $i++) {
            Write-Host "[$($i+1)] $($managementGroups[$i].DisplayName)"
        }

        $managementGroupChoice = Read-Host 'Enter your choice'

        if ($managementGroupChoice -eq '0') {
            $managementGroupName = 'all'
            $policyAssignmentName = 'all'
        }
        else {
            $managementGroupIndex = [int]$managementGroupChoice - 1
            $managementGroupName = $managementGroups[$managementGroupIndex].Name
            $policyAssignmentName = 'all'
        }

        # Ask user for input
        Write-Host 'Please select the subscription for the noncompliance report:'
        Write-Host '[0] All Subscriptions'

        $subscriptions = Get-AzSubscription
        for ($i = 0; $i -lt $subscriptions.Count; $i++) {
            Write-Host "[$($i+1)] $($subscriptions[$i].Name) - $($subscriptions[$i].Id)"
        }

        $subscriptionChoice = Read-Host 'Enter your choice'

        if ($subscriptionChoice -eq '0') {
            $subscriptionId = 'all'
        }
        else {
            $subscriptionIndex = [int]$subscriptionChoice - 1
            $subscriptionId = $subscriptions[$subscriptionIndex].Id
        }

        # Create SQL credential (not working yet)
        $SqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SqlUsername, ($SqlPassword | ConvertTo-SecureString -AsPlainText -Force)

        # Run the compliance report
        RunComplianceReport -ManagementGroupName $managementGroupName -SubscriptionId $subscriptionId -PolicyAssignmentName $policyAssignmentName -SqlCredential $SqlCredential

        # Ask user if they want to run the report again
        $runAgain = Read-Host 'Do you want to run the report again? (Y/N)'
        if ($runAgain -eq 'Y') {
            # Authenticate to Azure
            PromptForAuth
        }
    } while ($runAgain -eq 'Y')
}
