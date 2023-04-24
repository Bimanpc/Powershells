# Vasiliy 2.0

$ruleCacheAction=[Microsoft.Azure.PowerShell.Cmdlets.Cdn.Models.Api20210601.DeliveryRuleCacheExpirationAction]::New()
$ruleCacheAction.Name=[Microsoft.Azure.PowerShell.Cmdlets.Cdn.Support.DeliveryRuleAction]::CacheExpiration
$ruleCacheAction.ParameterCacheDuration="1.00:00:00"
$ruleCacheAction.ParameterCacheBehavior=[Microsoft.Azure.PowerShell.Cmdlets.Cdn.Support.CacheBehavior]::SetIfMissing


$profileName="MyProf"
$rgName = "MyRegName"
$name = "EndptName"

$cdnEndpoint = Get-AzCdnEndpoint -ProfileName $profileName -ResourceGroupName $rgName -Name $name
$cond1 = New-AzCdnDeliveryRuleCookiesConditionObject -Name Cookies -ParameterOperator Equal -ParameterSelector test -ParameterMatchValue test -ParameterNegateCondition $False -ParameterTransform Lowercase
$rule = New-AzCdnDeliveryRuleObject -Action @($ruleCacheAction) -Order 1 -Name "Caching" -Condition @($cond1)
Update-AzCdnEndpoint -ProfileName $profileName -ResourceGroupName $rgName -Name $name -DeliveryPolicyRule @($rule)