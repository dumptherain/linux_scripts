# Linux Scripts
A collection of bash scripts that speed up small everyday tasks for me working on CG/VFX jobs.

- [exrtomp4](#exrtomp4)
- [mergeproes](#mergeprores)
- [mp4](#mp4)
- [prores422hq](#prores422hq)
- [prores422](#prores422)

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

### proress422hq
Takes any video files and converts them into .prores422hq files. The output is then moved into a folder named `prores422hq`.

### proress422
Takes any video files and converts them into .prores422 files. The output is then moved into a folder named `prores422hq`.

