Param(
   [string]$vstsAccount,   
   [string]$user,
   [string]$token,
   [string]$outputDir = "c:\scripts\"   
)

Write-Verbose "Parameter Values"
foreach($key in $PSBoundParameters.Keys)
{
     Write-Verbose ("  $($key)" + ' = ' + $PSBoundParameters[$key])
}
 
# Base64-encodes the Personal Access Token (PAT) appropriately
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
 

#obtem uma lista de team projects
$uri = "https://$($vstsAccount).visualstudio.com/DefaultCollection/_apis/projects?api-version=1.0"
# Invoke the REST call and capture the results
$projects = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} 

$listaUsuarios = New-Object System.Collections.ArrayList($null)

foreach($project in $projects.value)
{
    #obtem uma lista de times
    $uri = "https://$($vstsAccount).visualstudio.com/DefaultCollection/_apis/projects/$($project.id)/teams?api-version=2.2"
    $teams = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} 
    
    foreach($team in $teams.value)
    {        
        $uri = "https://$($vstsAccount).visualstudio.com/DefaultCollection/_apis/projects/$($project.id)/teams/$($team.id)/members/?api-version=2.2"
        $members = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} 
        
        foreach($member in $members.value)
        {
            $usuario = [PSCustomObject]@{
                TeamProject = $project.name
                Team = $team.name
                Nome = $member.displayName
                usuarioAD = $member.uniqueName
                }

            Write-Host "Adicionando usuario $($usuario.Nome) | $($usuario.TeamProject)"
            $listaUsuarios.Add($usuario)    
        }       
    }
}

Write-Host "Criando diretorio $outputDir"
mkdir $outputDir -Force

Write-Host "Criando arquivo csv"
$listaUsuarios | Export-Csv "$outputDir\userslist.csv" -Force

Write-Host "Arquivo $outputDir\userslist.csv criado com sucesso!"