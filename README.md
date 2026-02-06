# VidSub-Automator 🎬

Today I needed to add subtitles to a video file, and I thought of the struggles: if I change devices, I need to add them again; I cannot easily share them with friends because they'll need to manually add subs later. I created this to make the process a "no-brainer."

VidSub-Automator is a set of PowerShell scripts using FFmpeg to permanently integrate subtitles or combine series episodes into a single master file.

## ✨ Key Features

- **Session-Based Subtitle Adding**: Choose between **MUX** (instant, preserves styles in MKV) or **BURN** (permanent hardcoding in MP4) once, then process your whole series in a loop.
- **Smart Muxing**: Automatically uses the MKV container to prevent common formatting errors like `\{{}=6\}` in advanced subtitle styles.
- **Selective Series Joiner**: Choose exactly which episodes to merge.
- **Safety First**: Includes a **Resolution Check** to prevent glitches when combining files of different sizes.
- **No Quality Loss**: Uses stream copying (`-c copy`) for muxing and joining to keep original video quality.

## 🚀 Installation & Setup

1. Install [FFmpeg](https://www.gyan.dev/ffmpeg/builds/) and add it to your System PATH.
2. Clone this repo or download the scripts.
3. Run `Run_Merge.bat` to add subtitles.
4. Run `Run_Combine.bat` to join multiple episodes.

## 🛠️ Contributing

If you're a developer who loves automation, feel free to fork this repo and submit a PR! I'm specifically looking to add a "Time Remaining" estimator for the Burn process.

## 📜 License

This project is licensed under the MIT License.
