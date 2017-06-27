param(
    [parameter(Mandatory=$false)]
    [string]$sourceSubscriptionId,
    [parameter(Mandatory=$false)]
    [string]$sourceResourceGroupName,
    [parameter(Mandatory=$false)]
    [string]$sourceManagedDiskName,
    [parameter(Mandatory=$false)]
    [string]$targetVirtualNetResourceGroupName,
    [parameter(Mandatory=$false)]
    [string]$targetSubscriptionId,
    [parameter(Mandatory=$false)]
    [string]$targetVirtualNetworkName,
    [parameter(Mandatory=$false)]
    [string]$targetSubnetName,
    [parameter(Mandatory=$false)]
    [string]$targetSubnetPrefix,
    [parameter(Mandatory=$true)]
    [string]$targetResourceGroupName,
    [parameter(Mandatory=$true)]
    [string]$targetLocation,
    [parameter(Mandatory=$true)]
    [string]$targetVirtualMachineName,
    [parameter(Mandatory=$true)]
    [string]$targetVirtualMachineSize
)



#region Funcoes

function Write-Log 
{ 
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory=$true)] 
        [string]$Mensagem,
        [Parameter(Mandatory=$false)]         
        [string]$DiretorioLog=".\",
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info"
    ) 
     
    try 
    {  
        $DateTime = Get-Date -Format ‘dd-MM-yyyy HH:mm:ss’ 
        $ConteudoFormatado = "$DateTime - $Level - $Mensagem"

        If(-Not ($DiretorioLog.EndsWith("\")))
        {
            $DiretorioLog = "$DiretorioLog\"
        }

        if(-Not (Test-Path $DiretorioLog))
        {
           New-Item -ItemType Directory $DiretorioLog -Force
        }

        $arquivoLog = "$DiretorioLog$(Get-Date -Format 'yyyy-MM-dd').log"

        switch ($Level) { 
            'Error' { 
                Write-Error $Mensagem 
                $LevelText = 'ERROR:' 
                } 
            'Warn' { 
                Write-Warning $Mensagem 
                $LevelText = 'WARNING:' 
                } 
            'Info' { 
                Write-Verbose $Mensagem 
                $LevelText = 'INFO:' 
                } 
        } 
        Add-Content -Value $ConteudoFormatado  -Path $arquivoLog -Force
    } 
    catch 
    { 
        Write-Error $_.Exception.Message 
    } 
}

#endregion

try{

    #Variaveis
    $targeDiskName = ($targetVirtualMachineName.ToLower()+'_disk')

    Write-Log "Criando Resource Group"
    New-AzureRmResourceGroup -Name $targetResourceGroupName -Location $targetLocation -Force
    
    Write-Log "Criando copia do VHD da VM Template"
    Select-AzureRmSubscription -SubscriptionId $sourceSubscriptionId
    $managedDisk= Get-AzureRMDisk -ResourceGroupName $sourceResourceGroupName -DiskName $sourceManagedDiskName
    Select-AzureRmSubscription -SubscriptionId $targetSubscriptionId
    $diskConfig = New-AzureRmDiskConfig -SourceResourceId $managedDisk.Id -Location $managedDisk.Location -CreateOption Copy
    New-AzureRmDisk -Disk $diskConfig -DiskName $targeDiskName -ResourceGroupName $targetResourceGroupName

    Write-Log "Recuperando subscription destino, vnet e copia do disco"
    Select-AzureRmSubscription -SubscriptionId $targetSubscriptionId
    $disk =  Get-AzureRmDisk -ResourceGroupName $targetResourceGroupName -DiskName $targeDiskName
    $vnet = Get-AzureRmVirtualNetwork -Name $targetVirtualNetworkName -ResourceGroupName $targetVirtualNetResourceGroupName

    Write-Log "Criando ip e nic"
    $publicIp = New-AzureRmPublicIpAddress -Name ($targetVirtualMachineName.ToLower()+'_ip') -ResourceGroupName $targetResourceGroupName -Location $targetLocation -AllocationMethod Dynamic -Force
    $nic = New-AzureRmNetworkInterface -Name ($targetVirtualMachineName.ToLower()+'_nic') -ResourceGroupName $targetResourceGroupName -Location $targetLocation -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id -Force

    Write-Log "Criando NSG"
    $rule1 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
    $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $targetResourceGroupName -Location $targetLocation -Name ($vnet.Name.ToLower()+'_NSG') -SecurityRules $rule1 -Force
    Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $targetSubnetName -AddressPrefix $targetSubnetPrefix  -NetworkSecurityGroup $nsg


    Write-Log "Criando VM"
    $VirtualMachine = New-AzureRmVMConfig -VMName $targetVirtualMachineName -VMSize $targetVirtualMachineSize
    $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
    New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $targetResourceGroupName -Location $targetLocation

    Write-Log "Processo de copia da VM concluído com sucesso!"

}
catch{
    Write-Log "Processo finalizado com erros: $($_.Exception.Message)" -DiretorioLog $DiretorioLog -Level Error
    Write-Error $_.Exeption.Message
}  