#Ao exportar o certificado, a senha é o nome da máquina acrescida de um sufixo

param(
    [Parameter(Mandatory=$true)]
    [string]$SufixoSenha,
    [Parameter(Mandatory=$true)]
    [string]$DiretorioCertificado,
    [Parameter(Mandatory=$true)]
    [string]$BuildServer
)
try
{
    $FQDN = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
    Write-Host "Gerando certificado para $FQDN...."

    Get-Command -Module PKI 
    
    $MyCert = New-SelfSignedCertificate  -DnsName $FQDN -CertStoreLocation cert:\LocalMachine\My 
    $thumbprint = $MyCert.Thumbprint.ToString()
    Write-Host "Certificado gerado: " $thumbprint

    Write-Host "Criando diretorio para exportacao..."
    if(-Not (Test-Path $DiretorioCertificado ))
    {
        New-Item -Path $DiretorioCertificado -ItemType Directory
    }

    Write-Host "Exportando chave do certificado...."
    Export-PfxCertificate -Cert cert:\LocalMachine\My\$thumbprint  -FilePath "$DiretorioCertificado\$env:computername.pfx" -Password ( ConvertTo-SecureString -String ($env:computername+$SufixoSenha) -Force –AsPlainText)
    
    try
    {

        Write-Host "Habilitando WinRM..."
        Enable-PSRemoting -Force

    }

    catch
    {
        Write-Host $_.Exception.Message
    }

    Write-Host "Adicionando build server a lista de servidores confiáveis..."
    Set-Item wsman:\localhost\client\trustedhosts $BuildServer

    Write-Host "Reiniciando servico WinRM..."
    Restart-Service WinRM 

    winrm create winrm/config/listener?Address=*+Transport=HTTPS "@{Hostname=`"$FQDN`";CertificateThumbprint=`"$thumbprint`"}"
}
catch
{
    Write-Host $_.Exception.Message
}