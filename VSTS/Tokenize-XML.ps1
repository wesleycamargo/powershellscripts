
Param(
    [string]$filePath = "C:\scripts\trasform config\Web.config",
    $hashtable1 = @{Name1 = "Value1"; Name2 = "Value2"}
)
 
 
#$var = (Get-ChildItem env:*).GetEnumerator() | Sort-Object Name
#$out = ""
#
#Foreach ($v in $var) 
#{
#    $out = $out + "`t{0,-28} = {1,-28}`n" -f $v.Name, $v.Value
#
#
#
#    $no = "$xmlFIle"
#
#    if($no)
#    {
#        Write-Host "existe"
#    }
#    else
#    {
#        Write-Host "nao existe" 
#    }
#
#}
 
 
####################################################
 
function Get-XmlNodes {
    param ($inicialNode)
    
    $var = "configuration.connectionStrings.ConectSysConnStr"

    $envVar = (Get-ChildItem env:*).GetEnumerator() | Sort-Object Name

    $envVar.Add($var,"teste")

    Foreach ($v in $envVar) {
        
        $xpath = Format-xPath $v.Name -isConnString $true
        $node = $inicialNode.SelectSingleNode($xpath)     

        $attribName = Get-AttribName -fullVariable $v.name

        $node.SetAttribute($attribName, $v.value )        
    }
}

####################################################

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

    return  "//$($attribName.Replace(".","/"))/add[@$attribName='$attribValue']"    
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
     
    $fullVariable.Replace(".$(Get-AttribValue $fullVariable)", "")
}
####################################################


[xml]$xmlFIle = Get-Content $filePath 
 
$nodes = $xmlFIle.ChildNodes
 
Get-XmlNodes $nodes
 
 
 
 