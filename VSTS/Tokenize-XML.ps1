
Param(
    [string]$filePath = "C:\scripts\trasform config\Web.config"
)
 
 
 
####################################################
function Get-XmlNodes {
    param ($inicialNode)
    
    $envVar = (Get-ChildItem env:*).GetEnumerator() | Sort-Object Name

    Foreach ($v in $envVar) {
             
        try {
            Write-Host "Verifing variable: $($v.Name)"
            $xpath = Format-xPath (Format-EnvVariable $v.Name) -isConnString $true

            Write-Host "xPath: $xpath"

            $node = $inicialNode.SelectSingleNode($xpath)     


            Write-Host $node

            $attribName = Get-AttribName -fullVariable $v.name

            $node.SetAttribute($attribName, $v.value )         
        }
        catch {
          
        }  
    }


}
####################################################

function Format-EnvVariable {
    param([string]$var)

    return $var.ToLower().Replace("_", ".")
}

####################################################
function Format-xPath {
    param (
        [string]$variable, 
        [bool]$isConnString,
        [bool]$isAppSettings     
    )

    if ($isConnString) {
        $attribName = "name"
    }
    elseif (condition) {
        $attribName = "key"
    }

    $attribValue = Get-AttribValue $variable
    $attribName = Get-AttribName $variable
    $attribFullName = Get-AttribFullName $variable

    return  "//$($attribFullName.Replace(".","/"))/add[lower-case(@$attribName)='$attribValue']"    
}
####################################################

####################################################
function Get-AttribValue {
    param([string]$fullVariable)

    $var = $fullVariable.Split(".")
     
    return $($var[$var.Count - 1])
}
####################################################


####################################################
function Get-AttribName {
    param([string]$fullVariable)
     
    #$fullVariable.Replace(".$(Get-AttribValue $fullVariable)", "")
    $var = $fullVariable.Split(".")
    
    return $($var[$var.Count - 2])
}
####################################################
function Get-AttribFullName {
    param([string]$fullVariable)
     
    $fullVariable.Replace(".$(Get-AttribValue $fullVariable)", "")
}
####################################################

[xml]$xmlFIle = Get-Content $filePath 
 
$nodes = $xmlFIle.ChildNodes
 
Get-XmlNodes $nodes


 
 
 
 