<#
.SYNOPSIS
    Validates a Logic App provisioning run against the expected template.

.DESCRIPTION
    This script validates that a Logic App run:
    1. Successfully completed
    2. Used the correct template version with all required stages
    3. Executed all actions defined in the template

    The script authenticates using Azure CLI and requires the user to have:
    - Reader role on the subscription
    - Logic App Operator role on the subscription or Logic App resource

.PARAMETER SubscriptionId
    The Azure subscription ID containing the Logic App.

.PARAMETER ResourceGroup
    The resource group name containing the Logic App.

.PARAMETER LogicAppName
    The name of the Logic App workflow.

.PARAMETER RunId
    The specific run ID to validate (just the ID, not the full path).

.EXAMPLE
    .\ValidateLogicAppRun.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" `
                              -ResourceGroup "MyResourceGroup" `
                              -LogicAppName "MyLogicApp" `
                              -RunId "08584361051946613703020273411CU28"

.EXAMPLE
    .\ValidateLogicAppRun.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" `
                              -ResourceGroup "MyResourceGroup" `
                              -LogicAppName "MyLogicApp" `
                              -RunId "08584361051946613703020273411CU28" `
                              -SkipActionDetails
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$LogicAppName,

    [Parameter(Mandatory=$true)]
    [string]$RunId,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipActionDetails
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7 -and -not $SkipActionDetails) {
    Write-Host "ERROR: This script requires PowerShell 7.0 or later for parallel processing." -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Please run this script in PowerShell 7+ or use the -SkipActionDetails flag." -ForegroundColor Yellow
    exit 1
}

function Write-ValidationResult {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Success" { "Green" }
        "Error" { "Red" }
        "Warning" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host $Message -ForegroundColor $color
}

function Invoke-AzureRestApi {
    param(
        [string]$Uri,
        [string]$AccessToken
    )
    
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $Uri -Headers $headers -Method Get -ErrorAction Stop
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        Write-ValidationResult "  API call failed:" -Level Error
        Write-ValidationResult "    Status: $statusCode" -Level Error
        Write-ValidationResult "    Error: $errorMessage" -Level Error
        
        throw "API call failed with status $statusCode"
    }
}

function Get-AllLogicAppActions {
    param(
        [string]$BaseUri,
        [string]$AccessToken,
        [string]$ApiVersion
    )
    
    $allActions = @()
    $nextUri = "$BaseUri/actions?api-version=$ApiVersion"
    $pageCount = 0
    
    while ($nextUri) {
        $pageCount++
        Write-ValidationResult "  Fetching actions page $pageCount (total so far: $($allActions.Count))..."
        
        try {
            $response = Invoke-AzureRestApi -Uri $nextUri -AccessToken $AccessToken
            
            if ($response.value) {
                $allActions += $response.value
                Write-ValidationResult "    Added $($response.value.Count) actions from page $pageCount (total: $($allActions.Count))"
            }
            
            $nextUri = $null
            if ($response.nextLink) {
                $nextUri = $response.nextLink
            }
            elseif ($response.'@odata.nextLink') {
                $nextUri = $response.'@odata.nextLink'
            }
            
            if ($nextUri -and -not $nextUri.StartsWith("http")) {
                $nextUri = "https://management.azure.com$nextUri"
            }
        }
        catch {
            Write-ValidationResult "  Warning: Pagination stopped at page $pageCount" -Level Warning
            Write-ValidationResult "  Continuing with $($allActions.Count) actions retrieved so far" -Level Warning
            break
        }
    }
    
    Write-ValidationResult "  Fetched $($allActions.Count) total actions across $pageCount pages" -Level Success
    return $allActions
}

function Test-TemplateStructure {
    param(
        [object]$TemplateDefinition
    )
    
    $validationErrors = @()
    $foundStages = @()
    
    $actions = $TemplateDefinition.properties.definition.actions
    
    if (-not $actions) {
        return @{
            IsValid = $false
            Errors = @("Template has no actions defined")
            FoundStages = @()
            RequiredStages = @()
        }
    }
    
    $templateActionNames = $actions.PSObject.Properties.Name
    
    Write-ValidationResult "`nValidating template structure..."
    Write-ValidationResult "  Found $($templateActionNames.Count) root-level actions in template"
    
    foreach ($actionName in $templateActionNames) {
        $friendlyName = $actionName -replace '_', ' '
        
        Write-ValidationResult "  [INFO] Required stage: $friendlyName ($actionName)" -Level Info
        $foundStages += @{
            StageName = $friendlyName
            ActionName = $actionName
        }
    }
    
    return @{
        IsValid = $true
        Errors = $validationErrors
        FoundStages = $foundStages
        RequiredStages = $templateActionNames
    }
}

