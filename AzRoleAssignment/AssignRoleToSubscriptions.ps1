#Author: Rudy Corradetti

#The script assigns a single role to all subscriptions under a management group. The script prompts for the following input: MG Name, Role Definition Name, Principal ID.

# Function to handle user input for reauthentication or tenant switch
function PromptForAuth {
    $reAuthenticate = Read-Host 'Before we begin, do you need to authenticate to Azure? (Y/N)'
    if ($reAuthenticate -eq 'Y') {
        Connect-AzAccount
    }
}

# Authenticate to Azure
PromptForAuth

# Prompt user for input variables with additional hints
$managementGroupName = Read-Host -Prompt "Enter the parent Management Group Name (e.g. 'Development'). This is the Management Group under which all subscriptions are present and to which you want to assign the role."
$roleDefinitionName = Read-Host -Prompt "Enter the Role Definition Name (e.g. 'Contributor' for Contributor role)"
$principalId = Read-Host -Prompt "Enter the Principal ID (User or Service Principal ID to which you want to assign the role)"

# Define colors for logging
$colorSuccess = "Green"
$colorError = "Red"

# Counter for successful role assignments
$successfulAssignments = 0

# Fetch all subscriptions under the management group
$subscriptions = Get-AzManagementGroupSubscription -GroupName $managementGroupName

# Check if subscriptions are found
if ($subscriptions.Count -eq 0) {
    Write-Host "No subscriptions found under the management group: $managementGroupName" -ForegroundColor $colorError
    exit
}

# Assign roles to each subscription
foreach ($sub in $subscriptions) {
    try {
        # Extracting subscription ID from the Id property
        $subId = $sub.Id -split "/" | Select-Object -Last 1
        
        New-AzRoleAssignment -Scope "/subscriptions/$subId" -RoleDefinitionName $roleDefinitionName -ObjectId $principalId
        $successfulAssignments++
        Write-Host "Assigned role to subscription: $($sub.DisplayName)" -ForegroundColor $colorSuccess
    } catch {
        Write-Host "Failed to assign role to subscription: $($sub.DisplayName). Error: $($_.Exception.Message)" -ForegroundColor $colorError
    }
}

# Display stats
Write-Host "Role assignments completed! Total successful sub role assignments: $successfulAssignments" -ForegroundColor $colorSuccess
