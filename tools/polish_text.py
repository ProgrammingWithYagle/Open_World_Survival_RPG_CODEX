"""Keep player descriptions specific to implemented effects and controls."""

def polish(text,items,catalogs):
    styles={
      'blade':('A close-range blade.','近身作战的短剑。','近身作戰的短劍。','Hoja para combatir de cerca.','接近戦用の短剣です。'),
      'spear':('A long-reaching thrusting weapon.','攻击距离较远的突刺武器。','攻擊距離較遠的突刺武器。','Arma de estocadas con mayor alcance.','遠めの間合いから突ける槍です。'),
      'bow':('Fires an arrow toward your aim.','向瞄准方向射出箭矢。','向瞄準方向射出箭矢。','Dispara una flecha en la dirección apuntada.','狙った方向に矢を放ちます。'),
      'focus':('Launches a bolt of resonance toward your aim.','向瞄准方向发射共鸣弹。','向瞄準方向發射共鳴彈。','Lanza un proyectil de resonancia hacia donde apuntas.','狙った方向に共鳴の弾を放ちます。'),
      'axe':('Chops timber. Interact beside a tree to harvest it.','可砍伐木材。在树旁互动即可采集。','可砍伐木材。在樹旁互動即可採集。','Tala madera. Interactúa junto a un árbol para recogerla.','木を伐る道具です。木のそばで調べると採取できます。'),
      'pick':('Mines stone and ore up to tier {tier}.','可开采{tier}阶及以下的石料与矿物。','可開採{tier}階及以下的石料與礦物。','Extrae piedra y minerales de hasta nivel {tier}.','{tier}段階までの石や鉱石を採掘できます。')
    }
    for id,item in items.items():
        if item.get('style') not in styles:continue
        damage=item['damage'];tier=item['tier'];kind=styles[item['style']]
        stats=(f' Base damage: {damage}. Equip from your backpack.',f'基础伤害：{damage}。可在背包中装备。',f'基礎傷害：{damage}。可在背包中裝備。',f' Daño base: {damage}. Se equipa desde la mochila.',f'基礎ダメージ：{damage}。持ち物から装備できます。')
        text('item.'+id+'.desc',*(kind[i].format(tier=tier)+stats[i] for i in range(5)))
    labels=[('hunger',('food','饱腹','飽食','alimento','満腹度')),('thirst',('water','饮水','飲水','agua','水分')),('health',('health','生命','生命','salud','体力')),('stamina',('stamina','体力','體力','energía','スタミナ'))]
    for id,item in items.items():
        if item['kind']!='consumable' or not item.get('effects'):continue
        lines=[]
        for language,(lang,catalog) in enumerate(catalogs.items()):
            values=[(item['effects'].get(key,0),names[language]) for key,names in labels if item['effects'].get(key,0)>0]
            old=catalog['item.'+id+'.desc']
            prefix=['Restores ','恢复','恢復','Recupera ','満腹度'][language]
            separator='。' if language in [1,2,4] else '. '
            suffix=old.split(separator,1)[1] if old.startswith(prefix) and separator in old else old
            if language==0:line='Restores '+', '.join(f'{value} {name}' for value,name in values)+'. '
            elif language in [1,2]:line=['恢复','恢復'][language-1]+'、'.join(f'{value}点{name}' if language==1 else f'{value}點{name}' for value,name in values)+'。'
            elif language==3:line='Recupera '+', '.join(f'{value} de {name}' for value,name in values)+'. '
            else:line='、'.join(f'{name}{value}' for value,name in values)+'を回復します。'
            lines.append(line+suffix)
        text('item.'+id+'.desc',*lines)
    text('item.seed.desc','Plant in a garden. It ripens after several minutes of active world time and returns vegetables and a new seed packet.','种在菜畦中，经过几分钟游戏时间即可成熟，收获蔬菜与新种子。','種在菜畦中，經過幾分鐘遊戲時間即可成熟，收穫蔬菜與新種子。','Plántala en un bancal. Madura tras unos minutos de juego y produce verduras y nuevas semillas.','畑に植えると、ゲーム内の数分間で育ちます。野菜と新しい種を収穫できます。')
    text('item.feather.desc','A light, strong feather used in storm pins and traveler supplies.','轻而坚韧的羽毛，可制作风羽胸针，也用于旅人委托。','輕而堅韌的羽毛，可製作風羽胸針，也用於旅人委託。','Pluma ligera y resistente para broches de tormenta y encargos de viajeros.','軽く丈夫な羽根。嵐羽のブローチや旅人の依頼に使います。')
