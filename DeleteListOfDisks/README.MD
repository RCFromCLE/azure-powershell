# DeleteListofDisks
#
#### Author: Rudy Corradetti
### Purpose: Take a CSV of Azure disks and delete them. Give an option for preview using what if.
#
### How to use:

 1. Clone this repo to your local workstation
 2. Input values into ListofDisks2BeDeleted.csv. Resource group where disk exists, subscription where disk exists, name of disk are required.
 3. Open a terminal to ListofDisks2BeDeleted.csv. directory
 4. Run script .\DeleteListOfDisks.ps1
 5. Choose preview (1) or live (2). Preview will run the script using -whatif and can be used as a test. Live runs the script and deletes all disks in ListofDisks2BeDeleted.csv.
 6. Confirm disks were deleted in the Azure portal.


