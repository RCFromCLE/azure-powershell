# DeleteListofAppSvcSSLCerts
#
#### Author: Rudy Corradetti
### Purpose: Take a CSV of Azure app svc certificates and delete them. Give an option for preview using what if.
#
### How to use:

 1. Clone this repo to your local workstation
 2. Input values into ListofCerts2BeDeleted.csv. Resource group where certs exist, subscription where certs exist, and name of certs are required.
 3. Open a terminal to .\DeleteListofAppSvcSSLCerts.ps1.
 4. Run script .\DeleteListOfDisks.ps1
 5. Choose preview (1) or live (2). Preview will run the script using -whatif and can be used as a test. Live runs the script and deletes all certs in ListofDisks2BeDeleted.csv.
 6. Confirm certificates were deleted in the Azure portal.


