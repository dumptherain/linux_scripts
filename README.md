# Linux Scripts
A collection of bash scripts that speed up small everyday tasks for me working on CG/VFX jobs.

- [aration](#aratio)
- [exrtomp4](#exrtomp4)
- [mergeproes](#mergeprores)
- [mp4](#mp4)
- [smp4](#smp4)
- [prores422hq](#prores422hq)
- [prores422](#prores422)
- [exrarchive](#exrarchive)
- [grid3](#grid3)
- [monitor](#monitor)



## Requirements
- [ffmpeg](https://www.ffmpeg.org/)
- [imagemagick](https://imagemagick.org/index.php)
- [parallel](https://www.gnu.org/software/parallel/)
- [openimageio-tools](https://github.com/OpenImageIO/oiio)
- OCIO environment variable set

### Installation
For Debian-based Linux distributions, you can install these using the package manager apt:
`sudo apt-get install ffmpeg imagemagick parallel openimageio-tools`
For the OCIO environment variable, please refer to the documentation on how to [set environment variables in Linux](https://www.serverlab.ca/tutorials/linux/administration-linux/how-to-set-environment-variables-in-linux/).

### aratio
This command followed by the input video(s) to target will result in the most commonly to be delivered aspect ratios for online video media. The highest possible resolution from the given input video will be used.
- 1:1
- 4:5
- 16:9
- 9:16

### exrtomp4
Takes an .exr sequence in ACEScg color space in the current directory and converts it into an .mp4 with sRGB color space. This command defaults to 24 fps at the resolution of the images provided. The following flags can be used at the moment: 
- -fps 
- -res
Example:
`exrtomp4 -fps 30 -res 1080x1080`

### mergeproes
This is meant as a workaround for the nuke indie resolution limit. It takes two prores 444 files (`*_left.mov` + `*_right.mov`) in a current directory and merges them into a single prores 444 file, preserving the color space. 

### mp4
Takes any video files and converts them into compressed .mp4 files. The output is then moved into a folder named `mp4`.

### smp4
Takes any video files and converts them into compressed .mp4 files with a _small suffix in the same folder as the original.

### proress422hq
Takes any video files and converts them into .prores422hq files. The output is then moved into a folder named `prores422hq`.

### proress422
Takes any video files and converts them into .prores422 files. The output is then moved into a folder named `prores422hq`.

### exrarchive
Looks through all subfolders to find exr sequences and convert them from ACEScg into an sRGB .mp4 file. You will be shown a tree view off all subfolder. You can write the subfolders that should be ignored. When the script is done you can choose if you want to add all mp4 files into a new folder. If so just type in the name and it will create that folder and move the mp4's into it.

### grid3
This script takes all mp4 files in a current direcotory and makes 3x3 grids.

### monitor
this script opens up a tmux session with a split view of nvtop and btm to monitor your system during rendering.
