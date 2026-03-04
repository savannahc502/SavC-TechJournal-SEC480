#Load the Module
Import-Module '480-utils' -Force 

# Load Configurations from JSON File. Get-480Config is stored in 480-utils.psm1
$conf = Get-480Config -config_path "/home/savannah_loc/SavC-TechJournal-SEC480/480.json"

# Connecting to VCenter using the JSON value stored in vcenter_server
480_connect -server $conf.vcenter_server

# Select VM
Write-Host "Now selecting a VM from the folder $($conf.working_folder)"
Select-VM -folder $conf.working_folder

# List other Modules to Run. Comment out what's not needed
# 480_banner