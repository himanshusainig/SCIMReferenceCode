# Overview

Welcome to the pilot for **self-service validation of your provisioning
integration with Azure Logic apps**!

The Entra App Provisioning and Single Sign-On teams are currently
working on building a revamped onboarding experience where ISVs can
self-service onboard their provisioning or SSO integrations to the
Microsoft Entra app gallery. This will enable you to bring your
application into the Microsoft ecosystem faster and more efficiently
than ever before.

The self-service onboarding experience will consist of multiple
components:

1.  A process to self-service validate that your provisioning
    integration is ready to onboard to the Microsoft Entra app gallery
    via a provided Azure Logic app template

2.  A process to self-service validate that your SSO integration is
    ready to onboard to the Microsoft Entra app gallery via a browser
    extension

3.  An intake form in the Entra portal where you can submit a publishing
    request for your SSO and/or provisioning application

This document walks you through **\#1**, the process of self-service
validating that your provisioning integration is ready to onboard to the
Microsoft Entra app gallery. We are seeking your feedback on the
validation experience, including what you enjoy and what we can improve.

## Disclaimer

This feature is currently in PREVIEW. This information relates to a
pre-release product that may be substantially modified before it's
released. Microsoft makes no warranties, expressed or implied, with
respect to the information provided here.

## Support for preview

Microsoft Premier support will not provide support during the pilot. If
you have questions or feedback to provide, you may reach out to the
feature team managing this pilot at <aaduserprovisioning@microsoft.com>.

# Onboarding requirements

*<u>Technical requirements</u>*

For your application to be eligible to onboard to the Microsoft Entra
app gallery, your provisioning integration must meet the following
requirements:

- Support a SCIM 2.0 user or group endpoint (only one is required, but
  supporting both a user and group endpoint is recommended)

- Support the OAuth 2.0 Client Credentials grant as your primary
  authentication method

  - Note: Client Credentials is not required to participate in this
    pilot (i.e. you need to use ***long lived* bearer token** to test
    the Logic app). However, Client Credentials will be required to
    onboard to the Microsoft Entra app gallery

  - Currently, Client Credentials is the only authentication method we
    support for requests to onboard new provisioning integrations to the
    Microsoft Entra app gallery

- Support updating multiple group memberships with a single PATCH
  request

- Support at least 25 requests per second per tenant to ensure that
  users and groups can be provisioned and deprovisioned without delay

- Your SCIM endpoint does not require features that Microsoft does not
  support today. Examples of features that the non-gallery SCIM app does
  not currently support:

  - Verbose PATCH calls

  - Support for batching calls (i.e. including multiple add operations
    in the same PATCH call)

  - Rate limiting

*<u>Validation requirements</u>*

This document provides you with instructions on how to self-service
validate your application, so that it is ready to onboard to the
Microsoft Entra app gallery. Once you complete the instructions in this
document, you will have completed the following pre-requisites:

