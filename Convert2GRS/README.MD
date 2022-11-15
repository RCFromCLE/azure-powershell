# Convert2GRS
#
#### Author: Rudy Corradetti
### Purpose: Take a CSV of Storage Accounts and set them to GRS sku from RA-GRS. Give an option for preview using what if.
#
### How to use:

 1. Clone this repo to your local workstation
 2. Input values into Convert2GRS.csv. Resource group where storage account exists and storage account name are required.
 3. Open a terminal to Convert2GRS directory
 4. Update variable sub_id to contain the subscription where your storage accounts exist
 5. Run script ./Convert2GRS.ps1
 6. Choose preview (1) or live (2). Preview will run the script using -whatif and can be used as a test. Live runs the script and changes all storage account skus in Convert2GRS.csv to GRS.
 7. Confirm storage account changes went as expected by verifying through the Azure portal.


