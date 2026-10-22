import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'godot/art'

def read(path):return json.loads(path.read_text(encoding='utf-8'))

def test_every_item_has_a_complete_icon():
    for id in read(ROOT/'godot/data/items.json'):
        path=ART/f'icons/{id}.png'
        assert path.exists(),id
        im=Image.open(path).convert('RGBA')
        assert im.size==(32,32),id
        alpha=np.asarray(im)[:,:,3]
        assert np.count_nonzero(alpha)>5,id
        assert set(np.unique(alpha)).issubset({0,255}),id

def test_animation_frames_and_shared_anchors():
    manifest=read(ART/'animation_manifest.json')
    assert len([key for key in manifest if key.startswith('mob_')])==25
    assert all('player_'+action in manifest for action in ['idle','walk','attack','dodge','death'])
    for name,entry in manifest.items():
        im=Image.open(ART/f'sprites/{name}.png').convert('RGBA')
        size=entry['frame_size'];columns=entry['columns'];rows=entry['rows']
        assert im.size==(size*columns,size*rows),name
        assert len(entry['source_bounds'])==entry['frames'],name
        assert entry['shared_scale']>0,name
        for row in range(rows):
            for col in range(columns):
                data=np.asarray(im.crop((col*size,row*size,(col+1)*size,(row+1)*size)))
                alpha=data[:,:,3]
                assert np.count_nonzero(alpha)>20,(name,row,col)
                assert not (alpha[0].any() or alpha[-1].any() or alpha[:,0].any() or alpha[:,-1].any()),(name,row,col,'clipped frame edge')
                assert set(np.unique(alpha)).issubset({0,255}),(name,row,col)
                assert np.max(np.nonzero(alpha)[0]) in [size-3,size-2,size-1],(name,row,col,'foot baseline')

def test_original_sources_match_provenance():
    for entry in read(ART/'source/provenance.json'):
        path=ART/'source'/entry['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],entry['file']

def test_all_buildings_and_landmarks_have_distinct_art():
    hashes=[]
    for id in read(ROOT/'godot/data/structures.json'):
        path=ART/f'environment/build_{id}.png'
        assert path.exists(),id
        hashes.append(hashlib.sha256(path.read_bytes()).hexdigest())
    assert len(hashes)==len(set(hashes))
    for kind in ['cache','survey','puzzle','spring','grove','expedition','waystone_broken','waystone_restored']:
        assert (ART/f'environment/site_{kind}.png').exists(),kind