function Test-RequiredStagesExecuted {
    param(
        [string[]]$RequiredStages,
        [object]$RunActions
    )
    
    $validationErrors = @()
    $stageResults = @()
    $executedActionNames = @()
    if ($RunActions -is [System.Collections.IDictionary]) {
        $executedActionNames = @($RunActions.Keys)
    }
    elseif ($RunActions.PSObject.Properties) {
        $executedActionNames = @($RunActions.PSObject.Properties.Name)
    }
    
    Write-ValidationResult "`nChecking required stages execution..."
    
    foreach ($stageName in $RequiredStages) {
        $friendlyName = $stageName -replace '_', ' '
        
        if ($executedActionNames -contains $stageName) {
            $actionData = $RunActions[$stageName]
            $status = "Unknown"
            
            if ($actionData -is [System.Collections.IDictionary]) {
                if ($actionData.Contains('_details')) {
                    $status = $actionData['_details'].status
                }
            }
            elseif ($actionData._details) {
                $status = $actionData._details.status
            }
            elseif ($actionData.status) {
                $status = $actionData.status
            }
            
            Write-ValidationResult "  [PASS] $friendlyName`: Executed (Status: $status)" -Level Success
            $stageResults += [ordered]@{
                stage = $friendlyName
                action = $stageName
                executed = $true
                status = $status
            }
        }
        else {
            $errorMsg = "Required stage not executed: $friendlyName ($stageName)"
            Write-ValidationResult "  [FAIL] $errorMsg" -Level Error
            $validationErrors += $errorMsg
            $stageResults += [ordered]@{
                stage = $friendlyName
                action = $stageName
                executed = $false
                status = "Not Executed"
            }
        }
    }
    
    return @{
        IsValid = $validationErrors.Count -eq 0
        Errors = $validationErrors
        StageResults = $stageResults
    }
}

function Compare-TemplateToRunActions {
    param(
        [object]$TemplateDefinition,
        [array]$RunActions
    )
    
    $templateActions = $TemplateDefinition.properties.definition.actions
    if (-not $templateActions) {
        return @{
            IsValid = $false
            Errors = @("Template has no actions to compare")
            MissingFromRun = @()
            ExtraInRun = @()
        }
    }
    
    $templateActionNames = @($templateActions.PSObject.Properties.Name)
    $runActionNames = @($RunActions | ForEach-Object { $_.name })
    
    Write-ValidationResult "`nComparing template actions to run execution..."
    Write-ValidationResult "  Template root actions: $($templateActionNames.Count)"
    Write-ValidationResult "  Run executed: $($runActionNames.Count) actions"
    
    $runActionNamesLower = @($runActionNames | ForEach-Object { $_.ToLower() })
    $missingFromRun = @($templateActionNames | Where-Object { $_.ToLower() -notin $runActionNamesLower })
    $validationErrors = @()
    
    if ($missingFromRun.Count -gt 0) {
        Write-ValidationResult "  [WARNING] $($missingFromRun.Count) template actions not found in run execution" -Level Warning
        
        $displayCount = [Math]::Min(10, $missingFromRun.Count)
        for ($i = 0; $i -lt $displayCount; $i++) {
            Write-ValidationResult "    - $($missingFromRun[$i])" -Level Warning
        }
        if ($missingFromRun.Count -gt 10) {
            Write-ValidationResult "    ... and $($missingFromRun.Count - 10) more" -Level Warning
        }
        
        $validationErrors += "Template actions missing from run: $($missingFromRun.Count)"
    }
    else {
        Write-ValidationResult "  [PASS] All template actions found in run execution" -Level Success
    }
    
    return @{
        IsValid = $missingFromRun.Count -eq 0
        Errors = $validationErrors
        MissingFromRun = $missingFromRun
    }
}

