# // Load the Module // 
Import-Module '480-utils' -Force 

# // Load Configurations from JSON File. Get-480Config is stored in 480-utils.psm1 //
$conf = Get-480Config -config_path "/home/savannah_loc/SavC-TechJournal-SEC480/480.json"

# // Banner //
480_banner

# // Connecting to VCenter using the JSON value stored in vcenter_server //
480_connect -server $conf.vcenter_server

# // Select VM //
# Write-Host ""
# Write-Host "Now selecting a VM from the folder $($conf.working_folder)"
# Select-VM -folder $conf.working_folder

# // Create a New VM //
# New-480Clone -conf $conf

# // Create a new Network //
New-Network -conf $conf

# // Get the IP and MAC of a VM //
Get-IP