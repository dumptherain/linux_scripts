# Sync to /home/pscale/.config/blender on the remote machine
rsync -avz /home/pscale/.config/blender/ node@192.168.8.134:/home/pscale/.config/blender

# Sync to /home/node/.config/blender on the remote machine
rsync -avz /home/pscale/.config/blender/ node@192.168.8.134:/home/node/.config/blender
