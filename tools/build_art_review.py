"""Create QA contact sheets from shipped sprites and actual native captures."""
from pathlib import Path
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]

def main():
    out=ROOT/'verification'
    for name in ['player_idle','player_walk','player_attack','player_dodge','player_death','mob_old_briar','mob_reedmother','mob_cinder_heart','mob_storm_stag','mob_atlas_keeper']:
        image=Image.open(ROOT/'godot/art/sprites'/f'{name}.png')
        image.resize((image.width*2,image.height*2),Image.Resampling.NEAREST).save(out/f'{name}_contact.png')
    for mode in ['player','creature','warden']:
        folder=out/'frames'/f'{mode}_normal'
        if not folder.exists():continue
        contact=Image.new('RGB',(1280,1080),'#102321')
        for index,number in enumerate([0,30,60,90,120,150]):
            frame=Image.open(folder/f'{number:04d}.png').convert('RGB').resize((640,360),Image.Resampling.NEAREST)
            if len(frame.getcolors(frame.width*frame.height) or [])<20:raise RuntimeError('Refusing a blank playback contact sheet')
            contact.paste(frame,((index%2)*640,(index//2)*360))
        contact.save(out/f'{mode}_normal_contact.png')
    print('Updated sprite and nonblank playback contact sheets.')

if __name__=='__main__':main()
