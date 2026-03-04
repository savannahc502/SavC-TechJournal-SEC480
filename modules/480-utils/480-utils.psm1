function 480_banner()
{
    Write-Host "Hello 480 Besties!"
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
    Write-Host "Reading Configurations"
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

function Select-VM([string] $folder)
{
    $select_vm = $null
    try
    {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.Name
            $index += 1
        }
        $pick_index = Read-Host "Which index number do you wish to pick?"
        if($pick_index -ge 1 -and $pick_index -le $vms.Count){
            $select_vm = $vms[$pick_index -1]
            Write-Host ""
            Write-Host "You selected " $select_vm.Name -ForegroundColor "Green"
            return $select_vm
        }else{
            Write-Host ""
            Write-Host "Invalid input. Try again." -ForegroundColor "Yellow"
        }
    }
    catch {
        Write-Host ""
        Write-Host "Invalid Folder: $folder" -ForegroundColor "Red"
    }
}
