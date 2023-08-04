# linux_scripts

This is a collection of bash scripts that speed up small everyday tasks for me working on cg/vfx jobs.

## requirements 
- ffmpeg
- imagemagick
- parallel (speeds up image conversion)
- OCIO environment variable set

### exrtomp4
Takes an exr. sequence in ACEScg color space in the current directory and converts it into an .mp4 with sRGB color space. 
This command defaults to 24 fps at 1920x1080. 
The following flags can be used atm: 
-fps 
-res

example:
exrtomp4 -fps 30 -res 1080x1080

### mergeproes 
This is meant as a workaround for the nuke indie resolution limit. 
It takes two prores 444 files *_left.mov + *_right.mov in a current directory and merges them into a single prores 444 file keeping color space. 

### mp4 
Takes any video files and converts them into compressed .mp4 files.
Then moves them into a folder called mp4

### proress422hq 
Takes any video files and converts it into .proress422hq files. 
Then moves them into a folder called proress422hq

### proress422
Takes any video files and converts it into .proress422 files. 
Then moves them into a folder called proress422hq
