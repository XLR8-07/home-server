# SSH Connection to Linux
sudo apt install -y openssh-server
sudo systemctl start ssh

# Disable a Server from sleeping
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target


#First create a rclone config and ensure that the mount is working fine
#Verify the mount
#Config Jellyfin with the mount