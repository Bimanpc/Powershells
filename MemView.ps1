<#PSScriptInfo
 
.VERSION 2022
.AUTHOR PC TECH GREU
 #>

<#
 
.DESCRIPTION
 Get Windows Memory by Wmi
.EXAMPLE
 Get-WindowsMemory
 
.EXAMPLE
 Get-WindowsMemory FileServer01 -Credential (Get-Credential)
 
.EXAMPLE
 Get-WindowsMemory FileServer01,FileServer02
 
.EXAMPLE
 Get-ClusterNode | Get-WindowsMemory | ft
 
#>

[CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)][alias("DNSHostName","Name")]$ComputerName = '.',
        [PSCredential]$Credential
    )
    
    BEGIN {}
    
    PROCESS  {
        Foreach ($Comp in $ComputerName) {
            $param = @{
                'ComputerName' = $Comp
                'ErrorVariable' = 'WmiRequestError'
            }
            if($Credential -and ($Comp -notin @($env:COMPUTERNAME,'.'))){$param.Credential = $Credential}
                
            try{
                $PerfOS_Memory = Get-WmiObject -Class Win32_PerfRawData_PerfOS_Memory @param
                $PhysicalMemory = Get-WmiObject -Class Win32_PhysicalMemory @param
                $TotalPhysicalMemory = ($PhysicalMemory | Measure-Object -Sum -Property Capacity).Sum
            } Catch {$WmiRequestError; break}
            
            if($PerfOS_Memory -and !$WmiRequestError){
            
                [pscustomobject][ordered]@{
                    'ComputerName' = $PerfOS_Memory.PSComputerName
                    'AvailableGB' = [System.Math]::Round(($PerfOS_Memory.AvailableBytes/1gb),2)
                    'inUseGB' = [System.Math]::Round(($TotalPhysicalMemory/1gb - $PerfOS_Memory.AvailableBytes/1gb),2)
                    'CacheGB' = [System.Math]::Round(($PerfOS_Memory.CacheBytes/1gb),2)
                    'CommittedGB' = [System.Math]::Round(($PerfOS_Memory.CommittedBytes/1gb),2)
                    'CommitLimitGB' = [System.Math]::Round(($PerfOS_Memory.CommitLimit/1gb),2)
                    'PoolPagedMB' = [System.Math]::Round(($PerfOS_Memory.PoolPagedBytes/1mb),2)
                    'PoolNonpagedMB' = [System.Math]::Round(($PerfOS_Memory.PoolNonpagedBytes/1mb),2)
                    'TotalPhysicalMemory' = [System.Math]::Round(($TotalPhysicalMemory/1gb),2)
                    'ModuleSize' = ($PhysicalMemory | Group-Object -Property Capacity | % {[string]$($_.Count.ToString() + ' x ' + ($_.Name / 1GB).ToString() + 'GB')}) -join ', '
                }
            }
            $PerfOS_Memory = $Null
            $PhysicalMemory = $Null
            $TotalPhysicalMemory = $Null
            $WmiRequestError = $Null
            
        }
        
    }
    
    END {}