# Linux Scripts

A collection of small scripts used to speed up everyday CG/VFX work on Linux. They cover video conversion, EXR sequence processing, file management and various utility tasks.

## Requirements
- [ffmpeg](https://www.ffmpeg.org/)
- [ImageMagick](https://imagemagick.org/index.php)
- [GNU parallel](https://www.gnu.org/software/parallel/)
- [OpenImageIO tools](https://github.com/OpenImageIO/oiio)
- OCIO environment variables

### Installation
For Debian based distributions install the dependencies via apt:

```bash
sudo apt-get install ffmpeg imagemagick parallel openimageio-tools
```

Set the OCIO environment variable according to your colour configuration.

## Script Overview
Scripts are grouped roughly by purpose. Most of them are simple shell utilities and can be run from any directory once the repo is on your `PATH`.

### Video Conversion & Encoding
- **aratio.sh** – crop a video into 1:1, 4:5, 16:9 and 9:16 versions.
- **aratio_high.sh** – high quality variant of `aratio.sh` using slower encoding settings.
- **exrtomp4.sh** – convert an ACEScg EXR sequence to an sRGB MP4.
- **exrtoprores422.sh** – convert an EXR sequence to ProRes 422.
- **exrtoprores444.sh** – convert an EXR sequence to ProRes 444.
- **movtoexr.sh** – turn a video file into a DWAB compressed EXR sequence.
- **mkv_mov.sh** – convert an MKV into a ProRes 422 MOV file.
- **mp4.sh** / **mp4hq.sh** – convert videos to MP4 (standard or high quality).
- **smp4.sh** – create a smaller MP4 in the same folder.
- **prores422hq.sh** – encode videos as ProRes 422 HQ.
- **prores444.sh** – encode videos as ProRes 444.
- **webmp4.sh** / **webmp4_smaller.sh** – create web friendly MP4s.
- **pngtomp4.sh** – stitch a PNG sequence into an MP4.
- **mp4topng.sh** – extract frames from a video as PNGs.
- **mp4towav.sh** – extract a WAV track from an MP4.
- **videotomp3.sh** – convert a video to MP3 audio.
- **videotojpg.sh** / **videotopng.sh** – convert a video to an image sequence.
- **videototxt.sh** – convert a video to MP3 and transcribe it using Whisper.

### Sequence and Image Tools
- **exrarchive.sh** – scan subfolders for EXR sequences and convert them to MP4.
- **exrmerge.sh** – merge `_l.exr` and `_r.exr` images into a single file.
- **exrtojpg.sh** – convert a single EXR to JPG.
- **exrtotiff.sh** – convert a single EXR to TIFF.
- **exrtotiff_ProPhotoRGB.sh** – create a gamma encoded ProPhoto RGB TIFF from an EXR.
- **extractstills.sh** / **autocut.sh** – grab still frames from a video based on a sensitivity setting.
- **extractallstills.sh** – run `extractstills.sh` across an entire directory tree.
- **pngtomp4.sh** – convert PNG sequences to MP4.
- **thumbnail.sh** and **.thumbnail.sh** – extract specific or first frames as thumbnails.
- **montage.sh**, **montage4.sh**, **montage6.sh** – build mosaics from numbered EXR frames.

### Video Editing Utilities
- **joinvideo.sh** / **videomerge.sh** – concatenate multiple videos into one.
- **mergeprores.sh** / **mergeprores2.sh** – merge left/right ProRes clips side by side.
- **grid3.sh** and **grid3_backup.sh** – generate 3×3 grid videos from MP4s.
- **grid_play.sh** – launch multiple videos in a grid layout using mpv.
- **trim.sh** – trim frames from the start or end of a video.
- **record.sh** – desktop + webcam recorder with optional live preview.
- **hdri.sh** – run the DiffusionLight HDRI generation pipeline.

### GIFs and Watchers
- **gif.sh** and **gif_small.sh** – create GIFs from videos (normal or smaller).
- **watch_convert_to_gif.sh** – watch a folder and automatically convert new videos to GIF.
- **watch_move_videos.sh** – monitor a folder and move incoming videos to a subdirectory.

### Audio and Transcription
- **applyaudio.sh** – attach the same audio track to multiple videos.
- **noaudio.sh** – remove the audio stream from a video file.
- **mp4towav.sh** and **videotomp3.sh** – extract audio tracks.
- **transcribe.sh** – run Whisper on an audio file.
- **formatjson.sh** and **formattxt.sh** – helper scripts to clean up Whisper output.
- **rft_to_txt.sh** – convert RTF documents to plain text.

### Desktop & System Utilities
- **date.sh** – create a directory named after today’s date.
- **project_folder.sh** – create a standard project folder hierarchy.
- **folder.sh** – build directories from an indented tree listing.
- **clean.sh** – recursively remove temporary folders named `tmp*`.
- **htmlpreview.sh** – generate a simple HTML gallery for selected files.
- **open_clipboard.sh** – open a path or image sequence from the clipboard.
- **chatid.sh** – get the last chat ID from a Telegram bot.
- **monitor.sh** / **monitor2.sh** / **mm.sh** – system monitoring helpers using tmux.
- **obs_copy.sh** – automatically copy new OBS recordings to dated folders.
- **syncblender.sh** – rsync Blender configuration to a remote host.
- **set_wacom.sh**, **wacom1.sh**, **wacom2.sh**, **wacom3.sh** – map a Wacom tablet to various monitor setups.
- **sine.sh** – toggle an audible test tone.
- **deadline_env_mint.sh** – wrapper to start Deadline with custom library paths.

### Desktop Integration
- **create_desktop.sh** – create KDE service menu files for scripts.
- **deploy_desktop_files.sh** – install the `.desktop` files from `desktop_files/`.
- **desktop_files/** – example service menu entries used with Dolphin/Nemo.

### Python GUI
- **batchexrtomp4.py** – a Tkinter application to batch convert EXR sequences to various formats.

## Usage
Most scripts are self‑contained. Place this repository somewhere in your `PATH` or call the scripts with their full path. Read each script for exact options – many accept command line flags to tweak behaviour.

