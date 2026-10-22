"""Localized notes for actual releases, shared by the game and generated Wiki."""

def releases(text):
    text('release.100',
         'The Mossbound Atlas begins. Follow forgotten roads, make a home in the wild, and reconnect five regions through their waystones.',
         '《苔路图志》启程。踏上被遗忘的道路，在荒野安家，修复路碑，让五片土地再次相连。',
         '《苔路圖誌》啟程。踏上被遺忘的道路，在荒野安家，修復路碑，讓五片土地再次相連。',
         'Comienza The Mossbound Atlas. Recorre caminos olvidados, construye un hogar y conecta cinco regiones a través de sus hitos.',
         '『苔むす道の地図帳』の旅が始まります。忘れられた道を歩き、荒野に住まいを築き、道標で5つの地域をつなぎましょう。')
    notes={
      'world':(
        'Five wardens, eight travelers, 30 discovery sites, memory seals and repeatable three-wave expeditions. Choose Bloom, Ember or Gale for each region.',
        '五位守卫、八名旅人、30处探索地点、记忆封印，以及可重复挑战的三波远征。各区域可选择繁茂、余烬或疾风。',
        '五位守衛、八名旅人、30處探索地點、記憶封印，以及可重複挑戰的三波遠征。各區域可選擇繁茂、餘燼或疾風。',
        'Cinco guardianes, ocho viajeros, 30 lugares, sellos de memoria y expediciones repetibles de tres oleadas. Elige Brote, Ascua o Vendaval para cada región.',
        '5体の守り手、8人の旅人、30か所の発見地点、記憶の封印、繰り返し挑める3波の遠征。各地域で芽吹き、残り火、疾風を選べます。'),
      'camp':(
        '143 items, 115 recipes, 41 building pieces, six crops and five regional fish. Queue production, send courier shipments and fulfill 16 rotating requests.',
        '143种物品、115份配方、41种建筑构件、六种作物与五地鱼类。安排加工队列、寄送物资，完成16种轮换委托。',
        '143種物品、115份配方、41種建築構件、六種作物與五地魚類。安排加工佇列、寄送物資，完成16種輪換委託。',
        '143 objetos, 115 recetas, 41 piezas de construcción, seis cultivos y cinco peces regionales. Organiza la producción, envía suministros y cumple 16 encargos rotativos.',
        '143種類のアイテム、115種類のレシピ、41種類の建築物、6種類の作物、地域ごとの5種類の魚。加工の予約や物資の配送、16種類の交代する依頼を楽しめます。'),
      'combat':(
        'Four equipment tiers, blades, spears, bows and focuses, nine perks, six charms, food benefits and dodge invulnerability. Face 25 creatures with visible attack warnings.',
        '四阶装备，刀剑、长矛、弓与聚能器，九项专长、六种护符与食物增益。可用闪避躲过伤害，25种生物的攻击均有预兆。',
        '四階裝備，刀劍、長矛、弓與聚能器，九項專長、六種護符與食物增益。可用閃避躲過傷害，25種生物的攻擊均有預兆。',
        'Cuatro niveles de equipo, hojas, lanzas, arcos y focos; nueve talentos, seis amuletos y beneficios de comida. Esquivas con invulnerabilidad y ataques anunciados para 25 criaturas.',
        '4段階の装備、剣・槍・弓・集束器、9種類の特技、6種類のお守り、料理の効果。回避中は無敵になり、25種類の生き物が予備動作を見せて攻撃します。'),
      'saves':(
        'Multiple journey slots, automatic saves and three backup generations. Five game difficulties and three separate death rules. Hardcore preserves a retired character’s atlas.',
        '多个旅程存档、自动保存与三代备份。五档游戏难度与三种死亡规则可独立选择。硬核角色退场后仍可查看图志。',
        '多個旅程存檔、自動儲存與三代備份。五檔遊戲難度與三種死亡規則可獨立選擇。硬核角色退場後仍可查看圖誌。',
        'Varias partidas, guardado automático y tres copias de respaldo. Cinco dificultades y tres reglas de muerte independientes. En Hardcore puedes consultar el atlas del personaje retirado.',
        '複数の旅の保存、自動保存、3世代のバックアップ。5段階の難易度と3種類の死亡ルールを別々に選べます。ハードコアで旅を終えた後も地図帳を閲覧できます。'),
      'presentation':(
        'Original pixel art with 336 animation frames, six original music themes and 21 sound effects. Five languages, bundled CJK fonts, controller controls, an atlas and a searchable field guide.',
        '原创像素美术，336帧动画、六首原创乐曲与21种音效。支持五种语言，内置中日文字体，并提供手柄操作、图志与可搜索的生物图鉴。',
        '原創像素美術，336幀動畫、六首原創樂曲與21種音效。支援五種語言，內建中日文字型，並提供手把操作、圖誌與可搜尋的生物圖鑑。',
        'Arte de píxeles original con 336 fotogramas, seis temas musicales y 21 efectos de sonido. Cinco idiomas, fuentes CJK incluidas, controles de mando, atlas y guía de campo con búsqueda.',
        'オリジナルのピクセルアート、336フレームのアニメーション、6曲の音楽、21種類の効果音。5言語と同梱の中日フォント、コントローラー操作、地図帳、検索できる図鑑に対応。')
    }
    for key,values in notes.items():text('release.100.'+key,*values)
    return [{'version':'1.0.0','date':'2026-10-22','text_key':'release.100','entries':['release.100.'+key for key in notes]}]
