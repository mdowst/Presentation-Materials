# Get the latest version of the agent script
find -type f -name 'onboard_agent.sh' -exec rm -f {} \;
wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh
 
# Uninstall Existing Agent (Skip if new install)
sudo sh onboard_agent.sh --purge
 
# Rename the worker configuration files (Skip if new install)
mv -f /home/nxautomation/state/worker.conf /home/nxautomation/state/worker.conf_old
mv -f /home/nxautomation/state/worker_diy.crt /home/nxautomation/state/worker_diy.crt_old
mv -f /home/nxautomation/state/worker_diy.key /home/nxautomation/state/worker_diy.key_old

# Remove from Automation Account through PowerShell of Portal

# Reinstall Agent
sudo sh onboard_agent.sh -w <WorkspaceID> -s <WOrkspaceKey> -d opinsights.azure.com
