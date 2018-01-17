<# This script will create a folder $baseLocation/Year/Month/6digitTicketnumber if the ticket folder is not created in last three months. 
The folder will be opened and put path folder will be added to windows clip-board(i.e "Ctl+v" will paste the full patch of the ticket.).
It can also list the file from Doanload Directory if any file contain the ticket number.
It will allow to copy the file to ticket directory just by intering index number of the file seprated by comma.
#>

cls
$a = 0
$base = 'c:\Tickets'
#$Logloc = "~\Downloads\"

# Collect Ticket number form User
Do{
$t = [regex]::Match((Read-Host -Prompt 'Ticket Number').Trim(),"\d{6}$")
if($t.length -eq 6) {
   "Processing:$t"
   break
   } Elseif($a -eq 0){
        "Can't find 6 digit ticket in your input.Try once more"
        } Else {
            $a = read-host -Prompt "Can't find 6 digit ticket in string. Press 'Enter' to exit"
            return
            }
$a=+1
}while("True")
# Acces the base location
Try{
    "Attempting to access P drive ..."
    cd "$base" -ErrorAction Stop
} Catch{   
    $a = read-host -Prompt "Can't access access $base. Press 'Enter' to exit"
    Return
}
# Open the ticket folder or create ticket file for current month
$pha = (Get-ChildItem -Path ((Get-Date).AddMonths(-2).ToString("yyyy/MM")),((Get-Date).AddMonths(-1).ToString("yyyy/MM")),((Get-Date).ToString("yyyy/MM")) -Directory | Where-Object {$_.Name -EQ "$t"})
Foreach ($ph in $pha){
 cd $ph.FullName
 explorer .
 Convert-Path . | Clip
  }
if (($Pha.Count -eq 0)) {
  New-Item -ItemType directory -Path ((Get-Date).ToString("yyyy/MM")+"/"+$t) -Force
  cd ((Get-Date).ToString("yyyy/MM")+"/"+$t)
  explorer . 
  Convert-Path . | Clip
} 

#Get the list of Files avaliable for download, and assign them to Hash Table.
 "`n Recent uploaded files are:"
 $Global:count = 1;
$file = (Get-ChildItem -Path "$Logloc"|Where-Object {$_.Name -like "$t*"} |
        Sort-Object LastWriteTime -Descending | 
        Select-Object Name,BaseName,@{ Name = "ID" ; Expression={$global:count; $global:count++}},Extension,@{ Name = "FileName" ; Expression={$_.name.Split('-',3)[-1]}},LastWriteTime,Attributes) 
$Global:count = 1;
# Show to user display.
 $file  | Select-Object @{ Name = "ID" ; Expression={$global:count; $global:count++}},@{ Name = "FileName" ; Expression={$_.name.Split('-',3)[-1]}}, LastWriteTime,Attributes | Format-Table | Out-Host

 # Read input from user to for logs they want to download
[array]$idf = (Read-host -prompt "Enter ID number to move (seprated with comma)").Split(",") |  %{$_.trim()}


    if ( $($idf.SyncRoot) -eq "" ){
    "Not copying any file"
	Read-Host "bye!"
    Return
    }

#Copy File from Archive location to Ticket folder and rename it.
Foreach ($i in ($idf)){
    $i = $i -1     
    if ( $i -ge 0  -and $i -le $($count-1)){
       write-Host -NoNewline "Copying $($file[$i].FileName) to $($ph.FullName) ..."
        Copy-Item $Logloc$($file[$i].Name) $($ph.FullName)
        Rename-Item $file[$i].Name $file[$i].FileName
		 "Done."
    } Else {  (($idf[$i]) + "is not a valid input")} 
}

Read-Host "bye!"