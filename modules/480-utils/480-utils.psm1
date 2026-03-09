function 480_banner()
{
    Write-Host "Hello 480 Besties!" -ForegroundColor Magenta
}

function 480_connect([string] $server)
{
    $connect = $global:DefaultVIServer
    if ($connect){
        $msg = "Already connected to: {0}" -f $connect
        Write-Host ""
        Write-Host -ForegroundColor Green $msg
    }else {
        $connect = Connect-VIServer -Server $server
    }
}

function Get-480Config([string] $config_path)
{
    Write-Host ""
    Write-Host "Reading Configurations" -ForegroundColor Blue
    $conf = $null
    if (Test-Path $config_path) {
        Write-Host -ForegroundColor Green "Configuration found."
        $conf = Get-Content -Raw -Path $config_path | ConvertFrom-Json
    }
    else {
        Write-Host -ForegroundColor Yellow "No configuration found."
    }
    return $conf
}

function Select-VM()
{
    Write-Host ""
    Write-Host "Browse and Select a VM" -ForegroundColor Blue
    
    # Get all folders
    $folders = Get-Folder | Where-Object { $_.Type -eq "VM" }
    if (-not $folders) {
        Write-Host "No VM folders found." -ForegroundColor Red
        return
    }

    # Display folders
    Write-Host ""
    Write-Host "Available VM Folders:" -ForegroundColor Blue
    $index = 1
    foreach ($f in $folders) {
        Write-Host "[$index] $($f.Name)"
        $index++
    }

    # Pick Folder
    $folderChoice = Read-Host "Select a folder by number"
    if ($folderChoice -lt 1 -or $folderChoice -gt $folders.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return
    }

    $selectedFolder = $folders[$folderChoice - 1]
    Write-Host ""
    Write-Host "You selected folder: $($selectedFolder.Name)" -ForegroundColor Green

    # Get VMs inside the selected folder
    $vms = Get-VM -Location $selectedFolder
    if (-not $vms) {
        Write-Host "No VMs found in this folder." -ForegroundColor Red
        return
    }

    # Display VMs
    Write-Host ""
    Write-Host "Available VMs:" -ForegroundColor Cyan
    $vmIndex = 1
    foreach ($vm in $vms) {
        Write-Host "[$vmIndex] $($vm.Name)"
        $vmIndex++
    }

    # Pick a VM
    $vmChoice = Read-Host "Select a VM by number"
    if ($vmChoice -lt 1 -or $vmChoice -gt $vms.Count) {
        Write-Host "Invalid VM selection." -ForegroundColor Red
        return
    }

    $selectedVM = $vms[$vmChoice - 1]
    Write-Host ""
    Write-Host "You selected VM: $($selectedVM.Name)" -ForegroundColor Green
    return $selectedVM
}

