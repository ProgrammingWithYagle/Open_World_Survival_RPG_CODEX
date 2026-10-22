"""Deterministic sprite slicing, shared-scale normalization and atlas packing.

This is asset preparation, not a replacement for image generation. All illustrated
content comes from the original raw images; rejected artwork is never painted over.
"""
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'godot/art'
RAW=ART/'source'
GENERATED=Path(r'C:\Users\yigal\.codex\generated_images\01a1614d-ed62-7fc3-86f6-c16240062532')
FILES={
 'surveyor_concept.png':'exec-3ff26269-0a18-475b-a68d-a58ae396d308.png',
 'surveyor_walk.png':'exec-72505d61-a80a-43c1-893d-8bc193defe6d.png',
 'surveyor_idle.png':'exec-0fc2dc31-4dfa-446b-9fd0-80f73695b0a1.png',
 'surveyor_attack.png':'exec-f1d90171-18c0-434f-b30d-f61476f80e22.png',
 'surveyor_dodge.png':'exec-ae351a8e-d62b-4c61-90dd-242f030330c7.png',
 'settlement_structures.png':'exec-52d4f175-6c14-46bd-8aba-74e74a728df0.png',
 'bracken_creatures.png':'exec-bc959642-b92f-4821-93bd-26e382775fe7.png',
 'fen_creatures.png':'exec-88432344-5d29-4bb5-bc52-6bdac3984438.png',
 'reedmother_revised.png':'exec-d3bd7626-f4d6-4473-ab9f-29e1da89afb0.png',
 'cinder_creatures.png':'exec-37e75ebf-cc35-452f-b7fb-ea82fa1ecb51.png',
 'storm_creatures.png':'exec-e90025e6-4e45-4bff-af2d-0133240b7741.png',
 'hollow_creatures.png':'exec-bc3af977-7dba-4413-ab1c-3c885818c22f.png',
 'surveyor_death.png':'exec-108bfb50-b1b5-4387-9656-bd43840348d0.png',
 'equipment_icons.png':'exec-8ac1bbcd-eece-4ebb-85cf-562c901aba14.png',
 'supply_icons.png':'exec-984f4031-f411-44db-b405-4b826671c004.png',
 'regional_landmarks.png':'exec-decf4842-6422-4608-b002-a92a0fa0fc78.png',
 'extended_provision_icons.png':'exec-37d341d0-706e-48b1-8e25-5aed306f2bab.png',
 'garden_growth.png':'exec-d6ff7ceb-34fc-4a40-9734-f6cafc09ed7b.png',
 'floor_surfaces.png':'exec-fa41f6b2-55b0-4760-a42b-bd33a1324240.png',
 'grain_provisions.png':'exec-f385c7a8-6a0a-4309-9dd6-3a4a3abd69ad.png',
 'camp_specialists.png':'exec-5db48862-7c4e-40ad-a7d7-fac720de9c61.png',
 'woodland_props.png':'exec-33f995d2-148b-43c1-ab95-f3d9784d432a.png',
 'terrain_tiles.png':'exec-62fa7629-dba8-4eb5-b735-2c53b9bb6c11.png',
 'terrain_tiles_quiet.png':'exec-fd029d76-e720-41c4-8a3e-0c76a2e13b53.png',
}

def bbox(im):return im.getchannel('A').point(lambda a:255 if a>210 else 0).getbbox()

def save_runtime(im,path):
    """Bake the reviewed runtime alpha cutoff, with no resampling or painted fixes."""
    im=im.convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a:255 if a>210 else 0))
    data=np.asarray(im).copy();data[data[:,:,3]==0]=0
    Image.fromarray(data).save(path)