- You should have set up a non-gallery SCIM app with a successful sync.
  This step requires:

  - A SCIM endpoint. If you need guidance on how to develop a SCIM
    endpoint, you can refer to our public documentation:
    <https://learn.microsoft.com/entra/identity/app-provisioning/use-scim-to-provision-users-and-groups>

  - An Entra ID tenant. If you don’t already have one, you can follow
    the instructions here to create one:
    <https://learn.microsoft.com/entra/identity-platform/quickstart-create-new-tenant>

  - You must have at least an **Application Administrator** role in the
    Entra ID tenant.

  - If your app will support only group provisioning, an [Entra ID
    Premium P1
    license](https://learn.microsoft.com/entra/fundamentals/licensing)
    is required for group-only provisioning to function (a P1 license is
    not required if “Provision all” is selected). A trial license will
    work. *Note: If you have an [M365 E3 or E5
    license](https://www.microsoft.com/microsoft-365/enterprise/microsoft-365-plans-and-pricing),
    Entra Premium is included as part of those license packages.*

- You should complete a successful run of our Logic app validation
  template, with no errors returned. This step requires:

  - In the same tenant where your non-gallery SCIM app is hosted, an
    Azure subscription for Logic app testing. The Logic app template
    functions on a [consumption
    model](https://learn.microsoft.com/azure/logic-apps/single-tenant-overview-compare),
    meaning that you will likely incur a small monetary cost as a result
    of running the Logic app. This cost is expected to be small (less
    than 10 USD per month on an [Azure pay-as-you-go
    subscription](https://azure.microsoft.com/pricing/purchase-options/azure-account/search?icid=hybrid-cloud&ef_id=_k_CjwKCAiA8vXIBhAtEiwAf3B-gwGo45BSp9MkHu1_SsZHPGytGsYgUoGgKhwiVKvh4pCybuz62bqCnhoCYlgQAvD_BwE_k_&OCID=AIDcmm5edswduu_SEM__k_CjwKCAiA8vXIBhAtEiwAf3B-gwGo45BSp9MkHu1_SsZHPGytGsYgUoGgKhwiVKvh4pCybuz62bqCnhoCYlgQAvD_BwE_k_&gad_source=1&gad_campaignid=21496728177&gbraid=0AAAAADcJh_siQ5FaD4VnPUpZunMKSJ2sy&gclid=CjwKCAiA8vXIBhAtEiwAf3B-gwGo45BSp9MkHu1_SsZHPGytGsYgUoGgKhwiVKvh4pCybuz62bqCnhoCYlgQAvD_BwE)).

  - You must have permissions to create a Logic app under the
    appropriate subscription and resource group. This will require at
    least a [Logic app
    contributor](https://learn.microsoft.com/azure/logic-apps/logic-apps-securing-a-logic-app?tabs=azure-portal)
    role, but more permissions may be required depending on whether you
    also need to create a subscription and resource group.

*<u>Publishing requirements</u>*

While not required to participate in this pilot, the following is
required to complete the self-service publishing experience once it
becomes available for Private Preview in CY2026:

- Your tenant must be registered as a partner in Microsoft Partner
  Center and enrolled in the Microsoft AI Cloud Partner program.

- You must have documentation for your SCIM endpoint ready to publish.
  Once Private Preview starts, a documentation template will be
  available for you to use.

  - End customers should be able to access documentation about your SCIM
    endpoint on both your website and the Microsoft Learn website.

- Please provide us with engineering and support contacts for us to
  refer end customers to once your application is published to the
  Microsoft Entra app gallery.

<span id="_Set_up_your" class="anchor"></span>

# Pre-run: Setup

## Set up your non-gallery SCIM app

As mentioned in the [Requirements section](#_Requirements), before you
validate your provisioning integration, you must set up a non-gallery
SCIM app with your desired configuration and start a successful sync
with that app. This section describes how to do so.

### Requirements

In the [Onboarding requirements section](#onboarding-requirements),
review the *Validation requirements* list to ensure that you have
everything you need to set up a non-gallery SCIM app.

### Instructions

1.  Sign in to the Entra portal at
    [entra.microsoft.com](https://entra.microsoft.com).

2.  Select **Enterprise applications \> New application \> Create your
    own application**.

<img src="./media/image1.png"
style="width:6.5in;height:1.85347in" />

<img src="./media/image2.png"
style="width:6.07743in;height:2.62448in" />

3.  Enter the name of your app, integration options, and click
    **Create**.

<img src="./media/image3.png"
style="width:4.76548in;height:6.32658in" />

4.  Take note of the **Object ID** (this will be referred to as
    servicePrincipalID in the logic App).

<img src="./media/image4.png"
style="width:6.5in;height:5.90903in" />

5.  Set **Provisioning Mode** to **Automatic**, enter your bearer token
    details, and select **Test Connection**.

<img src="./media/image5.png"
style="width:6.5in;height:3.82431in" />

<img src="./media/image6.png"
style="width:6.5in;height:2.1875in" />

6.  Create a provisioning job by creating connection and set up schema
    by navigating to **Provisioning \> Mappings \> Provision Users**.
    For more details on how to customize schema, you can check out our
    public documentation here: [Tutorial - Customize Microsoft Entra
    attribute mappings in Application Provisioning - Microsoft Entra ID
    \| Microsoft
    Learn](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/customize-application-attributes).

<img src="./media/image7.png"
style="width:6.5in;height:3.48889in" />

**Prune the schema** with only attributes/mappings required and
supported by the ISV. Select the checkbox **Show Advanced Options.**
Then the **Edit attribute list** link will be displayed. Select the link
and verify the attributes. Update/delete the attributes depending on the
schema supported by the ISV endpoint.

<img src="./media/image8.png"
style="width:6.5in;height:2.31319in" />

<img src="./media/image9.png"
style="width:6.5in;height:2.77778in" />

7.  In the **Overview** page, select **Start Provisioning** to start a
    provisioning job. If the provisioning job commences without errors,
    you are ready to move on to the next section.

<img src="./media/image10.png"
style="width:6.5in;height:3.36875in" />

8.  **Optional:** Once you’ve successfully started a provisioning job,
    submit an allow list request for faster sync cycles via this form:
    [Allow List for Self-Service Validation of Provisioning Integration
    (Pilot) – Fill out
    form](https://forms.microsoft.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR1xPIYfdXw5FhHBIH8BxY9ZUQ0w0UEczQTdLT1gzUTIyVzVNOUFHTjNGQS4u).
    The Entra App Provisioning team will then work on allow listing your
    tenant and provisioning job. Once complete, you will have access to
    sync cycles that run more frequently than the standard 40-minute
    sync cycle, allowing you to test and iterate upon your provisioning
    integration quickly.

## Set up a Logic app for running automated tests

Once you have set up a non-gallery SCIM app and started the sync, you
will use our provided Logic app template to validate your provisioning
integration and ensure that it is ready to publish to the Microsoft
Entra app gallery. Logic app runs user tests and group tests on ISVs
behalf by using the non-gallery SCIM app that you set up. 

Once we release the full private preview for the full onboarding and
publishing experience, a successful run of the Logic app template will
allow you to submit a publishing request for your provisioning
integration, after which we will review and deploy your app.

### Requirements

In the [Onboarding requirements section](#onboarding-requirements),
review the *Validation requirements* list to ensure that you have
everything you need to set up a Logic app.

### Instructions

1.  Sign in to the Azure portal at <https://portal.azure.com>. You
    should use the same tenant as the one where you set up your
    non-gallery SCIM app.

2.  Use the searchbar to navigate to the **Subscriptions** blade.

<img src="./media/image11.png" style="width:6.5in;height:1in" />

3.  Select the appropriate Azure subscription and create a resource
    group. This is the subscription and resource group that your Logic
    app will be attached to.

<img src="./media/image12.png"
style="width:6.5in;height:2.10903in" />

<img src="./media/image13.png"
style="width:6.5in;height:3.20833in" />

4.  Use the searchbar to navigate to the **Logic app**s blade.

5.  Select **Add \> Multi-tenant (consumption)**. *Note: The Logic app
    functioning on a consumption model means that you may be billed on
    your Azure description depending on level of usage. The amount is
    expected to be small—see the [Onboarding requirements
    section](#onboarding-requirements) for more details, under*
    Validation requirements*.*

<img src="./media/image14.png"
style="width:6.5in;height:1.76944in" />

<img src="./media/image15.png"
style="width:6.5in;height:2.6625in" />

6.  Configure the settings of your Logic app as desired. Once you are
    done, click **Review + create**.

<img src="./media/image16.png"
style="width:6.5in;height:5.29444in" />

7.  Once the Logic app finishes deploying, open the Logic app.

<img src="./media/image17.png"
style="width:6.5in;height:2.97708in" />

8.  Download the **logicAppTemplate.json **file from
    the** Microsoft.SCIM.LogicAppValidationTemplate** folder of our GitHub repository: <u>https://github.com/AzureAD/SCIMReferenceCode/tree/master/Microsoft.SCIM.LogicAppValidationTemplate</u> (copy/paste
    this URL into your browser). *Note: The folder includes
    a **README.md** file that lists out the various tests that the Logic
    app will run. This may be helpful for your reference.*

9.  In the Logic app, select **Development Tools \> Logic app code
    view**. Copy/paste the code from the template in the previous step
    and click **Save**. The **Logic app designer** view should then
    update with the various test cases that our template will
    automatically run for you.

<img src="./media/image18.png"
style="width:6.50278in;height:3.18082in" />

<img src="./media/image19.png"
style="width:6.5in;height:3.70833in" />

10. Next, we will enable system-assigned managed identity for secure
    resource access. Select **Settings \> Identity**.

<img src="./media/image20.png"
style="width:6.5in;height:4.16806in" />

11. Set the **Status** in the **System assigned** tab to **On**. Select
    **Yes** in the confirmation dialog that pops up.

<img src="./media/image21.png"
style="width:6.5in;height:2.86181in" />

12. Select **Save**.

<img src="./media/image22.png"
style="width:6.5in;height:3.02431in" />

13. Take note of the object ID of the managed identity. You will need
    this object ID for the script that you will run in a few steps.

<img src="./media/image23.png"
style="width:6.5in;height:3.59792in" />

14. Now let’s work on granting the owner role to the Logic app. Select
    **Azure role assignments**.

15. In the **Azure role assignments** page, click on **Add role
    assignment** and select the **Owner** role.

<img src="./media/image24.png"
style="width:6.5in;height:2.28889in" />

<img src="./media/image25.png"
style="width:5.16964in;height:5.3232in" />

<img src="./media/image26.png"
style="width:6.5in;height:1.27083in" />

Once the owner role has been granted to the Logic app, you can now work
on assigning the proper permissions to the Logic app so that it can
invoke various Graph queries as part of the automated tests it will run
(the Logic app will create, update, and delete users and groups, query
provisioning logs, etc.).

You may choose to use Azure CLI or PowerShell for the following steps.

16. Go to the sample script provided in the
    [appendix](#script-for-assigning-permissions-to-your-logic-app) of
    this document. Copy the script for your records, and update the
    value of the **\$logicAppManagedId** field with the object ID of
    your Logic app’s managed identity.

17. Run the script using the command-line interface of your choice. If
    using a UI like Azure Cloud Shell that provides you with an option
    to upload a file, you may opt to copy the script into a file, upload
    the file, then run the script.

*<u>How to upload and run a script using Azure Cloud Shell</u>*

<img src="./media/image27.png"
style="width:6.5in;height:1.84653in" />

<img src="./media/image28.png"
style="width:6.5in;height:2.33681in" />

<img src="./media/image29.png"
style="width:6.5in;height:4.56528in" />

<img src="./media/image30.png"
style="width:6.5in;height:2.05764in" />
<img src="./media/image31.png"
style="width:6.5in;height:2.66181in" />

Once the script successfully runs, you will have assigned all the
necessary roles to the managed identity of your Logic app.

### Logic App Explanation:

Logic App is divided into separate sections.

The first section initializes the required steps to run the tests in
Logic App.

<img src="./media/image32.png"
style="width:2.89624in;height:5.76122in" />

The next section contains the tests. Tests are bundled into user and
group sections. All the User Tests are in ‘UserTests Scope’ and Group
tests in ‘GroupTests Scope’.

<img src="./media/image33.png"
style="width:6.5in;height:2.46667in" />

<img src="./media/image34.png"
style="width:6.5in;height:2.45486in" />

<img src="./media/image35.png"
style="width:6.5in;height:2.00694in" />

Each test can be further drilldown by selecting the down arrow and to
get into details of stages and the actions. Each stage and action can be
drilled down till the inputs and outputs are displayed for each action.

<img src="./media/image36.png"
style="width:5.57369in;height:6.90721in" />

<img src="./media/image37.png"
style="width:6.5in;height:3.89583in" />

The last section is for post run results evaluation.

<img src="./media/image38.png"
style="width:3.95889in;height:2.5837in" />

# Run: Steps to Run Logic app

Before we run your Logic app, let’s provide values for your Logic app’s
required run parameters. Save the Logic app after updating parameters
before Run.

## Providing Values To Parameters:

18. The **servicePrincipalId** is the **objectId** of the non-gallery
    SCIM app you created in the [previous section](#_Set_up_your).

<img src="./media/image39.png"
style="width:6.26129in;height:4.12558in" />

19. Enter your SCIM endpoint.

    1.  **Note**: don’t include feature flags like aadOptscim062020 in
        the scim endpoint here. Even if you have to configure your non
        gallery app with feature flags.

<img src="./media/image40.png"
style="width:6.5in;height:2.79167in" />

20. Enter your SCIM bearer token.

<img src="./media/image41.png"
style="width:5.78206in;height:4.11516in" />

21. Under **templateId**, enter **scim** as the **Default value**.

<img src="./media/image42.png"
style="width:5.71955in;height:3.45882in" />

22. Under **testUserDomain**, enter a verified domain that belongs to
    your tenant. This domain will be used to create test users in Entra
    ID and provision them to your SCIM endpoint as part of the automated
    tests that the Logic app template will run. *Note: A Logic app
    template that successfully completes all tests will clean up any
    test users that were created during that run. If the Logic app
    template does not complete a full, clean run, test users may not be
    cleaned up. For example, stubs of the test user accounts will remain
    in your tenant if the Logic app template fails the Delete User tests
    or if you choose to interrupt the Logic app template before it has
    the chance to complete delete operations.*

<img src="./media/image43.png"
style="width:6.18784in;height:2.73981in" />

23. Under defaultUserProperties give the different sets of user
    Properties values to test. The Logic App takes one choose one set of
    the defaultUserProperties to create User and another set for
    updating User. Selection is random based on no. of sets.

<img src="./media/image44.png"
style="width:6.19878in;height:4.03181in" />

<img src="./media/image45.png"
style="width:4.6875in;height:6.5in" />

**  **

24. **EnabledTests** can take one of the below values. We support
    running all tests in parallel, running individual tests, or running
    tests related to only users or only groups. ***Only one value should
    be provided.***

**“All” -** All tests will run

**“UserTests” -** All of the User Tests will run and Groups Tests are
skipped.

**“GroupTests” –** All of the Group Tests will run and User Tests are
skipped.

> "All",

                    "UserTests",

                    "GroupTests",

                    "Create_User_Test",

                    "Update_User_Test",

                    "Delete_User_Test",

                    "User_Disable_Test",

                    "User_Update_Manager_Test",

                    "Create_Group_Test",

                    "Update_Group_Test",

                    "Delete_Group_Test",

                    "Group_Update_Add_Member_Test",

                    "Group_Update_Remove_Member_Test"

<img src="./media/image46.png"
style="width:5.99994in;height:4.23525in" />

25. IsSoftDeleted can be ‘true’ or ‘false’. Set to true only if soft
    deletion is supported and defined in your SCIM schema. This property
    indicates that the user resource is marked for soft deletion—meaning
    it is flagged for removal but not permanently deleted.
    “Disable_User_Tests’ and “Delete_User_Tests” are dependent on the
    correct value of this parameter.

<img src="./media/image47.png"
style="width:5.98in;height:3.14627in" />

26. IsManagerAttributeSupported is set to ‘true’ or ‘false’. If the
    manager attribute is present in the ISV schema, then this should be
    set to true. Else ‘false’. If this variable is ‘false’ then
    “User_Update_Manager_Test’ will be skipped. Setting the value and
    skipping the tests will help in the tests to run successfully.

> <img src="./media/image48.png"
> style="width:5.94875in;height:3.47965in" />

27. IsGroupSupported is set ‘true’ or ‘false’. Only if Group Sync is
    supported set this parameter value to ‘true’. The Group Tests will
    run only if this parameter is set to ‘true’ else they are skipped.

<img src="./media/image49.png"
style="width:5.93833in;height:3.19836in" />

## Run the Logic App:

28. You’re now ready to run the Logic app! Navigate to **Development
    Tools \> Logic app designer**, then select **Run**.

<img src="./media/image50.png"
style="width:6.5in;height:3.30764in" />

# Post-Run: Verify the Runs and the Results

## Verify the Runs

29. You can view logs of your runs in the **Runs history** blade. When
    clicking on an entry in **Runs history**, you check the final
    results of that entry, including the list of tests that were run,
    alongside status and any errors that may have come up.

<img src="./media/image51.png"
style="width:6.5in;height:1.42639in" />

## Debugging

30. Debugging Logic App:

Check the Final_TestResults action to learn about the tests and their
results.

<img src="./media/image52.png"
style="width:6.5in;height:2.60764in" />

In Final_TestResults -\> Select 'Show raw Outputs’.

<img src="./media/image53.png"
style="width:5.61111in;height:5.53819in" />

<img src="./media/image54.png"
style="width:5.61806in;height:0.94236in" />

For each test, “testResult” shows the success / failure / skipped. In
case of failure the phase and action name for the failure is displayed.
Search the action name and can debug and look furthermore for error
details. Identify the failures from failed actions inputs/outputs give
further details about why that call is failed. Verify if the schema is
valid and all the parameters are set according to the Schema. Fix the
parameters or schema and run the logic app again.

“provisioningErrorDetails” gives the glimpse of Error information in
case of failure.

*Tip:* More details about the run can be found by drilling down to the
test definition and checking the input/output. Here’s a sample of how
the output may look like:

<img src="./media/image55.png"
style="width:6.5in;height:1.76458in" />

*Another tip:* In the **Logic app designer** view, you can query for a
specific stage / action on the magnifying glass icon.

<img src="./media/image56.png"
style="width:6.5in;height:3.65625in" />

## Test Results

31. Once you see the tests have passed and you are ready to move to
    onboarding. Provide the test results to us to validate and onboard.

Run the Powershell validation script and provide us with the generated
JSON file.

> **Prerequisites**

- **PowerShell Version 7.0+**: Install
  from [https://aka.ms/powershell](vscode-file://vscode-app/c:/Users/v-mchittoory/AppData/Local/Programs/Microsoft%20VS%20Code/resources/app/out/vs/code/electron-browser/workbench/workbench.html) or
  PowerShell 5.1 with \`-SkipActionDetails\` flag

- **Azure Role** - Reader or Logic App Operator on the Logic App
  resource

- **Azure CLI** - Install from <https://aka.ms/installazurecli>

> **31.1 Login to Azure**
>
> Open PowerShell and run:
>
> az login
>
> \# Set the subscription you want to use
>
> az account set --subscription "YOUR_SUBSCRIPTION_ID"
>
> **Note:** The script uses Azure CLI internally to obtain access tokens
> for Azure Resource Management (ARM) API calls.
>
> **31.2 Run the Validation Script**
>
> Download the Validation script provided in the appendix.
>
> Navigate to the script directory and run:
>
> .\ValidateLogicAppRun.ps1 \`
>
>     -SubscriptionId "YOUR_SUBSCRIPTION_ID" \`
>
>     -ResourceGroup "YOUR_RESOURCE_GROUP" \`
>
>     -LogicAppName "YOUR_LOGIC_APP_NAME" \`
>
>     -RunId "YOUR_RUN_ID"
>
> **Where to find these values:**
>
> Subscription ID: Azure Portal → Subscriptions → Your Subscription →
> Copy the ID
>
> Resource Group / Logic App Name: Azure Portal → Your Logic App →
> Overview
>
> Run ID: Azure Portal → Your Logic App → Run History → Copy the Run ID
>
> **Optional Parameters:**
>
> -SkipActionDetails: Skip fetching action inputs/outputs (faster
> execution, works with PowerShell 5.1)
>
> **Note:** If copy-pasting the command, verify that hyphens (-) before
> parameters are correct, as some applications replace them with
> different dash characters.
>
> **Example**
>
> .\ValidateLogicAppRun.ps1 \`
>
>     -SubscriptionId "12345678-1234-1234-1234-123456789012" \`
>
>     -ResourceGroup "rg-provisioning-prod" \`
>
>     -LogicAppName "la-scim-validator" \`
>
>     -RunId "08584361051946613703020273411CU28"
>
> **31.3 Submit Results**
>
> Send us the generated JSON file:
> <span class="mark">validation-result-{RunId}.json</span>
>
> The script displays **VALIDATION PASSED** (green) or **VALIDATION
> FAILED** (red) in the console upon completion.
>
> **What Gets Validated**

- Run completed successfully

- No failed actions

- All required provisioning stages executed (dynamically extracted from
  template)

- All template actions executed (no modifications)

> **Finding Required Parameters**
>
> **Subscription ID**

1.  Go to **Azure Portal** → **Subscriptions**

2.  Find your subscription and copy the **Subscription ID**

> Alternatively, via command:
>
> az account show --query id --output tsv
>
> **Resource Group and Logic App Name:**  
> Go to Azure Portal → Navigate to your Logic App → View the resource
> group and Logic App name in the overview.
>
> **Run ID:**

1.  Go to **Azure Portal** → Your **Logic App** → **Run history**

2.  Click on the run you want to validate

3.  Copy the **Run ID** (format: 08584XXXXX...CUXX)

> **Troubleshooting the Validation Script**

<table style="width:92%;">
<colgroup>
<col style="width: 45%" />
<col style="width: 46%" />
</colgroup>
<thead>
<tr>
<th>Issue</th>
<th>Solution</th>
</tr>
</thead>
<tbody>
<tr>
<td>"Authentication failed"</td>
<td>Run az login and sign in again</td>
</tr>
<tr>
<td>"Cannot access Logic App"</td>
<td><p>Verify subscription ID, resource group, and Logic App name.</p>
<p>Check you have proper Azure permissions.</p></td>
</tr>
<tr>
<td>"No subscriptions found"</td>
<td>Wait 5-10 minutes after role assignment, then run az account
clear and az login</td>
</tr>
<tr>
<td>Script execution policy error</td>
<td>Run: <mark>Set-ExecutionPolicy RemoteSigned -Scope
CurrentUser</mark></td>
</tr>
<tr>
<td>"This script requires PowerShell 7.0 or later for parallel
processing."</td>
<td>Install PowerShell 7+ or run
with <mark>-SkipActionDetails</mark> flag</td>
</tr>
</tbody>
</table>

> **Understanding Results**

- **VALIDATION PASSED** - Run succeeded with valid template

- **VALIDATION FAILED** - Check the JSON report for:

<!-- -->

- **validationErrors** - High-level issues

- **failedActions** - Specific errors with details

- **templateValidation.requiredStages** - Stage execution status

- **actionComparison** - Missing or modified actions detected

When we release the full self-service onboarding experience for
provisioning integrations, you will provide us with a **Run ID**
associated with a successful run of your Logic app (alongside details
such as the subscription and resource group that your Logic app is
associated with). Run IDs will be valid for a finite number of days,
during which we will review your submission and work on deploying your
provisioning integration to the Microsoft Entra app gallery. You will be
given access to this experience when it releases to Private Preview in
CY2026.

# Provide feedback

Once you get a chance to test the pilot, please fill out the following
feedback form: [Feedback Form for Self-Service Validation of
Provisioning Integrations (Pilot) – Fill out
form](https://forms.microsoft.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR1xPIYfdXw5FhHBIH8BxY9ZUNTJTRkc0SDUxOTdHSFk5UEZQVkVZRjhTMy4u)

In the form, you may specify whether you are interested in participating
in a follow-up feedback session with the Entra App Provisioning feature
team. In this feedback session, we would ask you more questions about
your experience.

We’re excited to hear more from you! Thank you for participating in our
pilot—your insights help us make Microsoft Entra ID better.

# Appendix

## Script for assigning permissions to your Logic app

\$logicAppManagedId = "" 

\$graphAppId="00000003-0000-0000-c000-000000000000" 

\$roleValue="Directory.ReadWrite.All" 

\$graphSpId = az ad sp list --filter "appId eq '\$graphAppId'" --query
"\[0\].id" -o tsv  

\$roleId = az ad sp show --id \$graphSpId --query
"appRoles\[?value=='\$roleValue'\].id" -o tsv 

\$body =
@{ principalId=\$logicAppManagedId; resourceId=\$graphSpId; appRoleId=\$roleId }
\| ConvertTo-Json 

az rest --method POST
--uri "https://graph.microsoft.com/v1.0/servicePrincipals/\$logicAppManagedId/appRoleAssignments"
--headers "Content-Type=application/json" --body "\$body" 

\$roleValue="Application.ReadWrite.All" 

\$roleId = az ad sp show --id \$graphSpId --query
"appRoles\[?value=='\$roleValue'\].id" -o tsv 

\$body =
@{ principalId=\$logicAppManagedId; resourceId=\$graphSpId; appRoleId=\$roleId }
\| ConvertTo-Json 

az rest --method POST
--uri "https://graph.microsoft.com/v1.0/servicePrincipals/\$logicAppManagedId/appRoleAssignments"
--headers "Content-Type=application/json" --body "\$body" 

\$roleValue="Synchronization.ReadWrite.All" 

\$roleId = az ad sp show --id \$graphSpId --query
"appRoles\[?value=='\$roleValue'\].id" -o tsv 

\$body =
@{ principalId=\$logicAppManagedId; resourceId=\$graphSpId; appRoleId=\$roleId }
\| ConvertTo-Json 

az rest --method POST
--uri "https://graph.microsoft.com/v1.0/servicePrincipals/\$logicAppManagedId/appRoleAssignments"
--headers "Content-Type=application/json" --body "\$body" 

\$roleValue="AuditLog.Read.All" 

\$roleId = az ad sp show --id \$graphSpId --query
"appRoles\[?value=='\$roleValue'\].id" -o tsv 

\$body =
@{ principalId=\$logicAppManagedId; resourceId=\$graphSpId; appRoleId=\$roleId }
\| ConvertTo-Json 

az rest --method POST
--uri "https://graph.microsoft.com/v1.0/servicePrincipals/\$logicAppManagedId/appRoleAssignments"
--headers "Content-Type=application/json" --body "\$body" 

\$roleValue="User.ReadWrite.All" 

\$roleId = az ad sp show --id \$graphSpId --query
"appRoles\[?value=='\$roleValue'\].id" -o tsv 

\$body =
@{ principalId=\$logicAppManagedId; resourceId=\$graphSpId; appRoleId=\$roleId }
\| ConvertTo-Json 

az rest --method POST
--uri "https://graph.microsoft.com/v1.0/servicePrincipals/\$logicAppManagedId/appRoleAssignments"
--headers "Content-Type=application/json" --body "\$body" 

\$roleValue="Group.ReadWrite.All" 

\$roleId = az ad sp show --id \$graphSpId --query
"appRoles\[?value=='\$roleValue'\].id" -o tsv 

\$body =
@{ principalId=\$logicAppManagedId; resourceId=\$graphSpId; appRoleId=\$roleId }
\| ConvertTo-Json 

az rest --method POST
--uri "https://graph.microsoft.com/v1.0/servicePrincipals/\$logicAppManagedId/appRoleAssignments"
--headers "Content-Type=application/json" --body "\$body" 

## Script for Logic App Validation

[ValidateLogicAppRun.ps1](https://onedrive.cloud.microsoft/:u:/a@tn9g7bf7/S/IQCGtvVTNyhsQrSAIOgD29foActXLLfZD6PLfKUWfhA6aMY?e=TdwSxy)
