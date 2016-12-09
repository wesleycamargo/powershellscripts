#O Script considera que a senha do certificado é o nome da máquina acrescido de um sufixo.

param(
    [Parameter(Mandatory=$true)]
    [string]$DiretorioCertificados,
    [Parameter(Mandatory=$true)]
    [string]$SufixoSenha
)

function Get-Password($nomeCertificado)
{
    return ( ConvertTo-SecureString -String ($nomeCertificado.Replace(".pfx","")+$SufixoSenha) -Force –AsPlainText)     
}

try
{
    Get-Command -Module PKI 
    
    $certificados = Get-ChildItem $DiretorioCertificados *.pfx 

    foreach($certificado in $certificados)
    {
        Import-PfxCertificate -FilePath $certificado.FullName cert:\localMachine\my -Exportable -Password (Get-Password -nomeCertificado $certificado.Name)
    }
}
catch
{
    Write-Host $_.Exception.Message
}