def connected_bodies(mask,count):
    """Separate silhouettes whose horizontal projections overlap without touching."""
    height,width=mask.shape
    visited=bytearray(mask.astype(np.uint8).tobytes())
    groups=[]
    for start in np.flatnonzero(mask):
        start=int(start)
        if not visited[start]:continue
        visited[start]=0;stack=[start];area=0;left=width;right=0;top=height;bottom=0
        while stack:
            point=stack.pop();y,x=divmod(point,width);area+=1
            left=min(left,x);right=max(right,x+1);top=min(top,y);bottom=max(bottom,y+1)
            for next_ in ([point-1] if x>0 else [])+([point+1] if x+1<width else [])+([point-width] if y>0 else [])+([point+width] if y+1<height else []):
                if visited[next_]:visited[next_]=0;stack.append(next_)
        groups.append((area,[left,top,right,bottom]))
    groups.sort(reverse=True)
    if len(groups)<count:raise ValueError(f'Expected {count} separate bodies, found {len(groups)}')
    chosen=groups[:count]
    if groups[count:] and groups[count][0]>chosen[-1][0]*.15:raise ValueError(f'Unexpected large detached component in sprite row: {groups[:count+2]}')
    return sorted([box for area,box in chosen],key=lambda box:box[0])

def silhouette_cells(source,columns,rows,row_bounds=None):
    """Find actual transparent gutters; never assume a generator obeyed its grid."""
    im=Image.open(source).convert('RGBA')
    mask=np.asarray(im)[:,:,3]>210
    def runs(values):
        edges=np.flatnonzero(np.diff(np.r_[False,values,False].astype(int)))
        return [(int(a),int(b)) for a,b in zip(edges[::2],edges[1::2]) if b-a>5]
    bands=list(zip(row_bounds,row_bounds[1:])) if row_bounds else runs(mask.any(axis=1))
    if len(bands)!=rows:
        boxes=connected_bodies(mask,columns*rows)
        boxes.sort(key=lambda box:(box[1]+box[3])/2)
        ordered=[]
        for row in range(rows):ordered+=sorted(boxes[row*columns:(row+1)*columns],key=lambda box:box[0])
        return [im.crop(box) for box in ordered],ordered
    cells=[];bounds=[]
    for row,(top,bottom) in enumerate(bands):
        spans=runs(mask[top:bottom].any(axis=0))
        if len(spans)!=columns:
            boxes=connected_bodies(mask[top:bottom],columns)
            for left,y0,right,y1 in boxes:
                actual=[left,top+y0,right,top+y1]
                cells.append(im.crop(actual));bounds.append(actual)
            continue
        for left,right in spans:
            cell=im.crop((left,top,right,bottom))
            box=bbox(cell)
            actual=[left+box[0],top+box[1],left+box[2],top+box[3]]
            cells.append(im.crop(actual));bounds.append(actual)
    return cells,bounds