function Build-ActionPathMapping {
    param(
        [object]$TemplateDefinition
    )
    
    $actionPaths = @{}
    $actionOrder = @{}
    $actionsWithChildren = @{}
    
    function Get-ExecutionOrder {
        param(
            [object]$Actions
        )
        
        $actionNames = @($Actions.PSObject.Properties.Name | Where-Object { $_ })
        $dependencies = @{}
        
        foreach ($prop in $Actions.PSObject.Properties) {
            $name = $prop.Name
            if (-not $name) { continue }
            
            $def = $prop.Value
            $dependencies[$name] = @()
            
            if ($def.runAfter) {
                $dependencies[$name] = @($def.runAfter.PSObject.Properties.Name | Where-Object { $_ })
            }
        }
        
        $inDegree = @{}
        foreach ($name in $actionNames) { 
            if ($name) { $inDegree[$name] = 0 }
        }
        
        foreach ($name in $actionNames) {
            if (-not $name) { continue }
            foreach ($dep in $dependencies[$name]) {
                if ($dep -and ($actionNames -contains $dep)) {
                    $inDegree[$name]++
                }
            }
        }
        
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $order = @()
        
        foreach ($name in $actionNames) {
            if ($name -and $dependencies[$name].Count -eq 0) {
                $queue.Enqueue($name)
            }
        }
        
        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            $order += $current
            
            foreach ($name in $actionNames) {
                if (-not $name) { continue }
                if ($dependencies[$name] -contains $current) {
                    $dependencies[$name] = @($dependencies[$name] | Where-Object { $_ -ne $current })
                    if ($dependencies[$name].Count -eq 0) {
                        $queue.Enqueue($name)
                    }
                }
            }
        }
        
        $orderMap = @{}
        for ($i = 0; $i -lt $order.Count; $i++) {
            if ($order[$i]) {
                $orderMap[$order[$i]] = $i
            }
        }
        return $orderMap
    }
    
    function Traverse-Actions {
        param(
            [object]$Actions,
            [array]$ParentPath
        )
        
        if (-not $Actions) { return }
        
        $scopeOrder = Get-ExecutionOrder -Actions $Actions
        
        $Actions.PSObject.Properties | ForEach-Object {
            $actionName = $_.Name
            $actionDef = $_.Value
            $currentPath = $ParentPath + @($actionName)
            
            $actionPaths[$actionName] = $ParentPath
            $actionOrder[$actionName] = $scopeOrder[$actionName]
            
            $hasChildren = $false
            
            switch ($actionDef.type) {
                "Scope" {
                    if ($actionDef.actions -and $actionDef.actions.PSObject.Properties.Count -gt 0) {
                        $hasChildren = $true
                        Traverse-Actions -Actions $actionDef.actions -ParentPath $currentPath
                    }
                }
                "If" {
                    if ($actionDef.actions -and $actionDef.actions.PSObject.Properties.Count -gt 0) {
                        $hasChildren = $true
                        Traverse-Actions -Actions $actionDef.actions -ParentPath ($currentPath + @("[true]"))
                    }
                    if ($actionDef.else -and $actionDef.else.actions -and $actionDef.else.actions.PSObject.Properties.Count -gt 0) {
                        $hasChildren = $true
                        Traverse-Actions -Actions $actionDef.else.actions -ParentPath ($currentPath + @("[false]"))
                    }
                }
                "Until" {
                    if ($actionDef.actions -and $actionDef.actions.PSObject.Properties.Count -gt 0) {
                        $hasChildren = $true
                        Traverse-Actions -Actions $actionDef.actions -ParentPath $currentPath
                    }
                }
                "Foreach" {
                    if ($actionDef.actions -and $actionDef.actions.PSObject.Properties.Count -gt 0) {
                        $hasChildren = $true
                        Traverse-Actions -Actions $actionDef.actions -ParentPath $currentPath
                    }
                }
                "Switch" {
                    if ($actionDef.cases) {
                        $actionDef.cases.PSObject.Properties | ForEach-Object {
                            $caseName = $_.Name
                            if ($_.Value.actions -and $_.Value.actions.PSObject.Properties.Count -gt 0) {
                                $hasChildren = $true
                                Traverse-Actions -Actions $_.Value.actions -ParentPath ($currentPath + @("[case:$caseName]"))
                            }
                        }
                    }
                    if ($actionDef.default -and $actionDef.default.actions -and $actionDef.default.actions.PSObject.Properties.Count -gt 0) {
                        $hasChildren = $true
                        Traverse-Actions -Actions $actionDef.default.actions -ParentPath ($currentPath + @("[default]"))
                    }
                }
            }
            
            if ($hasChildren) {
                $actionsWithChildren[$actionName] = $true
            }
        }
    }
    
    $templateActions = $TemplateDefinition.properties.definition.actions
    if ($templateActions) {
        Write-ValidationResult "`nBuilding action path mapping from template..."
        Traverse-Actions -Actions $templateActions -ParentPath @()
        Write-ValidationResult "  Mapped $($actionPaths.Count) actions to their parent paths" -Level Success
        Write-ValidationResult "  Found $($actionsWithChildren.Count) actions with nested children" -Level Success
    }
    
    return @{
        Paths = $actionPaths
        Order = $actionOrder
        HasChildren = $actionsWithChildren
    }
}

