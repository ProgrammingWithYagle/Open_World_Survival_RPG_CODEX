"""Distinct fishing, farming, cooking and equipment options for extended play."""

def expand_provisions(text,item,recipes):
    fish=[
    ('pond_perch',('Pond perch','池鲈','池鱸','Perca de estanque','池のスズキ')),
    ('reed_eel',('Reed eel','苇鳗','葦鰻','Anguila del junco','葦ウナギ')),
    ('ash_char',('Ash char','灰红点鲑','灰紅點鮭','Salvelino de ceniza','灰イワナ')),
    ('pine_trout',('Pine trout','松纹鳟','松紋鱒','Trucha del pino','松マス')),
    ('glassfin',('Glassfin','琉璃鳍','琉璃鰭','Aleta de vidrio','玻璃ビレ'))]
    for region,(key,names) in enumerate(fish):
        item(key,names,('A regional catch. Eat for 14 food, or clean one at a cooking pot to make two portions of fish for recipes.','当地鱼种。食用恢复14点饱腹；也可在炊锅旁处理成两份配方用鱼肉。','當地魚種。食用恢復14點飽食；也可在炊鍋旁處理成兩份配方用魚肉。','Pez de la región. Recupera 14 de alimento o límpialo junto a una olla para obtener dos porciones para recetas.','この地域の魚。食べると満腹度が14回復します。料理鍋のそばでさばくと、料理用の魚が2個できます。'),kind='consumable',effects={'hunger':14,'health':0,'thirst':0,'stamina':10})
        text('recipe.clean_'+key,'Clean '+names[0],names[1]+'处理',names[2]+'處理','Limpiar '+names[3],names[4]+'をさばく')
        recipes['clean_'+key]={'name_key':'recipe.clean_'+key,'result':{'id':'fish','count':2},'ingredients':[{'id':key,'count':1}],'station':'cooking_pot','tier':1}
    seeds=[
    ('berry_seed',('Berry seed','浆果种子','漿果種子','Semilla de baya','ベリーの種'),'berry',180,1),
    ('reed_seed',('Reed seed','苇草种子','葦草種子','Semilla de junco','葦の種'),'reed',240,2),
    ('mushroom_spawn',('Mushroom spawn','蘑菇菌种','蘑菇菌種','Micelio','キノコの菌床'),'mushroom',270,2),
    ('sunroot_seed',('Sunroot seed','阳根种子','陽根種子','Semilla de raíz solar','陽根の種'),'sunroot',330,3)]
    for key,names,produce,seconds,tier in seeds:
        item(key,names,('Plant in a garden bed. Harvest three crops and one seed when ready.','种在菜畦中，成熟后收获三份作物与一份种子。','種在菜畦中，成熟後收穫三份作物與一份種子。','Plántala en un bancal. Al madurar, cosecha tres productos y una semilla.','畑に植えると、育ったときに作物3個と種1個を収穫できます。'),kind='material',tier=tier)
        recipes[key]={'result':{'id':key,'count':3},'ingredients':[{'id':produce,'count':2},{'id':'fiber','count':1}],'station':'workbench','tier':tier}
    item('sunroot',('Sunroot','阳根','陽根','Raíz solar','陽根'),('A sweet golden root. Restores 20 food. Grow it in a garden or find it in Cinderstep.','甘甜的金色根茎，恢复20点饱腹。可在菜畦种植，也生长于烬阶荒地。','甘甜的金色根莖，恢復20點飽食。可在菜畦種植，也生長於燼階荒地。','Raíz dorada y dulce. Recupera 20 de alimento. Crece en bancales y en las Tierras de Ceniza.','甘い黄金色の根。満腹度が20回復します。畑で育てるほか、灰踏みの荒地で採れます。'),kind='consumable',effects={'hunger':20,'health':0,'thirst':0,'stamina':10})
    buffs={
    'warmth':('Sheltered warmth','温暖护佑','溫暖護佑','Calor protector','ぬくもり'),
    'stamina':('Steady breath','平稳呼吸','平穩呼吸','Aliento constante','整う息'),
    'healing':('Slow recovery','缓慢恢复','緩慢恢復','Recuperación gradual','穏やかな回復'),
    'armor':('Rootguard','根须护体','根鬚護體','Protección de raíz','根の守り'),
    'endurance':('Long trail','远行耐力','遠行耐力','Largo camino','長旅の力'),
    'nourished':('Well fed','饱足','飽足','Bien alimentado','腹持ち'),
    'haste':('Light step','轻盈步伐','輕盈步伐','Paso ligero','軽い足取り'),
    'focus':('Clear focus','澄明专注','澄明專注','Concentración clara','澄んだ集中')}
    for key,names in buffs.items():text('buff.'+key,*names)
    foods=[
    ('honey_tea',('Honey tea','蜂蜜茶','蜂蜜茶','Té con miel','ハチミツ茶'),0,65,10,'warmth',240,{'honey':1,'tea':1}),
    ('mushroom_skewer',('Woodland skewer','林野菇串','林野菇串','Brocheta del bosque','森の串焼き'),38,0,12,'stamina',180,{'mushroom':3,'wood':1}),
    ('berry_tart',('Hearth berry tart','炉火浆果饼','爐火漿果餅','Tarta de bayas','ベリーのタルト'),50,0,20,'nourished',240,{'berry':5,'honey':1,'vegetable':1}),
    ('fish_chowder',('Reedglass chowder','苇镜鱼羹','葦鏡魚羹','Sopa de la marisma','葦鏡の魚スープ'),55,20,25,'healing',180,{'fish':2,'vegetable':2,'water':1}),
    ('root_roast',('Golden root roast','金根烤盘','金根烤盤','Raíces doradas asadas','黄金根のロースト'),65,0,20,'armor',240,{'sunroot':3,'mushroom':1}),
    ('smoked_fish',('Trail-smoked fish','远行熏鱼','遠行燻魚','Pescado ahumado','旅の燻製魚'),50,0,5,'endurance',240,{'fish':2,'wood':2}),
    ('syrup_ration',('Syrup trail pack','糖蜜行粮','糖蜜行糧','Ración con miel','蜜の保存食'),80,0,10,'nourished',300,{'ration':2,'honey':2}),
    ('clear_tonic',('Clearwater tonic','澄泉药剂','澄泉藥劑','Tónico de agua clara','清水の薬'),0,30,30,'focus',180,{'water':2,'gel':2,'mint':1})]
    descriptions={
    'warmth':('Prevents exposure from rising.','防止环境影响增加。','防止環境影響增加。','Evita que aumente la exposición.','環境による冷えの増加を防ぎます。'),
    'stamina':('Stamina recovers 35% faster.','体力恢复加快35%。','體力恢復加快35%。','La energía se recupera un 35 % más deprisa.','スタミナの回復が35%速くなります。'),
    'healing':('Restores 1 health each second.','每秒恢复1点生命。','每秒恢復1點生命。','Recuperas 1 de salud por segundo.','体力が毎秒1回復します。'),
    'armor':('Reduces incoming damage by 2.','受到的伤害降低2点。','受到的傷害降低2點。','Reduce el daño recibido en 2.','受けるダメージを2軽減します。'),
    'endurance':('Sprinting uses 30% less stamina.','冲刺体力消耗降低30%。','衝刺體力消耗降低30%。','Correr consume un 30 % menos de energía.','走るときのスタミナ消費が30%減ります。'),
    'nourished':('Hunger and thirst rise 30% more slowly.','饥饿与口渴增长减慢30%。','飢餓與口渴增加減慢30%。','El hambre y la sed avanzan un 30 % más despacio.','空腹と渇きの進行が30%遅くなります。'),
    'haste':('Move 10% faster.','移动速度提高10%。','移動速度提高10%。','Te mueves un 10 % más rápido.','移動速度が10%上がります。'),
    'focus':('Weapon damage increases by 10%.','武器伤害提高10%。','武器傷害提高10%。','El daño con armas aumenta un 10 %.','武器のダメージが10%上がります。')}
    for key,names,food,water,health,buff,duration,costs in foods:
        desc=(f'Restores {food} food, {water} water and {health} health. {descriptions[buff][0]} Lasts {duration} seconds.',f'恢复{food}点饱腹、{water}点饮水与{health}点生命。{descriptions[buff][1]}持续{duration}秒。',f'恢復{food}點飽食、{water}點飲水與{health}點生命。{descriptions[buff][2]}持續{duration}秒。',f'Recupera {food} de alimento, {water} de agua y {health} de salud. {descriptions[buff][3]} Dura {duration} segundos.',f'満腹度{food}、水分{water}、体力{health}を回復。{descriptions[buff][4]}効果は{duration}秒です。')
        item(key,names,desc,kind='consumable',effects={'hunger':food,'thirst':water,'health':health,'stamina':20},buff=buff,duration=duration)
        recipes[key]={'result':{'id':key,'count':1},'ingredients':[{'id':k,'count':v} for k,v in costs.items()],'station':'drying_rack' if key in ['smoked_fish','syrup_ration'] else 'cooking_pot','tier':2 if key!='root_roast' else 3}
    charms=[
    ('trail_compass',('Trail compass','行路罗盘','行路羅盤','Brújula de camino','旅の羅針盤'),'speed',{'copper':3,'amber':2},2,('Move 8% faster while equipped.','装备时移动速度提高8%。','裝備時移動速度提高8%。','Te mueves un 8 % más rápido al equiparla.','装備すると移動速度が8%上がります。')),
    ('reed_charm',('Reed charm','苇编饰物','葦編飾物','Amuleto de junco','葦のお守り'),'garden',{'reed':6,'amber':3},2,('Gardens grow 15% faster while equipped.','装备时菜畦成长加快15%。','裝備時菜畦成長加快15%。','Los cultivos crecen un 15 % más rápido al equiparlo.','装備すると畑の作物が15%速く育ちます。')),
    ('cinder_token',('Cinder token','烬铜纹章','燼銅紋章','Medallón de ascua','熾火のメダル'),'armor',{'iron':3,'amber':3},3,('Take 2 less damage while equipped.','装备时受到的伤害降低2点。','裝備時受到的傷害降低2點。','Recibes 2 puntos menos de daño al equiparlo.','装備すると受けるダメージを2軽減します。')),
    ('storm_pin',('Storm pin','风羽胸针','風羽胸針','Broche de tormenta','嵐羽のブローチ'),'stamina',{'storm_shard':4,'feather':3},4,('Stamina recovers 20% faster while equipped.','装备时体力恢复加快20%。','裝備時體力恢復加快20%。','La energía se recupera un 20 % más deprisa al equiparlo.','装備するとスタミナの回復が20%速くなります。')),
    ('keeper_seal',('Keeper seal','守望者印章','守望者印章','Sello del guardián','守り手の印'),'damage',{'glass':4,'relic':6},4,('Weapon damage increases by 12% while equipped.','装备时武器伤害提高12%。','裝備時武器傷害提高12%。','El daño con armas aumenta un 12 % al equiparlo.','装備すると武器のダメージが12%上がります。')),
    ('root_locket',('Root locket','根心吊坠','根心吊墜','Colgante de raíz','根のペンダント'),'healing',{'wood':12,'amber':6},2,('Recover 1 health every 5 seconds while equipped.','装备时每5秒恢复1点生命。','裝備時每5秒恢復1點生命。','Recuperas 1 de salud cada 5 segundos al equiparlo.','装備すると5秒ごとに体力が1回復します。'))]
    for key,names,effect,costs,tier,desc in charms:
        item(key,names,desc,kind='trinket',stack=1,tier=tier,charm=effect)
        recipes[key]={'result':{'id':key,'count':1},'ingredients':[{'id':k,'count':v} for k,v in costs.items()],'station':'workbench' if tier<4 else 'resonator','tier':tier}
    herbs=[('mint',('Wild mint','野薄荷','野薄荷','Menta silvestre','野のミント')),('sunblossom',('Sunblossom','阳焰花','陽焰花','Flor solar','陽炎花')),('sage',('Alpine sage','高山鼠尾草','高山鼠尾草','Salvia alpina','高山セージ')),('orchid',('Hollow orchid','空寂兰','空寂蘭','Orquídea del hueco','うつろ蘭'))]
    for key,names in herbs:item(key,names,('A regional herb used in expedition cordials. Gather it in the wilds or trade for it.','区域草药，可调制远行饮剂。可在野外采集或通过交易获得。','區域草藥，可調製遠行飲劑。可在野外採集或透過交易獲得。','Hierba regional para preparar cordiales de expedición. Recógela o consíguela comerciando.','探索用の薬に使う地域の草花です。荒野で採るか、交換で手に入ります。'))
    for key,names,herb,buff in [
    ('mint_cordial',('Mint cordial','薄荷饮剂','薄荷飲劑','Cordial de menta','ミントの薬'),'mint','haste'),
    ('sun_cordial',('Sun cordial','阳花饮剂','陽花飲劑','Cordial solar','陽花の薬'),'sunblossom','warmth'),
    ('sage_draught',('Sage draught','鼠尾草饮剂','鼠尾草飲劑','Brebaje de salvia','セージの薬'),'sage','stamina'),
    ('orchid_cordial',('Orchid cordial','兰花饮剂','蘭花飲劑','Cordial de orquídea','蘭の薬'),'orchid','focus')]:
        desc=tuple(descriptions[buff][i]+[' Lasts 240 seconds.','持续240秒。','持續240秒。',' Dura 240 segundos.','効果は240秒です。'][i] for i in range(5))
        item(key,names,desc,kind='consumable',effects={'hunger':0,'thirst':25,'health':10,'stamina':20},buff=buff,duration=240)
        recipes[key]={'result':{'id':key,'count':1},'ingredients':[{'id':herb,'count':2},{'id':'honey','count':1},{'id':'water','count':1}],'station':'cooking_pot','tier':2}
    for key,names,kind in [
    ('grain',('Golden grain','金穗谷物','金穗穀物','Grano dorado','黄金の穀物'),'material'),
    ('grain_seed',('Grain seed','谷物种子','穀物種子','Semilla de cereal','穀物の種'),'material'),
    ('flour',('Stoneground flour','石磨面粉','石磨麵粉','Harina molida','石挽き粉'),'material'),
    ('flatbread',('Hearth flatbread','炉火薄饼','爐火薄餅','Pan de hoguera','炉火の平焼きパン'),'consumable')]:
        desc={
        'grain':('Mill ripe grain into flour, or save it for seed packets.','可将成熟谷物磨成面粉，或留作制种。','可將成熟穀物磨成麵粉，或留作製種。','Muele el grano para obtener harina o guárdalo para preparar semillas.','熟した穀物です。粉に挽くか、種を用意する材料になります。'),
        'grain_seed':('Plant in a garden. Harvest grain and a new seed packet when it ripens.','种在菜畦中，成熟后收获谷物与新种子。','種在菜畦中，成熟後收穫穀物與新種子。','Plántala en un bancal. Cosecha grano y nuevas semillas cuando madure.','畑に植えると、穀物と新しい種を収穫できます。'),
        'flour':('Ground at a grain mill. Used to bake filling camp bread.','在磨坊中磨制，可烘烤饱腹的营地面包。','在磨坊中磨製，可烘烤飽腹的營地麵包。','Se obtiene en un molino. Sirve para hornear pan saciante.','製粉機で挽いた粉。腹持ちのよいパンを作れます。'),
        'flatbread':('Restores 45 food and 8 health. A simple reward for tending your own fields.','恢复45点饱腹与8点生命，是亲手耕作的朴实回报。','恢復45點飽食與8點生命，是親手耕作的樸實回報。','Recupera 45 de alimento y 8 de salud. El fruto sencillo de cultivar tu huerto.','満腹度45、体力8を回復します。畑を育てた、ささやかなごほうびです。')}[key]
        item(key,names,desc,kind=kind,**({'effects':{'hunger':45,'thirst':0,'health':8,'stamina':20}} if kind=='consumable' else {}))
    recipes['grain_seed']={'result':{'id':'grain_seed','count':3},'ingredients':[{'id':'grain','count':2},{'id':'fiber','count':1}],'station':'workbench','tier':1}
    recipes['flour']={'result':{'id':'flour','count':2},'ingredients':[{'id':'grain','count':3}],'station':'mill','tier':2,'production_seconds':25}
    recipes['flatbread']={'result':{'id':'flatbread','count':2},'ingredients':[{'id':'flour','count':2},{'id':'water','count':1}],'station':'cooking_pot','tier':2}
    crops={'seed':{'produce':'vegetable','seconds':300},'grain_seed':{'produce':'grain','seconds':300},**{key:{'produce':produce,'seconds':seconds} for key,n,produce,seconds,tier in seeds}}
    return {'fish_species':[key for key,n in fish],'crops':crops,'production_extra':[{'id':'flour','station':'mill','seconds':25}]}
