# Author: Savannah Ciak
# Date: 2/23/2026
# Description: Creates a Linked or Full VM Clone
# Consultants: Lily Pouliot and Natlie Eckles 
# Revision provided by Copilot with prompt "Make sure code is logical and would work as intended. Point out any flaws for correction."

Write-Host ""
get-vm
Write-Host ""

$ClonedVM = Read-Host "Enter the name of the VM that you want to be cloned"
$Name = Read-Host "Enter the name that you want for the new VM"
$Type = Read-Host "Full or Linked Clone? 'F' for full clone or 'L' for linked clone"

$vm = Get-VM -Name $ClonedVM
$snapshot = Get-Snapshot -vm $vm -Name "Base"
$vmhost = Get-VMHost -Name "192.168.3.203"
$ds = Get-Datastore -Name "datastore2"

If ($Type -eq "F"){
        $linkedName = "{0}.linked" -f $vm.name
        $linkedvm = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
        $newvm = New-VM -Name $Name -VM $linkedvm -VMHost $vmhost -Datastore $ds
        $newvm | new-snapshot -Name "Base"
        $linkedvm | Remove-VM -Confirm:$false
        Move-VM -VM $newvm -InventoryLocation (Get-Folder -Name "BASE VMs")
        }
Elseif ($Type -eq "L"){
        $linkedvm = New-VM -LinkedClone -Name $Name -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
        $linkedvm | new-snapshot -Name "Base"
        Move-VM -VM $linkedvm -InventoryLocation (Get-Folder -Name "LINKED VMs")
        }
else {
        write-host "That selection does not exist. Please re-run the program. Program ending."
        }