function Build-TrueHierarchy {
    param(
        [array]$Actions,
        [hashtable]$ActionPathMapping,
        [scriptblock]$DetailsTransform
    )
    
    $actionPaths = $ActionPathMapping.Paths
    $actionOrder = $ActionPathMapping.Order
    
    $result = [ordered]@{}
    
    $actionsByPath = @{}
    foreach ($action in $Actions) {
        $actionName = $action.name
        if (-not $actionName) { continue }
        
        $path = if ($actionPaths.ContainsKey($actionName)) { $actionPaths[$actionName] } else { @() }
        $pathKey = $path -join "/"
        
        if (-not $actionsByPath.ContainsKey($pathKey)) {
            $actionsByPath[$pathKey] = @()
        }
        $actionsByPath[$pathKey] += $action
    }
    
    $sortedPathKeys = $actionsByPath.Keys | Sort-Object { ($_ -split "/").Count }
    
    foreach ($pathKey in $sortedPathKeys) {
        $actionsInPath = $actionsByPath[$pathKey]
        
        $sortedActions = $actionsInPath | Sort-Object { 
            if ($_.name -and $actionOrder.ContainsKey($_.name)) { $actionOrder[$_.name] } else { 999 }
        }
        
        $path = if ($pathKey -eq "") { @() } else { $pathKey -split "/" }
        $current = $result
        foreach ($segment in $path) {
            if (-not $segment) { continue }
            if (-not $current.Contains($segment)) {
                $current[$segment] = [ordered]@{}
            }
            $current = $current[$segment]
        }
        
        foreach ($action in $sortedActions) {
            $actionName = $action.name
            if (-not $actionName) { continue }
            
            if (-not $current.Contains($actionName)) {
                $current[$actionName] = [ordered]@{}
            }
            
            $details = if ($DetailsTransform) { & $DetailsTransform $action } else { $null }
            if ($details) {
                $current[$actionName]["_details"] = $details
            }
        }
    }
    
    $rootActions = if ($actionsByPath.ContainsKey("")) { $actionsByPath[""] } else { @() }
    $sortedRootNames = @($rootActions | Sort-Object { 
        if ($_.name -and $actionOrder.ContainsKey($_.name)) { $actionOrder[$_.name] } else { 999 }
    } | ForEach-Object { $_.name })
    
    $reorderedResult = [ordered]@{}
    foreach ($name in $sortedRootNames) {
        if ($name -and $result.Contains($name)) {
            $reorderedResult[$name] = $result[$name]
        }
    }
    foreach ($key in $result.Keys) {
        if (-not $reorderedResult.Contains($key)) {
            $reorderedResult[$key] = $result[$key]
        }
    }
    
    return $reorderedResult
}

function Get-TestFromPath {
    param([array]$Path)
    
    foreach ($segment in $Path) {
        if ($segment -match ".*_Test$|.*Test_.*|.*_User_Test|.*_Group_Test") {
            return $segment
        }
    }
    return $null
}

function Get-PhaseFromName {
    param([string]$ActionName)
    
    if ($ActionName -match "Phase(\d+)") {
        return "Phase$($Matches[1])"
    }
    if ($ActionName -match "CreatePhase|Create_Phase") {
        return "CreatePhase"
    }
    if ($ActionName -match "UpdatePhase|Update_Phase") {
        return "UpdatePhase"
    }
    if ($ActionName -match "DeletePhase|Delete_Phase") {
        return "DeletePhase"
    }
    return $null
}

