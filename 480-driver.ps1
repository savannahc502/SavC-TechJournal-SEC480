# // Load VMware PowerCLI and Module //
Write-Host "Importing PowerCLI and 480-utils Modules" -ForegroundColor Magenta
Import-Module VMware.PowerCLI
Import-Module '480-utils' -Force 

# // Load Configurations from JSON File. Get-480Config is stored in 480-utils.psm1 //
$conf = Get-480Config -config_path "/home/savannah_loc/SavC-TechJournal-SEC480/480.json"

# // Banner //
480_banner

# // Connecting to VCenter using the JSON value stored in vcenter_server //
480_connect -server $conf.vcenter_server

# // 480 Main Menu //
while ($true) {
    Write-Host ""
    Write-Host "          480 MENU            " -ForegroundColor Magenta
    Write-Host "1) Create a New Network"
    Write-Host "2) Clone a VM"
    Write-Host "3) Get the IP and MAC of a VM"
    Write-Host "4) Start or Stop VM"
    Write-Host "5) Set a Network Adapter"
    Write-Host "6) Exit"
    Write-Host ""

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "Create a New Network..." -ForegroundColor Magenta
            New-Network -conf $conf
        }
        "2" {
            Write-Host ""
            Write-Host "Create a New VM..." -ForegroundColor Magenta
            New-480Clone -conf $conf
        }
        "3" {
            Write-Host ""
            Write-Host "Get the IP and MAC of a VM..." -ForegroundColor Magenta
            Get-IP
        }
        "4" {
            Write-Host ""
            Write-Host "Start or Stop a VM..." -ForegroundColor Magenta
            StartStop-Box
        }
        "5" {
            Write-Host ""
            Write-Host "Set a network adapter..." -ForegroundColor Magenta
            Set-Network
        }
        "6" {
            Write-Host ""
            Write-Host "Exiting Program" -ForegroundColor Magenta
            exit
        }

        default {
            Write-Host ""
            Write-Host "Invalid selection. Try again." -ForegroundColor Red
        }
    }
}
