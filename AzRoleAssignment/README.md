# AssignRoleToSubscriptions.ps1

## Description
The `AssignRoleToSubscriptions.ps1` script is designed to assign a single role to all Azure subscriptions under a specified management group. The script will prompt the user for input concerning the Management Group Name, the Role Definition Name, and the Principal ID (either a User or Service Principal ID).

## Author
[Rudy Corradetti](https://github.com/RCFromCLE)

## Prerequisites
- Azure PowerShell module must be installed.
- User must have permissions to assign roles and list subscriptions.

## Usage
1. Clone the repository or download the script.
2. Open PowerShell in the directory containing the script.
3. Run the script by typing `./AssignRoleToSubscriptions.ps1`.
4. When prompted, authenticate to Azure if required.
5. Provide the necessary input when prompted:
    - Management Group Name (e.g., 'Development').
    - Role Definition Name (e.g., 'Contributor').
    - Principal ID (This can be a User ID or a Service Principal ID).
6. The script will then iterate over the subscriptions under the provided management group and assign the specified role to each subscription.
7. Upon completion, the script will display the number of successful role assignments.

## Notes
- Ensure you have the necessary permissions in Azure to assign roles and list subscriptions.
- Always test scripts in a non-production environment before applying them to critical resources.
