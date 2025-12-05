$miObjId = ""
$graphAppId="00000003-0000-0000-c000-000000000000"
$roleValue="Directory.ReadWrite.All"
$graphSpId = az ad sp list --filter "appId eq '$graphAppId'" --query "[0].id" -o tsv 
$roleId = az ad sp show --id $graphSpId --query "appRoles[?value=='$roleValue'].id" -o tsv
$body = @{ principalId=$miObjId; resourceId=$graphSpId; appRoleId=$roleId } | ConvertTo-Json
az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$miObjId/appRoleAssignments" --headers "Content-Type=application/json" --body "$body"
$roleValue="Application.ReadWrite.All"
$roleId = az ad sp show --id $graphSpId --query "appRoles[?value=='$roleValue'].id" -o tsv
$body = @{ principalId=$miObjId; resourceId=$graphSpId; appRoleId=$roleId } | ConvertTo-Json
az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$miObjId/appRoleAssignments" --headers "Content-Type=application/json" --body "$body"
$roleValue="Synchronization.ReadWrite.All"
$roleId = az ad sp show --id $graphSpId --query "appRoles[?value=='$roleValue'].id" -o tsv
$body = @{ principalId=$miObjId; resourceId=$graphSpId; appRoleId=$roleId } | ConvertTo-Json
az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$miObjId/appRoleAssignments" --headers "Content-Type=application/json" --body "$body"
$roleValue="AuditLog.Read.All"
$roleId = az ad sp show --id $graphSpId --query "appRoles[?value=='$roleValue'].id" -o tsv
$body = @{ principalId=$miObjId; resourceId=$graphSpId; appRoleId=$roleId } | ConvertTo-Json
az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$miObjId/appRoleAssignments" --headers "Content-Type=application/json" --body "$body"
$roleValue="User.ReadWrite.All"
$roleId = az ad sp show --id $graphSpId --query "appRoles[?value=='$roleValue'].id" -o tsv
$body = @{ principalId=$miObjId; resourceId=$graphSpId; appRoleId=$roleId } | ConvertTo-Json
az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$miObjId/appRoleAssignments" --headers "Content-Type=application/json" --body "$body"
$roleValue="Group.ReadWrite.All"
$roleId = az ad sp show --id $graphSpId --query "appRoles[?value=='$roleValue'].id" -o tsv
$body = @{ principalId=$miObjId; resourceId=$graphSpId; appRoleId=$roleId } | ConvertTo-Json
az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$miObjId/appRoleAssignments" --headers "Content-Type=application/json" --body "$body"