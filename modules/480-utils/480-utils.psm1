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
    Write-Host "Reading the path" $config_path
    $conf = $null
    if(Test-Path $config_path){
        Write-Host -ForegroundColor Green "Configuration found."
        $conf = (Get-Content -Raw -Path $config_path | ConnvertFrom-Json)
    }
    else{
        Write-Host -ForegroundColor Yellow "No configuration found."
    }
    return $conf
}