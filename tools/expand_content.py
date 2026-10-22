"""Authored exploration, settlement and repeatable activity content."""

def expand(text, item, items, recipes, structures, regions, npcs):
    ui={
    'activities':('Discoveries','探索发现','探索發現','Descubrimientos','発見'),
    'bestiary':('Field guide','生物图鉴','生物圖鑑','Guía de campo','生き物図鑑'),
    'seen':('Observed: {count} · Defeated: {kills}','已观察：{count} · 已击败：{kills}','已觀察：{count} · 已擊敗：{kills}','Observados: {count} · Derrotados: {kills}','観察数：{count}・討伐数：{kills}'),
    'unknown_creature':('Explore to discover this creature.','探索荒野以发现这种生物。','探索荒野以發現這種生物。','Explora para descubrir esta criatura.','探索すると、この生き物の情報が増えます。'),
    'discoveries':('Places discovered: {count} / {total}','已发现地点：{count} / {total}','已發現地點：{count} / {total}','Lugares descubiertos: {count} / {total}','発見した場所：{count} / {total}'),
    'searched':('You have already searched this place. Its story is now in your journal.','你已搜寻过这里，故事已记入日志。','你已搜尋過這裡，故事已記入日誌。','Ya has registrado este lugar. Su historia está en tu diario.','この場所は調査済みです。物語は旅日誌に残っています。'),
    'search_site':('Search the site','搜寻遗址','搜尋遺址','Registrar el lugar','遺跡を調べる'),
    'survey_site':('Survey the surrounding land','测绘周边土地','測繪周邊土地','Cartografiar los alrededores','周囲を測量する'),
    'surveyed':('Nearby land has been added to your atlas.','周边土地已记入图志。','周邊土地已記入圖誌。','Los alrededores aparecen ahora en tu atlas.','周囲の土地を地図帳に記しました。'),
    'grove_offer':('Tend the grove: 3 seeds and 4 water','照料林地：3份种子与4份水','照料林地：3份種子與4份水','Cuidar la arboleda: 3 semillas y 4 de agua','林を育てる：種3個と水4個'),
    'grove_done':('The grove is thriving. Return tomorrow to tend it again.','林地生机盎然，明天可以再次照料。','林地生機盎然，明天可以再次照料。','La arboleda prospera. Vuelve mañana para cuidarla.','林に元気が戻りました。また明日、手入れをしましょう。'),
    'puzzle_hint':('The inscription names three currents in order: {sequence}. Turn the seals to match.','碑文依次记着三种流向：{sequence}。转动印章，使其相符。','碑文依次記著三種流向：{sequence}。轉動印章，使其相符。','La inscripción nombra tres corrientes: {sequence}. Gira los sellos en ese orden.','碑文に三つの力が順に刻まれています：{sequence}。印を回して合わせましょう。'),
    'puzzle_wrong':('The seals remain quiet. Check the order in the inscription.','印章仍未回应，请确认碑文中的顺序。','印章仍未回應，請確認碑文中的順序。','Los sellos siguen en silencio. Revisa el orden de la inscripción.','印は静かなままです。碑文の順番を確かめましょう。'),
    'puzzle_solve':('Awaken the seals','唤醒印章','喚醒印章','Despertar los sellos','印を目覚めさせる'),
    'expedition':('Enter the expedition','开始远征','開始遠征','Iniciar expedición','遠征を始める'),
    'expedition_desc':('An old testing ground lies beyond this arch. Survive three waves to recover its cache. You can withdraw safely; your normal death rules still apply if you fall.','拱门后是古老试炼场。撑过三波敌人即可取回藏品。你可随时撤退；若倒下，仍遵循本旅程的死亡规则。','拱門後是古老試煉場。撐過三波敵人即可取回藏品。你可隨時撤退；若倒下，仍遵循本旅程的死亡規則。','Tras el arco hay un antiguo campo de pruebas. Supera tres oleadas para recuperar el cofre. Puedes retirarte; si caes se aplican las reglas de muerte de tu viaje.','門の先には古い試練場があります。3波を越えると宝箱を回収できます。途中で撤退も可能です。倒れた場合は、この旅の死亡ルールが適用されます。'),
    'wave':('Expedition · Wave {wave} / 3 · Depth {depth}','远征 · 第{wave} / 3波 · 深度{depth}','遠征 · 第{wave} / 3波 · 深度{depth}','Expedición · Oleada {wave} / 3 · Profundidad {depth}','遠征・第{wave}波 / 3・深度{depth}'),
    'expedition_win':('Expedition complete. The next depth is open. Return to the arch when you are ready.','远征完成，下一深度已开放。准备好后可重返拱门。','遠征完成，下一深度已開放。準備好後可重返拱門。','Expedición completada. Se abre la siguiente profundidad. Vuelve al arco cuando estés listo.','遠征を達成し、次の深度が開きました。準備ができたら門へ戻りましょう。'),
    'withdraw_expedition':('Withdraw from the expedition','撤离远征','撤離遠征','Retirarse de la expedición','遠征から撤退する'),
    'peaceful_survey':('Study the ruins: 6 stone and 2 amber','研究遗迹：6份石料与2块琥珀','研究遺跡：6份石料與2塊琥珀','Estudiar las ruinas: 6 de piedra y 2 de ámbar','遺跡を研究：石6個と琥珀2個'),
    'plant':('Plant one garden seed','播种一份种子','播種一份種子','Plantar una semilla','種を1個まく'),
    'harvest_crop':('Harvest the crop','收获作物','收穫作物','Cosechar','作物を収穫する'),
    'growing':('Ready in {seconds} seconds of world time.','还需{seconds}秒世界时间成熟。','還需{seconds}秒世界時間成熟。','Estará listo en {seconds} segundos de tiempo de juego.','ゲーム内時間であと{seconds}秒です。'),
    'plant_hint':('Plant a seed, then let the garden grow. Bloom and the Green Thumb skill shorten the wait.','播下种子，等待菜畦成长。繁茂流向与园艺巧手技能可缩短等待。','播下種子，等待菜畦成長。繁茂流向與園藝巧手技能可縮短等待。','Planta una semilla y deja crecer el bancal. Florecer y Buena mano reducen la espera.','種をまいて育てましょう。芽吹きの力と緑の手のスキルで早く育ちます。'),
    'collect':('Collect produce','收取产物','收取產物','Recoger producción','収穫物を受け取る'),
    'open_gate':('Open or close the gate','开关木门','開關木門','Abrir o cerrar la puerta','門を開閉する'),
    'fish_wait':('Line cast. Wait for a bite, then press interact again. Moving away cancels the cast.','已抛竿。等鱼咬钩后再次互动，走远会收回钓线。','已拋竿。等魚咬鉤後再次互動，走遠會收回釣線。','Anzuelo lanzado. Espera a que pique y vuelve a interactuar. Alejarte cancela la pesca.','糸を垂らしました。かかったら再び調べましょう。離れると釣りを中断します。'),
    'fish_missed':('The fish slipped away. Cast again when you are ready.','鱼儿溜走了，准备好后再抛竿吧。','魚兒溜走了，準備好後再拋竿吧。','El pez se escapó. Vuelve a lanzar cuando quieras.','魚に逃げられました。もう一度、糸を垂らしてみましょう。'),
    'fishing_record':('Fish caught: {count} · Best catch: {weight} kg','钓获：{count}条 · 最大：{weight}千克','釣獲：{count}條 · 最大：{weight}公斤','Capturas: {count} · Récord: {weight} kg','釣った数：{count}・最大：{weight} kg'),
    'request_today':('Request completed. Come back tomorrow for another delivery.','今日委托已完成，明天再来交付新的物资吧。','今日委託已完成，明天再來交付新的物資吧。','Petición completada. Vuelve mañana para otra entrega.','今日の依頼は完了です。また明日、届け物をお願いします。'),
    'request_cost':('Requested: {materials}','所需：{materials}','所需：{materials}','Se necesita: {materials}','必要な品：{materials}'),
    'request_reward':('Reward: {rewards} · {xp} experience · {rep} goodwill','报酬：{rewards} · {xp}经验 · {rep}好感','報酬：{rewards} · {xp}經驗 · {rep}好感','Recompensa: {rewards} · {xp} de experiencia · {rep} de confianza','報酬：{rewards}・経験値{xp}・信頼{rep}'),
    'goodwill':('Camp goodwill: {count}','营地好感：{count}','營地好感：{count}','Confianza del campamento: {count}','キャンプの信頼：{count}'),
    'trade':('Trade with the camp','与营地交易','與營地交易','Comerciar con el campamento','キャンプで交換する'),
    'trade_hint':('Trade amber for supplies. Complete requests to earn goodwill and unlock more stock.','用琥珀换取物资。完成委托可提升好感，解锁更多货品。','用琥珀換取物資。完成委託可提升好感，解鎖更多貨品。','Cambia ámbar por suministros. Completa peticiones para ganar confianza y ampliar las existencias.','琥珀で物資を交換できます。依頼を達成して信頼を得ると、品ぞろえが増えます。'),
    'price':('{count} amber','{count}块琥珀','{count}塊琥珀','{count} de ámbar','琥珀{count}個'),
    'courier':('Courier routes','驿递路线','驛遞路線','Rutas de mensajería','配達路線'),
    'courier_hint':('Place a chest and a hearth within three tiles of each board. Restore both regions, choose a destination, then send a shipment. Materials arrive after 30 seconds of world time.','每块告示板三格内需放置箱子与炉火。修复两地路碑后，选择目的地寄出物资。30秒世界时间后材料送达。','每塊告示板三格內需放置箱子與爐火。修復兩地路碑後，選擇目的地寄出物資。30秒世界時間後材料送達。','Pon un cofre y una hoguera a tres casillas de cada tablón. Restaura ambas regiones y elige destino. Los materiales llegan tras 30 segundos de juego.','各掲示板から3マス以内にチェストと炉火が必要です。両地域を修復して送り先を選ぶと、ゲーム内時間30秒で素材が届きます。'),
    'send_shipment':('Send stored materials','寄出箱内材料','寄出箱內材料','Enviar materiales guardados','預けた素材を送る'),
    'shipment_sent':('The courier has set out. Your materials are safe in transit.','驿递员已出发，材料正在安全运送中。','驛遞員已出發，材料正在安全運送中。','El mensajero ha partido. Tus materiales viajan a salvo.','配達員が出発しました。素材は安全に運ばれています。'),
    'shipment_arrived':('A courier delivered supplies to your camp.','驿递员已将物资送至营地。','驛遞員已將物資送至營地。','Un mensajero ha entregado suministros al campamento.','キャンプに物資が届きました。'),
    'route_incomplete':('This route needs a chest, hearth and board at both ends, with restored waystones in both regions.','路线两端均需箱子、炉火与告示板，且两地路碑都需修复。','路線兩端均需箱子、爐火與告示板，且兩地路碑都需修復。','La ruta necesita cofre, hoguera y tablón en ambos extremos, y los hitos de ambas regiones restaurados.','両端にチェスト、炉火、掲示板を用意し、両地域の道標を修復しましょう。'),
    'route_pending':('This chest is reserved for an incoming shipment. Wait for it to arrive before dismantling it.','此箱有在途货物，请等送达后再拆除。','此箱有在途貨物，請等送達後再拆除。','Este cofre espera un envío. Déjalo hasta que llegue.','このチェストには配達中の荷物があります。届くまで解体できません。'),
    'production':('Station production','设备加工','設備加工','Producción','設備の加工'),
    'queue':('Queue one batch','加工一批','加工一批','Preparar un lote','1回分を加工する'),
    'production_hint':('Queued materials are stored in the station. Collect finished batches here. Ember makes processing 25% faster.','排队材料存放于设备中，完成后在此领取。余烬流向可使加工加快25%。','排隊材料存放於設備中，完成後在此領取。餘燼流向可使加工加快25%。','Los materiales quedan en la estación. Recoge aquí los lotes terminados. Ascua reduce el tiempo un 25 %.','加工する素材は設備に保管されます。完成品はここで受け取れます。熾火の力で所要時間が25%短くなります。'),
    'queued':('Queued batches: {count}','排队批次：{count}','排隊批次：{count}','Lotes en cola: {count}','加工待ち：{count}回分'),
    'queue_full':('This station already has five batches queued. Collect or wait for them to finish.','此设备已有五批加工，请领取成品或等待完成。','此設備已有五批加工，請領取成品或等待完成。','La estación tiene cinco lotes en cola. Recoge lo terminado o espera.','加工待ちが5回分あります。完成品を受け取るか、少し待ちましょう。'),
    'weather_clear':('Clear skies','晴朗','晴朗','Cielo despejado','晴れ'),
    'weather_rain':('Rain','降雨','降雨','Lluvia','雨'),
    'weather_storm':('Storm','风暴','風暴','Tormenta','嵐'),
    'exposure_warning':('You are getting cold. Warm yourself near a hearth or shelter.','你正在失温，请靠近炉火或进入庇护所取暖。','你正在失溫，請靠近爐火或進入庇護所取暖。','Estás perdiendo calor. Busca una hoguera o un refugio.','体が冷えています。炉火や住まいのそばで温まりましょう。'),
    'rematch':('Challenge the warden again','再次挑战守卫','再次挑戰守衛','Volver a desafiar al guardián','守り手に再び挑む'),
    'loot':('Collect dropped supplies','收取地上物资','收取地上物資','Recoger suministros caídos','落ちた物資を拾う'),
    'confirm':('Confirm','确认','確認','Confirmar','決定'),
    'difficulty_change':('Change game difficulty','更改游戏难度','更改遊戲難度','Cambiar dificultad','難易度を変更'),
    'death_fixed':('Death rules stay fixed for this journey.','本旅程的死亡规则无法更改。','本旅程的死亡規則無法更改。','Las reglas de muerte de este viaje son permanentes.','この旅の死亡ルールは変更できません。'),
    }
    for key,values in ui.items():text('ui.'+key,*values)
    text('ui.trinket','Equip charm','装备饰物','裝備飾物','Equipar amuleto','お守りを装備')
    text('ui.active_effects','Active provisions: {effects}','生效补给：{effects}','生效補給：{effects}','Efectos activos: {effects}','食事の効果：{effects}')
    text('ui.pack_slots','Backpack: {used} / {total} slots · Level {level}','背包：{used} / {total}格 · 等级{level}','背包：{used} / {total}格 · 等級{level}','Mochila: {used} / {total} espacios · Nivel {level}','持ち物：{used} / {total}枠・レベル{level}')
    text('ui.plant_choice','Choose what to plant','选择种植物','選擇種植物','Elige qué plantar','育てる作物を選ぶ')
    text('ui.loadout','Equipped: {weapon} · {armor} · {charm}','装备：{weapon} · {armor} · {charm}','裝備：{weapon} · {armor} · {charm}','Equipo: {weapon} · {armor} · {charm}','装備：{weapon}・{armor}・{charm}')
    text('ui.creature_stats','Health {health} · Hit damage {damage}','生命{health} · 命中伤害{damage}','生命{health} · 命中傷害{damage}','Salud {health} · Daño por golpe {damage}','体力{health}・攻撃力{damage}')
    text('ui.creature_drops','Supplies: {items}','可获得：{items}','可獲得：{items}','Suministros: {items}','手に入る物：{items}')
    for key,values in {
    'charge':('Braces before rushing in a straight line. Step aside, then strike during recovery.','蓄势后直线冲撞。侧移躲开，趁其恢复时反击。','蓄勢後直線衝撞。側移躲開，趁其恢復時反擊。','Se prepara y carga en línea recta. Apártate y ataca mientras se recupera.','構えてから直線的に突進します。横へよけ、立て直す間に攻撃しましょう。'),
    'leap':('Pauses before a quick lunge. Keep enough stamina to dodge the marked direction.','短暂停顿后迅速扑击，留足体力以避开标示方向。','短暫停頓後迅速撲擊，留足體力以避開標示方向。','Se detiene antes de abalanzarse. Reserva energía para esquivar la dirección marcada.','一瞬止まってから素早く飛びかかります。示された方向をよけるため、スタミナを残しましょう。'),
    'ranged':('Aims before firing. Keep moving across its line of attack. Wardens fire a spread when weakened.','瞄准后发射。横向移动避开火线，守卫虚弱时会发动散射。','瞄準後發射。橫向移動避開火線，守衛虛弱時會發動散射。','Apunta antes de disparar. Muévete de lado. Los guardianes debilitados disparan en abanico.','狙いを定めてから発射します。射線を横切るように動きましょう。弱った守り手は拡散弾を放ちます。'),
    'shield':('Its armor blocks much of your damage. Attack after it commits to a strike.','护甲会挡下大部分伤害。等其出招后的破绽再反击。','護甲會擋下大部分傷害。等其出招後的破綻再反擊。','Su armadura bloquea parte del daño. Ataca después de su golpe.','鎧がダメージを防ぎます。攻撃を繰り出した直後を狙いましょう。'),
    'melee':('Closes in, winds up, then strikes nearby. Back away during the windup and return after the blow.','靠近后蓄力近击，蓄力时后退，出招后再上前。','靠近後蓄力近擊，蓄力時後退，出招後再上前。','Se acerca, se prepara y golpea. Retrocede mientras se prepara y vuelve tras el golpe.','近づいて構えてから攻撃します。構えたら離れ、振り終わったところへ戻りましょう。'),
    'passive':('Wildlife avoids people. It will flee when you approach.','野生动物会避开人，靠近时会逃走。','野生動物會避開人，靠近時會逃走。','La fauna evita a las personas y huye cuando te acercas.','人を避ける野生動物です。近づくと逃げていきます。')}.items():text('behavior.'+key,*values)
    text('quest.peaceful_warden','Prepare a restoration offering at the Brackenreach waystone.','在蕨野原路碑处准备修复供奉。','在蕨野原路碑處準備修復供奉。','Prepara una ofrenda de restauración en el hito de las Praderas.','ワラビ野の道標に修復の供物を準備する。')
    kinds=[
    ('cache',('Forgotten stores','遗落补给','遺落補給','Provisiones olvidadas','忘れられた物資'),('Someone left a weatherproof chest here. Its supplies may still be useful.','有人在此留下了防雨箱，里面的物资也许还能用。','有人在此留下了防雨箱，裡面的物資也許還能用。','Alguien dejó un cofre protegido de la lluvia. Quizá sus suministros aún sirvan.','雨を防ぐチェストが残されています。中の物資はまだ役立つかもしれません。')),
    ('survey',('Survey tower','测绘望台','測繪望臺','Torre de agrimensura','測量の見張り台'),('The old sighting marks still line up with distant ridges. A careful survey will reveal nearby land.','古老的瞄准标记仍对着远方山脊，仔细测绘可揭开周围土地的面貌。','古老的瞄準標記仍對著遠方山脊，仔細測繪可揭開周圍土地的面貌。','Las marcas siguen alineadas con las cumbres. Un estudio revelará los alrededores.','古い標線は今も遠くの尾根を指しています。測量すれば周囲の土地がわかりそうです。')),
    ('puzzle',('Three-current seal','三流印台','三流印臺','Sello de las tres corrientes','三つの力の印'),('Three worn seals turn around a single socket. Their inscription survived the weather.','三枚磨损的印章围着凹槽转动，上面的碑文尚未风化。','三枚磨損的印章圍著凹槽轉動，上面的碑文尚未風化。','Tres sellos gastados giran en torno a una cavidad. La inscripción ha resistido el tiempo.','三つの古い印が一つのくぼみを囲んでいます。碑文はまだ読めそうです。')),
    ('spring',('Travelers’ spring','旅人泉','旅人泉','Manantial de viajeros','旅人の泉'),('Clear water rises between the stones. Restock your water before the next trail.','清水从石缝间涌出，为下一段路补足饮水吧。','清水從石縫間湧出，為下一段路補足飲水吧。','Brota agua limpia entre las piedras. Repón tus reservas antes de seguir.','石の間から澄んだ水が湧いています。次の道へ進む前に水を補給しましょう。')),
    ('grove',('Returning grove','归生林地','歸生林地','Arboleda renaciente','芽吹きの林'),('Saplings struggle in a broken terrace. Seeds and water could bring this place back to life.','幼苗在破败梯田中挣扎，种子与清水可以让此地复苏。','幼苗在破敗梯田中掙扎，種子與清水可以讓此地復甦。','Los brotes luchan en una terraza rota. Con semillas y agua, este lugar volverá a vivir.','崩れた段丘で苗木が育とうとしています。種と水で、この場所をよみがえらせましょう。')),
    ('expedition',('Keeper’s trial','守望者试炼','守望者試煉','Prueba del guardián','守り手の試練'),('A stone arch marks an old proving ground. Every completed expedition opens a harder depth.','石拱标示着古老试炼场，每完成一次远征便会开放更深的挑战。','石拱標示著古老試煉場，每完成一次遠征便會開放更深的挑戰。','Un arco de piedra señala el campo de pruebas. Cada expedición completada abre una profundidad mayor.','石の門が古い試練場を示しています。遠征を達成するたび、より深い挑戦が開きます。'))]
    pois=[]
    offsets=[[-16,-14],[18,-11],[-20,12],[14,18],[-8,22],[23,16]]
    for region in range(5):
        for index,(kind,names,descs) in enumerate(kinds):
            key=f'{regions[region]["id"]}_{kind}'
            text('poi.'+key+'.name',*(names[i]+' · '+[['Brackenreach','Reedglass Fen','Cinderstep','Stormpine Heights','Hollow Meridian'][region],['蕨野原','苇镜沼泽','烬阶荒地','风松高地','空寂中庭'][region],['蕨野原','葦鏡沼澤','燼階荒地','風松高地','空寂中庭'][region],['Praderas','Marisma','Ceniza','Altos','Meridiano'][region],['ワラビ野','葦鏡','灰踏み','嵐松','中庭'][region]][i] for i in range(5)))
            text('poi.'+key+'.desc',*descs)
            pois.append({'id':key,'region':region,'kind':kind,'offset':offsets[index],'name_key':'poi.'+key+'.name','description_key':'poi.'+key+'.desc'})
    requests=[]
    materials=[({'wood':12,'fiber':8},{'amber':4,'ration':2}),({'stone':16,'rope':3},{'amber':5,'bandage':3}),({'vegetable':8,'mushroom':5},{'amber':6,'stew':3}),({'copper_ore':12,'charcoal':4},{'amber':8,'iron_ore':4}),({'honey':4,'gel':5},{'amber':8,'tonic':2}),({'cloth':4,'ration':4},{'amber':10,'storm_shard':4}),({'stone':20,'brick':8},{'amber':10,'glass':3}),({'relic':8,'glass':6},{'amber':14,'tonic':4})]
    for i,npc in enumerate(npcs):
        npc['region']=[0,0,1,1,2,3,3,4][i]
        costs,rewards=materials[i]
        for variant in range(2):
            requests.append({'id':npc['id']+'_'+str(variant),'npc':npc['id'],'cost':costs if variant==0 else {key:max(1,int(value*1.4)) for key,value in costs.items()},'reward':rewards if variant==0 else {key:max(1,int(value*1.3)) for key,value in rewards.items()},'xp':65+i*15,'goodwill':10})
    production=[{'id':key,'station':recipes[key]['station'],'seconds':20 if key in ['roast','tea','grilled_fish'] else 35} for key in ['charcoal','brick','copper','iron','cloth','glass','ration','roast','stew','grilled_fish','tea']]
    for definition in production:recipes[definition['id']]['production_seconds']=definition['seconds']
    from expand_provisions import expand_provisions
    extra=expand_provisions(text,item,recipes)
    production.extend(extra.pop('production_extra',[]))
    overrides={
    'floor':('A continuous timber foundation. Furniture and walls can stand on top.','连续铺设的木质地面，其上可放置家具和墙体。','連續鋪設的木質地面，其上可放置家具和牆體。','Suelo continuo de madera. Puedes colocar muebles y muros encima.','つなげて敷ける木の床。上に家具や壁を置けます。'),
    'path':('Mark a route through your camp with packed dirt and stepping stones.','用夯土与踏石标出穿过营地的路线。','用夯土與踏石標出穿過營地的路線。','Marca los caminos del campamento con tierra y piedras.','土と踏み石で、キャンプの道を整えます。'),
    'wall':('Blocks movement through a tile. Leave a gate so you can get back inside.','阻挡一格内的通行，记得留一扇门以便进出。','阻擋一格內的通行，記得留一扇門以便進出。','Impide el paso por una casilla. Deja una puerta para poder entrar.','1マス分の通行を防ぎます。出入りできるよう、門を残しましょう。'),
    'fence':('A low barrier for shaping gardens and camp boundaries. Blocks passage.','可围出田园与营地边界的矮篱，会阻挡通行。','可圍出田園與營地邊界的矮籬，會阻擋通行。','Barrera baja para delimitar huertos y campamentos. Impide el paso.','畑やキャンプを囲む低い柵。通り抜けを防ぎます。'),
    'gate':('Interact to open or close the entrance. An open gate allows passage.','互动即可开关出入口，开启后可以通行。','互動即可開關出入口，開啟後可以通行。','Interactúa para abrir o cerrar. Abierta, permite el paso.','調べると開閉できます。開けた門は通り抜けられます。'),
    'tent':('Shelter from storms. Interact to set your return point and rest.','躲避风暴的庇护所，互动可设为归处并休息。','躲避風暴的庇護所，互動可設為歸處並休息。','Refugio frente a las tormentas. Permite fijar tu regreso y descansar.','嵐をしのぐ住まい。調べると帰還地点を設定して休めます。'),
    'lantern':('Lights the ground around it after sunset. Needs no fuel.','日落后照亮周围地面，无需燃料。','日落後照亮周圍地面，無需燃料。','Ilumina el suelo cercano al anochecer. No necesita combustible.','日が暮れると周囲を照らします。燃料は不要です。'),
    'waypost':('A trail marker. Interact to open your atlas and plan the next leg.','路上的标记，互动可展开图志，规划下一段行程。','路上的標記，互動可展開圖誌，規劃下一段行程。','Un hito del sendero. Abre el atlas para planear tu siguiente tramo.','道に立てる目印。調べると地図帳を開けます。'),
    'mill':('Grinds harvested grain into flour. Queue batches here and collect them when ready.','将收获的谷物磨成面粉，可在此排队加工并领取成品。','將收穫的穀物磨成麵粉，可在此排隊加工並領取成品。','Muele grano y produce harina. Prepara lotes y recógelos cuando terminen.','収穫した穀物を粉に挽きます。加工を頼み、できあがった粉を受け取りましょう。'),
    'windmill':('Nearby processing stations finish batches 25% sooner. Place within four tiles.','四格内的加工设备耗时缩短25%。','四格內的加工設備耗時縮短25%。','Las estaciones a cuatro casillas tardan un 25 % menos por lote.','4マス以内の加工設備の所要時間が25%短くなります。'),
    'scarecrow':('Gardens within three tiles yield one extra crop.','三格内的菜畦每次额外产出一份作物。','三格內的菜畦每次額外產出一份作物。','Los bancales a tres casillas producen una unidad adicional.','3マス以内の畑で、作物を1個多く収穫できます。'),
    'bookshelf':('A home for maps and field notes. Interact to read your journal.','存放地图与野外笔记，互动可阅读日志。','存放地圖與野外筆記，互動可閱讀日誌。','Guarda mapas y notas. Interactúa para leer el diario.','地図と野帳を置く棚。調べると旅日誌を読めます。'),
    'planter':('Bring a patch of flowers home. A decorative touch for your camp.','将一丛鲜花带回家，装点你的营地。','將一叢鮮花帶回家，妝點你的營地。','Lleva flores a casa y da color al campamento.','花を家に持ち帰り、キャンプを彩ります。'),
    'rug':('A woven floor covering. Place furniture on top to make a welcoming room.','编织地毯，上方可放置家具，营造温馨房间。','編織地毯，上方可放置家具，營造溫馨房間。','Una alfombra tejida. Coloca muebles encima para crear una sala acogedora.','家具を上に置ける敷物。心地よい部屋を作りましょう。'),
    }
    for key,desc in overrides.items():text('item.'+key+'.desc',*desc)
    return {'points_of_interest':pois,'requests':requests,'production':production,**extra}