def normalize_grid(source,columns,rows,size,output,body_height=None,foot_anchor=True,row_bounds=None):
    cells,bounds=silhouette_cells(source,columns,rows,row_bounds)
    # One scale for the entire animation: never resize individual poses to fit.
    scale=min((size-6)/max(x.width for x in cells),(body_height or size-4)/max(x.height for x in cells))
    atlas=Image.new('RGBA',(columns*size,rows*size))
    for i,cell in enumerate(cells):
        resized=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        resized=resized.crop(bbox(resized))
        # Foot anchor is measured from the lowest boot pixels, not swinging arms.
        alpha=np.asarray(resized)[:,:,3]>210
        feet=np.flatnonzero(alpha[-max(2,round(resized.height*.08)):].any(axis=0))
        anchor=int(round((feet[0]+feet[-1])/2)) if len(feet) and foot_anchor else resized.width//2
        x=(i%columns)*size+size//2-anchor
        if x<(i%columns)*size+1 or x+resized.width>(i%columns+1)*size-1:
            raise ValueError(f'{source.name}: pose {i} exceeds its frame after foot alignment')
        y=(i//columns)*size+size-2-resized.height
        atlas.alpha_composite(resized,(x,y))
    save_runtime(atlas,output)
    return {'columns':columns,'rows':rows,'frame_size':size,'shared_scale':scale,'frames':len(cells),'source':source.relative_to(ROOT).as_posix(),'source_bounds':bounds,'anchor':[size//2,size-2]}

def main():
    RAW.mkdir(parents=True,exist_ok=True)
    (ART/'sprites').mkdir(exist_ok=True);(ART/'environment').mkdir(exist_ok=True)
    sources=[]
    for name,raw in FILES.items():
        destination=RAW/name
        if not destination.exists():shutil.copyfile(GENERATED/raw,destination)
        sources.append({'file':name,'sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),'tool':'image_gen','accepted_for':'costume reference only; soft glow rejected' if 'concept' in name else 'normalization and in-engine inspection'})
    manifest={}
    manifest['player_walk']=normalize_grid(RAW/'surveyor_walk.png',8,4,64,ART/'sprites/player_walk.png',44)
    manifest['player_idle']=normalize_grid(RAW/'surveyor_idle.png',4,4,64,ART/'sprites/player_idle.png',44)
    manifest['player_attack']=normalize_grid(RAW/'surveyor_attack.png',8,4,64,ART/'sprites/player_attack.png',44)
    manifest['player_dodge']=normalize_grid(RAW/'surveyor_dodge.png',6,4,64,ART/'sprites/player_dodge.png',44,False)
    death=Image.open(RAW/'surveyor_death.png')
    manifest['player_death']=normalize_grid(RAW/'surveyor_death.png',8,4,64,ART/'sprites/player_death.png',44,False)
    for action,entry in manifest.items():
        entry.update(fps={'player_walk':9,'player_idle':5,'player_attack':8/.63,'player_dodge':6/.36,'player_death':9}[action],loop=action in ['player_walk','player_idle'],directions=['south','west','east','north'])
    normalize_grid(RAW/'camp_specialists.png',4,2,64,ART/'sprites/camp_specialists.png',44)
    npcs=Image.open(ART/'sprites/camp_specialists.png')
    for index in range(8):
        row,col=divmod(index,4)
        npcs.crop((col*64,row*64,(col+1)*64,(row+1)*64)).save(ART/f'sprites/npc_{index}.png')
    im=Image.open(RAW/'woodland_props.png').convert('RGBA')
    # The raw environment atlas has taller tree cells. Bounds are recorded explicitly.
    rows=[0,round(im.height*.39),round(im.height*.59),round(im.height*.79),im.height]
    prop_cells,prop_bounds=silhouette_cells(RAW/'woodland_props.png',4,4,rows)
    targets=[(80,100),(64,108),(64,96),(48,72),(38,27),(36,28),(36,28),(34,36),(32,27),(24,26),(24,20),(25,34),(36,25),(34,25),(48,32),(64,48)]
    for index,target in enumerate(targets):
        cell=prop_cells[index]
        scale=min(target[0]/cell.width,target[1]/cell.height)
        cell=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        save_runtime(cell,ART/f'environment/prop_{index:02d}.png')
    terrain=Image.open(RAW/'terrain_tiles_quiet.png').convert('RGBA')
    atlas=Image.new('RGBA',(128,128))
    for index in range(16):
        row,col=divmod(index,4)
        cell=terrain.crop((round(col*terrain.width/4)+3,round(row*terrain.height/4)+3,round((col+1)*terrain.width/4)-3,round((row+1)*terrain.height/4)-3))
        atlas.paste(cell.resize((32,32),Image.Resampling.NEAREST),(col*32,row*32))
    atlas.save(ART/'environment/terrain.png')
    surfaces=Image.open(RAW/'floor_surfaces.png').convert('RGBA')
    for index,id in enumerate(['floor','path','stone_floor','rug','bridge']):
        cell=surfaces.crop((round(index*surfaces.width/5),0,round((index+1)*surfaces.width/5),surfaces.height))
        cell.resize((32,32),Image.Resampling.NEAREST).save(ART/f'environment/surface_{id}.png')
    cells,landmark_bounds=silhouette_cells(RAW/'regional_landmarks.png',4,2)
    for name,cell,target in zip(['cache','survey','puzzle','spring','grove','expedition','waystone_broken','waystone_restored'],cells,[(48,42),(64,86),(64,48),(56,42),(64,58),(76,92),(46,72),(46,72)]):
        scale=min(target[0]/cell.width,target[1]/cell.height)
        save_runtime(cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST),ART/f'environment/site_{name}.png')
    cells,growth_bounds=silhouette_cells(RAW/'garden_growth.png',4,2)
    growth_scale=min(32/max(cell.width for cell in cells),36/max(cell.height for cell in cells))
    for index,cell in enumerate(cells):
        frame=cell.resize((max(1,round(cell.width*growth_scale)),max(1,round(cell.height*growth_scale))),Image.Resampling.NEAREST)
        tile=Image.new('RGBA',(40,40));tile.alpha_composite(frame,((40-frame.width)//2,38-frame.height));save_runtime(tile,ART/f'environment/garden_{index}.png')
    structures=json.loads((ROOT/'godot/data/structures.json').read_text(encoding='utf-8'))
    im=Image.open(RAW/'settlement_structures.png').convert('RGBA')
    # Explicit recorded gutters from the reviewed source atlas, which has unequal rows.
    row_bounds=[0,220,414,609,790,978,im.height]
    building_cells,building_bounds=silhouette_cells(RAW/'settlement_structures.png',7,6,row_bounds)
    targets=[(32,24),(32,24),(32,36),(32,25),(32,34),(32,28),(64,48),(38,34),(36,28),(48,32),(36,40),(36,28),(32,24),(48,50),(18,40),(32,45),(40,42),(48,48),(40,36),(48,48),(48,42),(32,22),(40,38),(32,24),(28,48),(22,18),(40,24),(24,32),(32,24),(36,44),(30,42),(64,70),(36,32),(32,42),(32,48),(32,32),(32,24),(40,36),(20,40),(48,48),(36,36)]
    for index,(id,target) in enumerate(zip(structures,targets)):
        cell=building_cells[index]
        scale=min(target[0]/cell.width,target[1]/cell.height)
        save_runtime(cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST),ART/f'environment/build_{id}.png')
    mobs=json.loads((ROOT/'godot/data/mobs.json').read_text(encoding='utf-8'))
    for region in ['bracken','fen','cinder','storm','hollow']:
        region_index=['bracken','fen','cinder','storm','hollow'].index(region)
        ids=[key for key,value in mobs.items() if value['region']==region_index and not value['boss'] and not value['passive']]
        ids += [['hare','crane','fox','deer','tortoise'][region_index]]
        ids += [key for key,value in mobs.items() if value['region']==region_index and value['boss']]
        if region=='hollow':
            source=Image.open(RAW/f'{region}_creatures.png')
            cells,bounds=silhouette_cells(RAW/f'{region}_creatures.png',4,10)
        elif region=='fen':
            source=Image.open(RAW/f'{region}_creatures.png')
            cells,bounds=silhouette_cells(RAW/f'{region}_creatures.png',8,4,[0,220,365,565,755])
            revised,revised_bounds=silhouette_cells(RAW/'reedmother_revised.png',4,2)
            cells+=revised;bounds+=revised_bounds
        else:
            cells,bounds=silhouette_cells(RAW/f'{region}_creatures.png',8,5)
        for row,id in enumerate(ids):
            boss=mobs[id]['boss'];size=96 if boss else 48
            frames=cells[row*8:(row+1)*8]
            scale=min((size-6)/max(x.width for x in frames),(80 if boss else 38)/max(x.height for x in frames))
            atlas=Image.new('RGBA',(size*8,size))
            for col,cell in enumerate(frames):
                frame=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
                frame=frame.crop(bbox(frame))
                atlas.alpha_composite(frame,(col*size+(size-frame.width)//2,size-2-frame.height))
            save_runtime(atlas,ART/f'sprites/mob_{id}.png')
            manifest['mob_'+id]={'columns':8,'rows':1,'frame_size':size,'frames':8,'fps':8,'loop':True,'source':f'godot/art/source/{region}_creatures.png','source_bounds':bounds[row*8:(row+1)*8],'shared_scale':scale,'anchor':[size//2,size-2]}
            if id=='reedmother':manifest['mob_'+id]['source']='godot/art/source/reedmother_revised.png'
    (ART/'icons').mkdir(exist_ok=True)
    gear=Image.open(RAW/'equipment_icons.png')
    cells,bounds=silhouette_cells(RAW/'equipment_icons.png',7,4)
    for row,prefix in enumerate(['field','copper','iron','storm']):
        for col,style in enumerate(['blade','spear','bow','focus','axe','pick','coat']):
            cell=cells[row*7+col];scale=min(28/cell.width,28/cell.height)
            cell=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
            icon=Image.new('RGBA',(32,32));icon.alpha_composite(cell,((32-cell.width)//2,30-cell.height))
            save_runtime(icon,ART/f'icons/{prefix}_{style}.png')
    for id in structures:
        cell=Image.open(ART/f'environment/build_{id}.png');scale=min(28/cell.width,28/cell.height)
        cell=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        icon=Image.new('RGBA',(32,32));icon.alpha_composite(cell,((32-cell.width)//2,(32-cell.height)//2));save_runtime(icon,ART/f'icons/{id}.png')
    supply_ids=['wood','stone','fiber','amber','raw_meat','hide','reed','clay','copper_ore','copper','iron_ore','iron','storm_shard','glass','charcoal','brick','rope','cloth','seed','gel','venom_sac','feather','relic','berry','water','mushroom','vegetable','fish','honey','roast','stew','grilled_fish','ration','tea','salve','bandage','tonic','fishing_rod']
    cells,bounds=silhouette_cells(RAW/'supply_icons.png',8,5)
    for id,cell in zip(supply_ids,cells):
        scale=min(28/cell.width,28/cell.height)
        cell=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        icon=Image.new('RGBA',(32,32));icon.alpha_composite(cell,((32-cell.width)//2,(32-cell.height)//2));save_runtime(icon,ART/f'icons/{id}.png')
    extended=['pond_perch','reed_eel','ash_char','pine_trout','glassfin','berry_seed','reed_seed','mushroom_spawn','sunroot_seed','sunroot','honey_tea','mushroom_skewer','berry_tart','fish_chowder','root_roast','smoked_fish','syrup_ration','clear_tonic','trail_compass','reed_charm','cinder_token','storm_pin','keeper_seal','root_locket','mint','sunblossom','sage','orchid','mint_cordial','sun_cordial','sage_draught','orchid_cordial']
    cells,bounds=silhouette_cells(RAW/'extended_provision_icons.png',8,4)
    for id,cell in zip(extended,cells):
        scale=min(28/cell.width,28/cell.height)
        cell=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        icon=Image.new('RGBA',(32,32));icon.alpha_composite(cell,((32-cell.width)//2,(32-cell.height)//2));save_runtime(icon,ART/f'icons/{id}.png')
    cells,bounds=silhouette_cells(RAW/'grain_provisions.png',3,2)
    for id,cell in zip(['grain','grain_seed','flour','flatbread'],cells[:4]):
        scale=min(28/cell.width,28/cell.height)
        cell=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
        icon=Image.new('RGBA',(32,32));icon.alpha_composite(cell,((32-cell.width)//2,(32-cell.height)//2));save_runtime(icon,ART/f'icons/{id}.png')
    cell=cells[4];scale=min(32/cell.width,36/cell.height)
    cell=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
    tile=Image.new('RGBA',(40,40));tile.alpha_composite(cell,((40-cell.width)//2,38-cell.height));save_runtime(tile,ART/'environment/garden_8.png')
    (ART/'source/provenance.json').write_text(json.dumps(sources,indent=2)+'\n')
    (ART/'animation_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    preview=Image.open(ART/'sprites/player_walk.png')
    preview.resize((preview.width*4,preview.height*4),Image.Resampling.NEAREST).save(ROOT/'verification/player_walk_contact.png')
    print(f'Prepared {sum(x["frames"] for x in manifest.values())} animation frames, 8 specialists, {len(structures)} buildings, {len(list((ART/"icons").glob("*.png")))} icons and environment tiles.')

if __name__=='__main__':main()
