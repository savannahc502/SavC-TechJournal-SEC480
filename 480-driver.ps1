# // Load VMware PowerCLI and Module //
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
    Write-Host "          480 MENU            " -ForegroundColor Cyan
    Write-Host "1) Create a New Network"
    Write-Host "2) Clone a VM"
    Write-Host "3) Get the IP and MAC of a VM"
    Write-Host "4) Exit"
    Write-Host ""

    $choice = Read-Host "Enter your choice (1-4)"

    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "// Create a New Network //" -ForegroundColor Yellow
            New-Network -conf $conf
        }
        "2" {
            Write-Host ""
            Write-Host "// Create a New VM //" -ForegroundColor Yellow
            New-480Clone -conf $conf
        }
        "3" {
            Write-Host ""
            Write-Host "// Get the IP and MAC of a VM //" -ForegroundColor Yellow
            Get-IP
        }
        "4" {
            Write-Host ""
            Write-Host "// Exiting Program //" -ForegroundColor Green
            break
        }

        default {
            Write-Host ""
            Write-Host "Invalid selection. Try again." -ForegroundColor Red
        }
    }
}
