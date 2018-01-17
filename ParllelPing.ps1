<#
This pull the list ip fro $ipa file and . Start concurren continous ping on all ip and wite the output in file $locn\output
On the Powershell windows, "Press eneter to continue show". Once enter is pressed, all PING process will be killed.  

#>

cls
$ips= Get-Content "c:\tmp\ips.txt"
$ips
$locn= "c:\tmp\"
cd $locn
New-Item outPut -ItemType Directory -EA SilentlyContinue
Set-Location $locn"outPut"

$runspacepool =  [RunSpaceFactory]::CreateRunspacePool(1,10)
$runspacepool.ApartmentState = "MTA"
$runspacepool.open()

$codeContainer = {
    param (
            [string] $ipAddr
            )
            $FileName = Get-Date -Format yyMMddHHmmss
            filter timestamp {"$(Get-Date -Format o): $_"}
            $pingst= ping $ipAddr -t | timestamp | Out-File c:\tmp\outPut\"$FileName"_"$ipAddr"_p.txt -Force
            return $pingst
}

$threads = @()

foreach ($i in $ips)
{ 
    $runspaceObject = [PSCustomObject] @{
        Runspace = [PowerShell]::Create()
        Invoker= $null
    }
    $runspaceObject.Runspace.RunSpacePool = $runspacepool
    $runspaceObject.Runspace.AddScript($codeContainer) | Out-Null
    $runspaceObject.Runspace.AddArgument($i)| Out-Null
    $runspaceObject.Invoker = $runspaceObject.Runspace.BeginInvoke()
    $threads += $runspaceObject

    Write-Output "Finished creating runspace for $i"
}
#Get-Process PING
pause
kill -ProcessName PING -Force
while ($threads.Invoker.IsCompleted -contains $false){}
Write-Output "All completed"

$threadResult = @()
ForEach($t in $threads)
{
    $threadResult += $t.Runspace.EndInvoke($t.Invoker)
    $t.Runspace.Dispose()
}

$runspacepool.Close()
$runspacepool.Dispoer
