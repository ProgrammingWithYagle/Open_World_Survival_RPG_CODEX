"""Package actual engine captures into portable normal/slow playback reviews."""
import json
from pathlib import Path
import subprocess
import sys
from PIL import Image,ImageStat

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
import imageio_ffmpeg

def main():
    ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
    videos=[]
    for folder in sorted((ROOT/'verification/frames').iterdir()):
        if not folder.is_dir():continue
        frames=list(folder.glob('*.png'))
        if len(frames)!=180:raise ValueError(f'{folder.name}: incomplete capture ({len(frames)}/180 frames)')
        for frame in [frames[0],frames[len(frames)//2],frames[-1]]:
            if max(ImageStat.Stat(Image.open(frame).convert('RGB')).stddev)<5:raise ValueError(f'{folder.name}: blank or nearly uniform capture {frame.name}')
        output=ROOT/'verification'/(folder.name+'.mp4')
        subprocess.run([ffmpeg,'-hide_banner','-loglevel','error','-y','-framerate','30','-i',str(folder/'%04d.png'),'-c:v','libx264','-crf','15','-pix_fmt','yuv420p','-movflags','+faststart',str(output)],check=True)
        videos.append({'file':output.name,'frames':len(frames),'seconds':6,'source':'Godot 4.5.1 native Compatibility renderer','speed':.25 if 'slow' in folder.name else 1})
        print(output)
    (ROOT/'verification/animation_playback_manifest.json').write_text(json.dumps(videos,indent=2)+'\n')

if __name__=='__main__':main()
