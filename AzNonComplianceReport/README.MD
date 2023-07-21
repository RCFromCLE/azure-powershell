AzNonComplianceReport.ps1
==================================

This PowerShell script generates a report of noncompliant resources for Azure Policy assignments. The report can be generated for all non-compliant resources across all policy assignments in all management groups, subscriptions, for all non-compliant resources within a specific management group, subscription, or for a specific policy assignment within a single subscription. The report is saved to a CSV file with some stats output to the console. Dupliates are removed from the report.

1.  All Non-Compliant Resources across All Policy Assignments for All Subscriptions:

    -   The script retrieves non-compliant resources for all policy assignments across all subscriptions accessible to the user.
    -   The report includes details such as subscription ID, subscription name, policy definition display name, policy assignment name, resource group, resource type, and resource name.
    -   The report is saved to a CSV file named `Az_NonComplianceReport_All-<timestamp>.csv`, where `<timestamp>` represents the current date and time.
2.  All Non-Compliant Resources for a Specific Subscription:

    -   The user selects a specific subscription to check for non-compliant resources.
    -   The script retrieves non-compliant resources for all policy assignments within the selected subscription.
    -   The report includes details such as subscription ID, subscription name, policy definition display name, policy assignment name, resource group, resource type, and resource name.
    -   The report is saved to a CSV file named `Az_NonComplianceReport_<SubscriptionName>-<timestamp>.csv`, where `<SubscriptionName>` is the name of the selected subscription, and `<timestamp>` represents the current date and time.
3.  Non-Compliant Resources for a Specific Policy Assignment within a Single Subscription:

    -   The user selects a specific subscription and a specific policy assignment within that subscription to check for non-compliant resources.
    -   The script retrieves non-compliant resources for the selected policy assignment within the selected subscription.
    -   The report includes details such as subscription ID, subscription name, policy definition display name, policy assignment name, resource group, resource type, and resource name.
    -   The report is saved to a CSV file named `Az_NonComplianceReport_<SubscriptionName>-<PolicyAssignmentName>-<timestamp>.csv`, where `<SubscriptionName>` is the name of the selected subscription, `<PolicyAssignmentName>` is the name of the selected policy assignment, and `<timestamp>` represents the current date and time.

Usage
-----

1.  Run the script in a PowerShell environment.
2.  The script will display a welcome graphic.
3.  If prompted, enter 'Y' to authenticate to Azure or 'N' if you are already authenticated.
4.  Select the desired option:
    -   Enter '0' to generate a report for all non-compliant resources across all policy assignments in all subscriptions.
    -   Choose a number corresponding to a specific subscription to generate a report for all non-compliant resources within that subscription.
    -   Choose a specific subscription number and then select a policy assignment number to generate a report for a specific policy assignment within a subscription.
5.  The script generates the non-compliance report and saves it to a CSV file.
6.  The report is displayed on the console, showing details such as subscription ID, subscription name, policy definition display name, policy assignment name, resource group, resource type, and resource name.
7.  The script provides a summary of checked subscriptions or the selected subscription, depending on the chosen option.
8.  If desired, choose 'Y' to run the report again with a different option or 'N' to exit the script.

![AzNonComplianceReport Running](https://imgur.com/VXq3RVf)

Output
------

The script generates a non-compliance report based on the chosen option:

1.  All Non-Compliant Resources across All Policy Assignments for All Subscriptions:

    -   The report is saved to a CSV file named `Az_NonComplianceReport_All-<timestamp>.csv` in the current directory.
    
    -   The CSV file includes the following columns:
        -   SubscriptionId
        -   PolicyDefinitionName
        -   PolicyAssignmentName
        -   ResourceGroup
        -   ResourceType
        -   ResourceName
2.  All Non-Compliant Resources for a Specific Subscription:
    -   The report is saved to a CSV file named `Az_NonComplianceReport_<SubscriptionName>-<timestamp>.csv` in the current directory.
    -   The CSV file includes the same columns as above.
3.  Non-Compliant Resources for a Specific Policy Assignment within a Single Subscription:

    -   The report is saved to a CSV file named `Az_NonComplianceReport_<SubscriptionName>-<PolicyAssignmentName>-<timestamp>.csv` in the current directory.
    -   The CSV file includes the same columns as above.

The report is also displayed on the console, providing a summary of checked subscriptions or the selected subscription, depending on the chosen option.

Notes: Ensure that you have the Azure PowerShell module installed and have the necessary permissions to access the Azure subscriptions and resources you want evaluated. The timestamp in the file name represents the date and time when the report was generated.