import json
import re
import unittest
import wave
import numpy as np
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'godot/data'
LANGS=['en','zh_CN','zh_TW','es','ja']
def read(path):return json.loads(path.read_text(encoding='utf-8'))

class ContentTests(unittest.TestCase):
    def test_complete_content_graph(self):
        items=read(DATA/'items.json');recipes=read(DATA/'recipes.json');structures=read(DATA/'structures.json')
        self.assertGreaterEqual(len(items),80);self.assertGreaterEqual(len(recipes),60);self.assertGreaterEqual(len(structures),40)
        for key,value in recipes.items():
            self.assertIn(value['result']['id'],items,key)
            self.assertGreater(value['result']['count'],0,key)
            self.assertIn(value['tier'],range(1,5),key)
            if value['station']:self.assertIn(value['station'],structures,key)
            for ingredient in value['ingredients']:
                self.assertIn(ingredient['id'],items,key)
                self.assertGreater(ingredient['count'],0,key)
        for key,value in structures.items():
            self.assertEqual(items[key]['kind'],'building')
            self.assertIn(key,recipes)
            self.assertTrue(value['cost'])

    def test_creatures_and_progression(self):
        mobs=read(DATA/'mobs.json');items=read(DATA/'items.json')
        self.assertEqual(sum(x['boss'] for x in mobs.values()),5)
        self.assertEqual(sum(x['passive'] for x in mobs.values()),5)
        self.assertEqual(sum(not x['passive'] and not x['boss'] for x in mobs.values()),15)
        for key,mob in mobs.items():
            self.assertGreaterEqual(mob['attack_cooldown'],.5,key)
            self.assertIn(mob['region'],range(5),key)
            for drop in mob['drops']:self.assertIn(drop['id'],items,key)

    def test_translation_completeness_and_placeholders(self):
        catalogs={lang:read(ROOT/f'godot/locale/{lang}.json') for lang in LANGS}
        reference=catalogs['en']
        pattern=re.compile(r'\{([a-zA-Z_]+)\}')
        for lang,catalog in catalogs.items():
            self.assertEqual(set(reference),set(catalog),lang)
            for key,value in catalog.items():
                self.assertTrue(value.strip(),(lang,key))
                self.assertEqual(set(pattern.findall(reference[key])),set(pattern.findall(value)),(lang,key))
                self.assertNotRegex(value,r'(?:TODO:|PLACEHOLDER|(?i:lorem ipsum|not implemented))',(lang,key))
        differences=sum(catalogs['zh_CN'][key]!=catalogs['zh_TW'][key] for key in reference)
        self.assertGreater(differences,100,'Traditional Chinese must be an actual separate catalog')
        for section in ['items','mobs','npcs','regions','points_of_interest','recipes']:
            values=read(DATA/f'{section}.json')
            entries=values.values() if isinstance(values,dict) else values
            for entry in entries:
                for field in ['name_key','description_key','dialogue_key']:
                    if field in entry:self.assertIn(entry[field],reference,(section,field))

    def test_literal_ui_translation_keys_exist(self):
        catalog=read(ROOT/'godot/locale/en.json')
        missing=[]
        for script in (ROOT/'godot/scripts').rglob('*.gd'):
            if 'core' not in script.parts and 'ui' not in script.parts and 'actors' not in script.parts and 'world' not in script.parts and script.name!='moss_main.gd':continue
            for key in re.findall(r'L\.t\(\s*"([^"{}]+)"\s*[,)]',script.read_text(encoding='utf-8')):
                if key not in catalog:missing.append((str(script.relative_to(ROOT)),key))
        self.assertEqual(missing,[])

    def test_audio_has_headroom_and_real_content(self):
        manifest=read(ROOT/'godot/audio/audio_manifest.json')
        self.assertEqual(sum(name.startswith('music_') for name in manifest),6)
        for name,stats in manifest.items():
            self.assertGreater(stats['rms'],0,name)
            self.assertLess(stats['peak'],.95,name)
            if name.startswith('music_'):self.assertGreater(stats['seconds'],30,name)
            with wave.open(str(ROOT/'godot/audio'/f'{name}.wav'),'rb') as source:
                self.assertEqual((source.getnchannels(),source.getsampwidth(),source.getframerate()),(2,2,22050),name)
                samples=np.frombuffer(source.readframes(source.getnframes()),dtype='<i2').reshape(-1,2).astype(np.float32)/32767
                self.assertLess(abs(len(samples)/22050-stats['seconds']),.002,name)
                self.assertGreater(float(np.sqrt(np.mean(samples*samples))),.00001,name)
                self.assertLess(float(np.max(np.abs(samples))),.95,name)
                self.assertLess(float(np.max(np.abs(samples.mean(axis=0)))),.002,name)
                self.assertTrue(np.all(samples[0]==0) and np.all(samples[-1]==0),name)

if __name__=='__main__':unittest.main()
