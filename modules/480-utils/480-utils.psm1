function 480_banner()
{
    Write-Host "Hello 480 Besties!"
}

function 480_connect([string] $server)
{
    $connect = $global:DefaultVIServer
    if ($connect){
        $msg = "Already connected to: {0}" -f $connect
        Write-Host -ForegroundColor Green $msg
    }else {
        $connect = Connect-VIServer -Server $server
    }
}

function Get-480Config([string] $config_path)
{
    Write-Host "Reading Configurations"
    $conf = $null
    if(Test-Path $config_path){
        Write-Host -ForegroundColor "green" "Configuration found."
        $conf = (Get-Content -Raw -Path $conf_path | ConnvertFrom-JSON)
    }
    else{
        Write-Host -ForegroundColor "yellow" "No configuration found."
    }
    return $conf
}