try {
    Write-ValidationResult "=== Logic App Run Validation ===" -Level Success
    Write-ValidationResult "Subscription: $SubscriptionId"
    Write-ValidationResult "Resource Group: $ResourceGroup"
    Write-ValidationResult "Logic App: $LogicAppName"
    Write-ValidationResult "Run ID: $RunId"
    Write-ValidationResult ""
    
    Write-ValidationResult "Authenticating..."
    $tokenJson = az account get-access-token --resource https://management.azure.com --query "{accessToken:accessToken}" -o json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Authentication failed. Please run 'az login' and ensure you're on the correct tenant."
    }
    
    $tokenObj = $tokenJson | ConvertFrom-Json
    $accessToken = $tokenObj.accessToken
    Write-ValidationResult "  Authenticated successfully" -Level Success
    
    $apiVersionsToTry = @("2019-05-01", "2018-07-01-preview", "2016-06-01")
    $workflowFound = $false
    $selectedApiVersion = $null
    
    $basePath = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Logic/workflows/$LogicAppName"
    
    Write-ValidationResult "Attempting to access Logic App..."
    foreach ($apiVersion in $apiVersionsToTry) {
        try {
            Write-ValidationResult "  Trying API version: $apiVersion" -Level Info
            $workflowUri = "$basePath`?api-version=$apiVersion"
            $workflow = Invoke-AzureRestApi -Uri $workflowUri -AccessToken $accessToken
            
            Write-ValidationResult "  SUCCESS with API version $apiVersion" -Level Success
            Write-ValidationResult "  Logic App: $($workflow.name)" -Level Success
            Write-ValidationResult "  Location: $($workflow.location)" -Level Success
            Write-ValidationResult "  State: $($workflow.properties.state)" -Level Success
            
            $workflowFound = $true
            $selectedApiVersion = $apiVersion
            break
        }
        catch {
            Write-ValidationResult "  Failed with $apiVersion" -Level Warning
            continue
        }
    }
    
    if (-not $workflowFound) {
        throw "Cannot access Logic App with any API version. Please verify the resource exists and you have permissions."
    }
    
    Write-ValidationResult "`nFetching run data..."
    $runUri = "$basePath/runs/$RunId`?api-version=$selectedApiVersion"
    $runResponse = Invoke-AzureRestApi -Uri $runUri -AccessToken $accessToken
    
    $runStatus = $runResponse.properties.status
    $startTime = $runResponse.properties.startTime
    $endTime = $runResponse.properties.endTime
    
    Write-ValidationResult "  Run Status: $runStatus" -Level $(if ($runStatus -eq "Succeeded") { "Success" } else { "Warning" })
    Write-ValidationResult "  Started: $startTime" -Level Info
    Write-ValidationResult "  Ended: $endTime" -Level Info
    
    $workflowId = $runResponse.properties.workflow.id
    $versionNumber = "unknown"
    
    if ($workflowId -match "/versions/(.+)$") {
        $versionNumber = $Matches[1]
        Write-ValidationResult "  Workflow Version: $versionNumber" -Level Success
    }
    else {
        Write-ValidationResult "  Warning: Could not extract version from: $workflowId" -Level Warning
    }
    
    Write-ValidationResult "`nFetching template definition..."
    $versionUri = "$basePath/versions/$versionNumber`?api-version=$selectedApiVersion"
    
    try {
        $templateDefinition = Invoke-AzureRestApi -Uri $versionUri -AccessToken $accessToken
        Write-ValidationResult "  Retrieved template version $versionNumber" -Level Success
    }
    catch {
        Write-ValidationResult "  ERROR: Could not fetch template definition" -Level Error
        throw "Cannot validate template structure without template definition"
    }
    
    $templateValidation = Test-TemplateStructure -TemplateDefinition $templateDefinition
    
    Write-ValidationResult "`nFetching run actions..."
    $allActions = Get-AllLogicAppActions -BaseUri "$basePath/runs/$RunId" -AccessToken $accessToken -ApiVersion $selectedApiVersion
    
    $actionComparison = Compare-TemplateToRunActions -TemplateDefinition $templateDefinition -RunActions $allActions
    
    $actionPathMapping = Build-ActionPathMapping -TemplateDefinition $templateDefinition

    $allActionsHierarchy = Build-TrueHierarchy -Actions $allActions -ActionPathMapping $actionPathMapping -DetailsTransform {
        param($action)
        [ordered]@{
            status = $action.properties.status
            code = $action.properties.code
            startTime = $action.properties.startTime
            endTime = $action.properties.endTime
            error = $action.properties.error
            inputs = $action.properties.inputs
            outputs = $action.properties.outputs
        }
    }

    $stagesExecution = Test-RequiredStagesExecuted -RequiredStages $templateValidation.RequiredStages -RunActions $allActionsHierarchy
    
    Write-ValidationResult "`nAction Statistics:"
    $succeededCount = ($allActions | Where-Object { $_.properties.status -eq "Succeeded" }).Count
    $failedCount = ($allActions | Where-Object { $_.properties.status -eq "Failed" }).Count
    $skippedCount = ($allActions | Where-Object { $_.properties.status -eq "Skipped" }).Count
    
    Write-ValidationResult "  Total: $($allActions.Count)"
    Write-ValidationResult "  Succeeded: $succeededCount" -Level Success
    Write-ValidationResult "  Failed: $failedCount" -Level $(if ($failedCount -gt 0) { "Error" } else { "Success" })
    Write-ValidationResult "  Skipped: $skippedCount"
    
    $finalResultsAction = $allActions | Where-Object { $_.name -match "Compose.*Final.*Results|Final.*Results" } | Select-Object -First 1
    
    if ($finalResultsAction) {
        Write-ValidationResult "`nFinal Results:"
        Write-ValidationResult "  Action: $($finalResultsAction.name)" -Level Success
        Write-ValidationResult "  Status: $($finalResultsAction.properties.status)" -Level $(if ($finalResultsAction.properties.status -eq "Succeeded") { "Success" } else { "Warning" })
    }
    
    Write-ValidationResult "`n=== Validation Summary ===" -Level Success
    
    $overallPassed = ($runStatus -eq "Succeeded") -and 
                     ($failedCount -eq 0) -and 
                     ($versionNumber -ne "unknown") -and
                     ($templateValidation.IsValid) -and
                     ($stagesExecution.IsValid) -and
                     ($actionComparison.IsValid)
    
    if ($overallPassed) {
        Write-ValidationResult "VALIDATION PASSED" -Level Success
        Write-ValidationResult "Run completed successfully with valid template version $versionNumber" -Level Success
        Write-ValidationResult "All required provisioning stages are present in the template" -Level Success
        Write-ValidationResult "All template actions were executed in the run" -Level Success
    }
    else {
        Write-ValidationResult "VALIDATION FAILED" -Level Error
        
        if ($runStatus -ne "Succeeded") {
            Write-ValidationResult "  - Run status: $runStatus (expected Succeeded)" -Level Error
        }
        
        if ($failedCount -gt 0) {
            Write-ValidationResult "  - Failed actions: $failedCount" -Level Error
            
            $failedActionsList = $allActions | Where-Object { $_.properties.status -eq "Failed" } | Select-Object -First 5
            foreach ($action in $failedActionsList) {
                $errorMsg = if ($action.properties.error.message) { $action.properties.error.message } else { "No error details" }
                Write-ValidationResult "    * $($action.name): $errorMsg" -Level Error
            }
        }
        
        if ($versionNumber -eq "unknown") {
            Write-ValidationResult "  - Could not determine workflow version" -Level Error
        }
        
        if (-not $templateValidation.IsValid) {
            Write-ValidationResult "  - Template structure validation failed:" -Level Error
            foreach ($templateError in $templateValidation.Errors) {
                Write-ValidationResult "    * $templateError" -Level Error
            }
        }

        if (-not $stagesExecution.IsValid) {
            Write-ValidationResult "  - Required stages execution failed:" -Level Error
            foreach ($stageError in $stagesExecution.Errors) {
                Write-ValidationResult "    * $stageError" -Level Error
            }
        }
        
        if (-not $actionComparison.IsValid) {
            Write-ValidationResult "  - Template-to-run comparison failed:" -Level Error
            foreach ($comparisonError in $actionComparison.Errors) {
                Write-ValidationResult "    * $comparisonError" -Level Error
            }
        }
    }
    
    $validationErrors = @()
    if ($runStatus -ne "Succeeded") { $validationErrors += "Run status: $runStatus (expected Succeeded)" }
    if ($failedCount -gt 0) { $validationErrors += "Failed actions: $failedCount" }
    if ($versionNumber -eq "unknown") { $validationErrors += "Could not determine workflow version" }
    if (-not $templateValidation.IsValid) { $validationErrors += $templateValidation.Errors }
    if (-not $stagesExecution.IsValid) { $validationErrors += $stagesExecution.Errors }
    if (-not $actionComparison.IsValid) { $validationErrors += $actionComparison.Errors }
    
    # Extract workflow parameters
    $runParameters = [ordered]@{}

    $workflowVersionId = $runResponse.properties.workflow.id
    if ($workflowVersionId) {
        try {
            $workflowVersionUri = "https://management.azure.com$($workflowVersionId)?api-version=2019-05-01"
            $headers = @{ "Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" }
            $workflowVersion = Invoke-RestMethod -Uri $workflowVersionUri -Headers $headers -Method Get -ErrorAction Stop
            
            if ($workflowVersion.properties.definition.parameters) {
                $params = $workflowVersion.properties.definition.parameters
                foreach ($paramName in $params.PSObject.Properties.Name) {
                    $paramObj = $params.$paramName
                    $paramValue = $paramObj.defaultValue
                    
                    if ($paramName -imatch '^(scimBearerToken|.*secret.*|.*credential.*)$') {
                        $runParameters[$paramName] = "***"
                    }
                    elseif ($paramName -eq 'defaultUserProperties' -and $paramValue -is [System.Collections.IEnumerable]) {
                        $redactedUsers = @()
                        foreach ($user in $paramValue) {
                            $userJson = $user | ConvertTo-Json -Depth 10 -Compress
                            $userJson = $userJson -replace '"password"\s*:\s*"[^"]*"', '"password":"***"'
                            $redactedUsers += ($userJson | ConvertFrom-Json)
                        }
                        $runParameters[$paramName] = $redactedUsers
                    }
                    else {
                        $runParameters[$paramName] = $paramValue
                    }
                }
            }
        } catch {
            Write-ValidationResult "  Could not fetch workflow version parameters: $_" -Level Warning
        }
    }
    
    $duration = if ($startTime -and $endTime) {
        $start = [DateTime]::Parse($startTime)
        $end = [DateTime]::Parse($endTime)
        $diff = $end - $start
        "$($diff.Hours)h $($diff.Minutes)m $($diff.Seconds)s"
    } else {
        "N/A"
    }
    
    Write-ValidationResult "`nGenerating JSON report..."
    $jsonOutputPath = Join-Path $PSScriptRoot "validation-result-$RunId.json"
    
    $failedActionsEnriched = if ($failedCount -gt 0) {
        $failedRaw = @($allActions | Where-Object { $_.properties.status -eq "Failed" })
        $failedSorted = $failedRaw | Sort-Object { $_.properties.startTime }
        
        @($failedSorted | ForEach-Object {
            $actionName = $_.name
            $path = if ($actionPathMapping.Paths.ContainsKey($actionName)) { $actionPathMapping.Paths[$actionName] } else { @() }
            $fullPath = $path + @($actionName)
            $pathString = $fullPath -join " > "
            $test = Get-TestFromPath -Path $fullPath
            $phase = Get-PhaseFromName -ActionName $actionName
            
            [ordered]@{
                name = $actionName
                path = $pathString
                test = $test
                phase = $phase
                status = $_.properties.status
                code = $_.properties.code
                startTime = $_.properties.startTime
                endTime = $_.properties.endTime
                errorCode = $_.properties.error.code
                errorMessage = $_.properties.error.message
            }
        })
    } else { @() }

    $outputData = [ordered]@{
        validationResult = if ($overallPassed) { "PASSED" } else { "FAILED" }
        runStatus = $runStatus
        validationChecks = [ordered]@{
            noFailedActions = ($failedCount -eq 0)
            templateVersionKnown = ($versionNumber -ne "unknown")
            templateStructureValid = $templateValidation.IsValid
            requiredStagesExecuted = $stagesExecution.IsValid
            allTemplateActionsExecuted = $actionComparison.IsValid
        }
        timestamp = (Get-Date).ToString("o")
        runId = $RunId
        templateId = $versionNumber
        logicAppName = $LogicAppName
        resourceGroup = $ResourceGroup
        startTime = $startTime
        endTime = $endTime
        duration = $duration
        parameters = if ($runParameters.Count -gt 0) { $runParameters } else { $null }
        actionSummary = [ordered]@{
            total = $allActions.Count
            succeeded = $succeededCount
            failed = $failedCount
            skipped = $skippedCount
        }
        validationErrors = if ($overallPassed) { $null } else { $validationErrors }
        failedActions = if ($failedActionsEnriched.Count -gt 0) { $failedActionsEnriched } else { $null }
        templateValidation = [ordered]@{
            valid = $templateValidation.IsValid -and $stagesExecution.IsValid
            requiredStages = $stagesExecution.StageResults
            errors = $stagesExecution.Errors
        }
        actionComparison = [ordered]@{
            valid = $actionComparison.IsValid
            missingFromRunCount = $actionComparison.MissingFromRun.Count
            missingActions = if ($actionComparison.MissingFromRun.Count -gt 0) { $actionComparison.MissingFromRun } else { $null }
        }
        allActionsDetailed = $null
    }
    
    if ($SkipActionDetails) {
        Write-ValidationResult "  Skipping action inputs/outputs (SkipActionDetails flag set)" -Level Info
        $outputData.allActionsDetailed = $allActionsHierarchy
    } else {
        Write-ValidationResult "`nFetching action inputs/outputs (this may take a few minutes)..." -Level Info
        
        $totalActions = $allActions.Count
        $syncCounter = [ref]0
        
        $detailedActions = @($allActions | ForEach-Object -Parallel {
            $action = $_
            $currentIndex = [System.Threading.Interlocked]::Increment($using:syncCounter)
            $total = $using:totalActions
            $basePath = $using:basePath
            $runId = $using:RunId
            $apiVersion = $using:selectedApiVersion
            $token = $using:accessToken
            
            if ($currentIndex % 50 -eq 0 -or $currentIndex -eq 1) {
                Write-Host "  Processing action $currentIndex/$total..." -ForegroundColor Gray
            }
            
            $actionDetail = [ordered]@{
                status = $action.properties.status
                code = $action.properties.code
                startTime = $action.properties.startTime
                endTime = $action.properties.endTime
                error = if ($action.properties.error) {
                    [ordered]@{ code = $action.properties.error.code; message = $action.properties.error.message }
                } else { $null }
                inputs = $null
                outputs = $null
            }
            
            if ($action.properties.status -eq "Succeeded") {
                if ($action.properties.inputsLink.uri) {
                    try {
                        $actionDetail.inputs = Invoke-RestMethod -Uri $action.properties.inputsLink.uri -Method Get -ErrorAction Stop
                    } catch { $actionDetail.inputs = $null }
                }
                
                if ($action.properties.outputsLink.uri) {
                    try {
                        $actionDetail.outputs = Invoke-RestMethod -Uri $action.properties.outputsLink.uri -Method Get -ErrorAction Stop
                    } catch { $actionDetail.outputs = $null }
                }
                
                if ($null -eq $actionDetail.inputs -and $null -eq $actionDetail.outputs) {
                    try {
                        $headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
                        $repetitionsUri = "$basePath/runs/$runId/actions/$($action.name)/repetitions?api-version=$apiVersion"
                        $repetitionsResponse = Invoke-RestMethod -Uri $repetitionsUri -Headers $headers -Method Get -ErrorAction Stop
                        
                        if ($repetitionsResponse.value -and $repetitionsResponse.value.Count -gt 0) {
                            $lastRepetition = $repetitionsResponse.value | Sort-Object { $_.properties.startTime } | Select-Object -Last 1
                            if ($lastRepetition.properties.inputsLink.uri) {
                                try { $actionDetail.inputs = Invoke-RestMethod -Uri $lastRepetition.properties.inputsLink.uri -Method Get -ErrorAction Stop }
                                catch { $actionDetail.inputs = $null }
                            }
                            if ($lastRepetition.properties.outputsLink.uri) {
                                try { $actionDetail.outputs = Invoke-RestMethod -Uri $lastRepetition.properties.outputsLink.uri -Method Get -ErrorAction Stop }
                                catch { $actionDetail.outputs = $null }
                            }
                        }
                    } catch { }
                }
            }
            
            [PSCustomObject]@{ name = $action.name; detail = $actionDetail }
        } -ThrottleLimit 10)
        
        # Build hierarchy with full details (inputs/outputs)
        $outputData.allActionsDetailed = Build-TrueHierarchy -Actions $detailedActions -ActionPathMapping $actionPathMapping -DetailsTransform { param($a) $a.detail }
    }

    $outputData | ConvertTo-Json -Depth 40 | Out-File -FilePath $jsonOutputPath -Encoding UTF8
    Write-ValidationResult "  JSON report saved to: $jsonOutputPath" -Level Success
    Write-ValidationResult ""
    Write-ValidationResult "Validation report generated successfully!" -Level Success
    Write-ValidationResult "  - JSON: $jsonOutputPath" -Level Info
    
    exit $(if ($overallPassed) { 0 } else { 1 })
}
catch {
    Write-ValidationResult "`nScript failed: $_" -Level Error
    Write-ValidationResult $_.ScriptStackTrace -Level Error
    exit 1
}