function New-480Clone([PSCustomObject]$conf)
{
    # Select the source VM from the folder defined in JSON. 
    # Select-VM function lists VMs and lets the user pick by index number.
    Write-Host ""
    Write-Host "Clone an existing VM from its base snapshot..." -ForegroundColor Blue
    $vm = Select-VM -folder $conf.working_folder

    # Stop if no VM was selected
    if (-not $vm) {
        Write-Host "No VM selected. Try again." -ForegroundColor Red
        return
    }

    # Ask user for the new clone name.
    $CloneName = Read-Host "Enter the name for the new clone"

    # Ask user for clone type and normalize input to uppercase for easy comparison.
    $CloneType = Read-Host "Clone type: 'F' for Full or 'L' for Linked"
    $CloneType = $CloneType.Trim().ToUpper()

    # Resolve config values using ?? fallback. 
    # If the JSON contains the value, use it. Otherwise, it prompts the user for input.
    $SnapshotName = $conf.snapshot ?? (Read-Host "Enter snapshot name")
    $VmHostName   = $conf.vm_host ?? (Read-Host "Enter ESXi host name")
    $Datastore    = $conf.datastore ?? (Read-Host "Enter datastore name")
    $BaseFolder   = $conf.base_folder ?? (Read-Host "Enter BASE folder name")
    $OutputFolder = $conf.output_folder ?? (Read-Host "Enter output folder name") 
    $NetworkName  = $conf.default_network ?? (Read-Host "Enter network/portgroup name")

    # Validate snapshot, host, and datastore.
    try { $snapshot = Get-Snapshot -VM $vm -Name $SnapshotName -ErrorAction Stop }
    catch { Write-Host "Snapshot '$SnapshotName' not found." -ForegroundColor Red; return }

    try { $vmhost = Get-VMHost -Name $VmHostName -ErrorAction Stop }
    catch { Write-Host "Host '$VmHostName' not found." -ForegroundColor Red; return }

    try { $ds = Get-Datastore -Name $Datastore -ErrorAction Stop }
    catch { Write-Host "Datastore '$Datastore' not found." -ForegroundColor Red; return }

    # A full clone must be created from a temporary linked clone.
    if ($CloneType -eq "F") {
        Write-Host " "
        Write-Host "Creating temporary linked clone..." -ForegroundColor Cyan
        $TempName = "{0}.linked.tmp" -f $vm.Name   # Name for temporary linked clone

        # Create temporary linked clone from base snapshot.
        $linkedvm = New-VM -LinkedClone -Name $TempName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

        Write-Host "Converting to full clone '$CloneName'..." -ForegroundColor Cyan

        # Create full clone from temporary linked clone.
        $newvm = New-VM -Name $CloneName -VM $linkedvm -VMHost $vmhost -Datastore $ds

        # Apply network settings from JSON.
        $newvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $NetworkName -Confirm:$false

        # Snapshot the new full clone so it matches the base snapshot.
        $newvm | New-Snapshot -Name $SnapshotName | Out-Null

        # Remove temporary linked clone. If removal fails, warn the user.
        try { $linkedvm | Remove-VM -Confirm:$false }
        catch { Write-Host "Warning: Could not remove temporary clone." -ForegroundColor Yellow }

        # Move full clone into BASE folder.
        Move-VM -VM $newvm -InventoryLocation (Get-Folder -Name $OutputFolder)

        Write-Host "Full clone '$CloneName' created successfully." -ForegroundColor Green
        return
    }

    # Direct linked clone from base snapshot.
    if ($CloneType -eq "L") {
        Write-Host " "
        Write-Host "Creating linked clone '$CloneName'..." -ForegroundColor Cyan

        # Create linked clone directly from base snapshot.
        $linkedvm = New-VM -LinkedClone -Name $CloneName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

        # Apply network settings.
        $linkedvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $NetworkName -Confirm:$false

        # Move linked clone into output folder.
        Move-VM -VM $linkedvm -InventoryLocation (Get-Folder -Name $OutputFolder)

        Write-Host "Linked clone '$CloneName' created successfully." -ForegroundColor Green
        return
    }

    # Invalid clone type entered by the user.
    Write-Host "Invalid selection. Must be 'F' or 'L'." -ForegroundColor Red
}

function New-Network([PSCustomObject] $conf){
    Write-Host ""
    Write-Host "Create a New Network..." -ForegroundColor Blue
    $net_name = Read-Host "Enter the name for your new network"

    # Get ESXi IP
    $vmhost = Get-VMHost -Name $conf.vm_host

    # Check if Network Name already exists
    $existingSwitch = Get-VirtualSwitch -VMHost $vmhost -Name $net_name -ErrorAction SilentlyContinue
    if ($existingSwitch) {
        Write-Host "A vSwitch named '$net_name' already exists on host $($conf.vm_host)." -ForegroundColor Yellow
        Write-Host "Exiting without making changes."
        return
    }

    # Check if Port Group already exists
    $existingPG = Get-VirtualPortGroup -VMHost $vmhost -Name $net_name -ErrorAction SilentlyContinue
    if ($existingPG) {
        Write-Host "A Port Group named '$net_name' already exists on host $($conf.vm_host)." -ForegroundColor Yellow
        Write-Host "Exiting without making changes."
        return
    }

    # Create the network and port group 
    $vSwitch = New-VirtualSwitch -VMHost $vmhost -Name $net_name
    New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $net_name
    Write-Host "Network '$net_name' created successfully." -ForegroundColor Green
}


function Get-IP()
{
    Write-Host ""
    Write-Host "Retrive IP and MAC Address from the first interface of a VM..." -ForegroundColor Blue
    
    # Get the VM name and check its existence
    $vmName = Select-VM
    try {
        $vm = Get-VM -Name $vmName -ErrorAction Stop
    }
    catch {
        Write-Host "VM $vmName not found. Try again." -ForegroundColor Red
        return
    }

    # Get the first network adapter and check its existence
    $adapter = $vm | Get-NetworkAdapter | Select-Object -First 1
    if (-not $adapter){
        Write-Host "No network adapters found on the VM." -ForegroundColor Yellow
        return
    }

    # Get the MAC and IP
    $mac = $adapter.MacAddress
    $ip = $vm.Guest.IPAddress

    # If there's multiple IPs, select the first
    if ($ip -is [array]){
        $ip = $ip[0]
    }

    # If there's no IP, tell the user 
    if (-not $ip){
        Write-Host "No IP addresses found" -ForegroundColor Yellow
    }

    # Final information
    Write-Host ""
    Write-Host "VM Name: $vmName" -ForegroundColor Green
    Write-Host "Mac Address: $mac" -ForegroundColor Green
    Write-Host "IP Address: $ip" -ForegroundColor Green
}

