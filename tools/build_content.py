"""Author the game's data and five authored locale catalogs. Python standard library only."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'godot/data'
LOCALE = ROOT / 'godot/locale'
LANGS = ['en', 'zh_CN', 'zh_TW', 'es', 'ja']
CAT = {lang: {} for lang in LANGS}

def text(key, *values):
    assert len(values) == 5, (key, len(values))
    for lang, value in zip(LANGS, values):
        CAT[lang][key] = value

UI = {
'title': ('The Mossbound Atlas','苔生图志','苔生圖誌','El atlas del verdor','苔むす世界の地図'),
'subtitle': ('Find a path. Make a home. Bring the world together.','踏出新路，安下新家，让世界再度相连。','踏出新路，安下新家，讓世界再度相連。','Abre caminos. Construye un hogar. Reconecta el mundo.','道を拓き、家を築き、世界をつなぐ。'),
'new': ('Begin a journey','开启旅程','開啟旅程','Comenzar un viaje','旅を始める'),
'continue': ('Continue your journey','继续旅程','繼續旅程','Continuar el viaje','旅を続ける'),
'worlds': ('Your journeys','你的旅程','你的旅程','Tus viajes','旅の記録'),
'settings': ('Settings','设置','設定','Ajustes','設定'),
'changelog': ('What’s new','更新内容','更新內容','Novedades','更新履歴'),
'quit': ('Quit game','退出游戏','退出遊戲','Salir del juego','ゲームを終了'),
'back': ('Back','返回','返回','Volver','戻る'),
'close': ('Close','关闭','關閉','Cerrar','閉じる'),
'create': ('Set out','出发','出發','Emprender el viaje','出発する'),
'name': ('Journey name','旅程名称','旅程名稱','Nombre del viaje','旅の名前'),
'seed': ('World seed (leave blank for a new world)','世界种子（留空即可随机生成）','世界種子（留空即可隨機產生）','Semilla del mundo (vacía para generar una nueva)','ワールドのシード値（空欄ならランダム）'),
'difficulty': ('Game difficulty','游戏难度','遊戲難度','Dificultad','ゲームの難易度'),
'death_mode': ('When you fall','死亡后果','死亡後果','Al morir','倒れたとき'),
'language': ('Language','语言','語言','Idioma','言語'),
'music': ('Music','音乐','音樂','Música','音楽'),
'effects': ('Sound effects','音效','音效','Efectos de sonido','効果音'),
'fullscreen': ('Fullscreen','全屏','全螢幕','Pantalla completa','フルスクリーン'),
'reduce_motion': ('Reduce screen shake','减弱画面震动','減弱畫面震動','Reducir el temblor de pantalla','画面の揺れを抑える'),
'resume': ('Return to the wilds','返回野外','返回野外','Volver a la aventura','冒険に戻る'),
'save': ('Save journey','保存旅程','儲存旅程','Guardar viaje','旅を保存'),
'save_quit': ('Save and return to title','保存并返回标题画面','儲存並返回標題畫面','Guardar y volver al título','保存してタイトルへ'),
'saved': ('Journey saved.','旅程已保存。','旅程已儲存。','Viaje guardado.','旅を保存しました。'),
'saving': ('Saving your journey…','正在保存旅程……','正在儲存旅程……','Guardando el viaje…','旅を保存しています…'),
'save_failed': ('Could not save. Your previous save is safe. Check available disk space and try again.','保存失败。之前的存档仍然安全。请检查剩余磁盘空间后重试。','儲存失敗。先前的存檔仍然安全。請檢查剩餘磁碟空間後重試。','No se pudo guardar. Tu partida anterior está a salvo. Comprueba el espacio disponible e inténtalo de nuevo.','保存できませんでした。前のセーブデータは無事です。空き容量を確認して、もう一度お試しください。'),
'load_failed': ('This journey could not be opened. A backup may still be available.','无法打开这段旅程。你仍可尝试使用备份。','無法開啟這段旅程。你仍可嘗試使用備份。','No se pudo abrir este viaje. Puede que haya una copia de seguridad disponible.','この旅を開けませんでした。バックアップから復元できる場合があります。'),
'newer_save': ('This journey was saved with a newer game version. Update the game to open it.','此存档来自较新的游戏版本。请更新游戏后再打开。','此存檔來自較新的遊戲版本。請更新遊戲後再開啟。','Este viaje se guardó con una versión más reciente. Actualiza el juego para abrirlo.','この旅は新しいバージョンで保存されています。ゲームを更新してから開いてください。'),
'empty_saves': ('Your next adventure starts here. Begin a new journey to create your first world.','下一场冒险就在这里开始。开启新旅程，创建你的第一个世界。','下一場冒險就在這裡開始。開啟新旅程，建立你的第一個世界。','Tu próxima aventura empieza aquí. Comienza un viaje para crear tu primer mundo.','次の冒険はここから。新しい旅を始めて、最初の世界を作りましょう。'),
'inventory': ('Backpack','背包','背包','Mochila','持ち物'),
'crafting': ('Crafting','制作','製作','Fabricación','クラフト'),
'building': ('Building','建造','建造','Construcción','建築'),
'atlas': ('Atlas','图志','圖誌','Atlas','地図帳'),
'journal': ('Journal','日志','日誌','Diario','旅日誌'),
'perks': ('Skills','技能','技能','Habilidades','スキル'),
'health': ('Health','生命','生命','Salud','体力'),
'stamina': ('Stamina','体力','體力','Energía','スタミナ'),
'food': ('Food','饱腹','飽食','Alimento','満腹度'),
'water': ('Water','饮水','飲水','Agua','水分'),
'warmth': ('Exposure','环境影响','環境影響','Exposición','環境の影響'),
'craft': ('Craft','制作','製作','Fabricar','作る'),
'equip': ('Equip','装备','裝備','Equipar','装備する'),
'use': ('Use','使用','使用','Usar','使う'),
'place': ('Place','放置','放置','Colocar','設置する'),
'ingredients': ('Materials','所需材料','所需材料','Materiales','必要な素材'),
'requires': ('Requires: {name}','需要：{name}','需要：{name}','Requiere: {name}','必要な設備：{name}'),
'missing': ('You need more materials.','材料还不够。','材料還不夠。','Te faltan materiales.','素材が足りません。'),
'bag_full': ('Your backpack is full. Store something in a chest first.','背包已满。先把一些物品放进箱子里。','背包已滿。先把一些物品放進箱子裡。','Tu mochila está llena. Guarda algo en un cofre.','持ち物がいっぱいです。先にチェストへ預けましょう。'),
'crafted': ('Made {name} ×{count}.','已制作{name} ×{count}。','已製作{name} ×{count}。','Has fabricado {name} ×{count}.','{name}を{count}個作りました。'),
'gained': ('{name} +{count}','{name} +{count}','{name} +{count}','{name} +{count}','{name} +{count}'),
'empty_bag': ('Your backpack is empty. Gather supplies from the plants and stones nearby.','背包里空空如也。去附近的植物和石块处收集物资吧。','背包裡空空如也。去附近的植物和石塊處收集物資吧。','Tu mochila está vacía. Recoge plantas y piedras cercanas.','持ち物は空です。近くの草木や石から素材を集めましょう。'),
'locked': ('Discover more of the world to learn this recipe.','继续探索世界，学习这份配方。','繼續探索世界，學習這份配方。','Explora el mundo para aprender esta receta.','世界を探索すると、このレシピを覚えられます。'),
'tier': ('Crafting tier {tier}','制作等级 {tier}','製作等級 {tier}','Nivel de fabricación {tier}','クラフト段階 {tier}'),
'interact': ('Interact','互动','互動','Interactuar','調べる'),
'harvest': ('Gather {name}','采集{name}','採集{name}','Recoger {name}','{name}を採る'),
'talk': ('Speak to {name}','与{name}交谈','與{name}交談','Hablar con {name}','{name}と話す'),
'open': ('Open {name}','打开{name}','開啟{name}','Abrir {name}','{name}を開く'),
'rest': ('Rest until morning','休息到清晨','休息到清晨','Descansar hasta el amanecer','朝まで休む'),
'set_home': ('Your hearth is now your home.','已将这处炉火设为归处。','已將這處爐火設為歸處。','Esta hoguera es ahora tu hogar.','この炉火を帰還地点にしました。'),
'no_placement': ('There is no room here. Choose clear ground within reach.','这里放不下。请选择触手可及的空地。','這裡放不下。請選擇觸手可及的空地。','Aquí no hay sitio. Busca suelo despejado a tu alcance.','ここには置けません。手の届く空き地を選びましょう。'),
'build_hint': ('Choose a piece · Left click: place · Right click: cancel · R: dismantle','选择建筑部件 · 左键：放置 · 右键：取消 · R：拆除','選擇建築部件 · 左鍵：放置 · 右鍵：取消 · R：拆除','Elige una pieza · Clic izq.: colocar · Clic der.: cancelar · R: desmontar','部材を選択 · 左クリック：設置 · 右クリック：解除 · R：解体'),
'dismantled': ('Recovered the building materials.','已回收建筑材料。','已回收建築材料。','Has recuperado los materiales.','建築素材を回収しました。'),
'need_tool': ('You need a better tool to gather this.','需要更好的工具才能采集。','需要更好的工具才能採集。','Necesitas una herramienta mejor.','採取には、もっと良い道具が必要です。'),
'out_of_range': ('Move closer.','再靠近一点。','再靠近一點。','Acércate un poco más.','もう少し近づきましょう。'),
'day': ('Day {day}','第 {day} 天','第 {day} 天','Día {day}','{day}日目'),
'night': ('Nightfall','夜幕降临','夜幕降臨','Anochecer','日暮れ'),
'dawn': ('A new day begins.','新的一天开始了。','新的一天開始了。','Comienza un nuevo día.','新しい一日が始まりました。'),
'controls': ('WASD / Left stick: move · E / A: interact · Left click / RT: use tool · Space / B: dodge · Tab / Y: backpack · Esc: pause','WASD / 左摇杆：移动 · E / A：互动 · 左键 / RT：使用工具 · 空格 / B：闪避 · Tab / Y：背包 · Esc：暂停','WASD / 左搖桿：移動 · E / A：互動 · 左鍵 / RT：使用工具 · 空白鍵 / B：閃避 · Tab / Y：背包 · Esc：暫停','WASD / Palanca izq.: moverse · E / A: interactuar · Clic izq. / RT: usar herramienta · Espacio / B: esquivar · Tab / Y: mochila · Esc: pausa','WASD / 左スティック：移動 · E / A：調べる · 左クリック / RT：道具を使う · Space / B：回避 · Tab / Y：持ち物 · Esc：一時停止'),
'objective': ('Your next step','下一步','下一步','Tu siguiente paso','次の一歩'),
'welcome': ('You found the old survey camp. Speak to Mara beside the hearth.','你找到了旧测绘营地。去和炉火旁的玛拉谈谈。','你找到了舊測繪營地。去和爐火旁的瑪拉談談。','Has encontrado el antiguo campamento. Habla con Mara junto a la hoguera.','古い測量キャンプを見つけました。炉火のそばにいるマーラと話しましょう。'),
'low_food': ('You are hungry. Eat something from your backpack.','你饿了。吃点背包里的食物吧。','你餓了。吃點背包裡的食物吧。','Tienes hambre. Come algo de tu mochila.','お腹が空いています。持ち物の食べ物を食べましょう。'),
'low_water': ('Your canteen is low. Gather water at a spring.','水快喝完了。去泉水处补充饮水吧。','水快喝完了。去泉水處補充飲水吧。','Te queda poca agua. Busca un manantial.','水分が不足しています。泉で水を補給しましょう。'),
'dead': ('The trail grows quiet','旅途暂歇','旅途暫歇','El sendero queda en silencio','静まり返る道'),
'respawn': ('Return to your hearth','返回归处','返回歸處','Volver a tu hogar','炉火へ戻る'),
'grave': ('Your belongings are marked on the atlas.','你的遗物已标在图志上。','你的遺物已標在圖誌上。','Tus pertenencias están señaladas en el atlas.','落とした持ち物の場所を地図帳に記しました。'),
'retired': ('This journey has ended. Your world and discoveries remain in the atlas.','这段旅程已经结束。你的世界与发现仍留在图志中。','這段旅程已經結束。你的世界與發現仍留在圖誌中。','Este viaje ha terminado. Tu mundo y tus descubrimientos permanecen en el atlas.','この旅は終わりました。築いた世界と発見は地図帳に残ります。'),
'recover': ('Recover your belongings','取回遗物','取回遺物','Recuperar tus pertenencias','持ち物を回収'),
'recovered': ('Your belongings are back in your pack.','遗物已放回背包。','遺物已放回背包。','Has recuperado tus pertenencias.','持ち物を回収しました。'),
'restore': ('Restore the waystone','修复路碑','修復路碑','Restaurar el hito','道標を修復する'),
'restore_cost': ('Offer 8 wood, 6 stone and 2 amber to restore this landmark.','献上8份木材、6份石料与2块琥珀，修复这处地标。','獻上8份木材、6份石料與2塊琥珀，修復這處地標。','Entrega 8 de madera, 6 de piedra y 2 de ámbar para restaurar este lugar.','木材8個、石6個、琥珀2個を捧げると、この道標を修復できます。'),
'restored': ('The waystone wakes. New paths are open.','路碑苏醒了。新的道路已向你敞开。','路碑甦醒了。新的道路已向你敞開。','El hito despierta. Se abren nuevos caminos.','道標が目覚め、新たな道が開けました。'),
'attune': ('Choose the region’s current','选择区域流向','選擇區域流向','Elige la corriente de la región','この地域を流れる力を選ぶ'),
'bloom': ('Bloom','繁茂','繁茂','Florecer','芽吹き'),
'ember': ('Ember','余烬','餘燼','Ascua','熾火'),
'gale': ('Gale','长风','長風','Vendaval','疾風'),
'bloom_desc': ('Plants recover faster. Gardens and wildlife flourish.','植物恢复得更快，田园与野生动物更加繁盛。','植物恢復得更快，田園與野生動物更加繁盛。','Las plantas se recuperan antes. Prosperan los cultivos y la fauna.','植物の再生が早まり、畑と野生動物が豊かになります。'),
'ember_desc': ('Processing stations work faster. Mineral harvests improve.','加工设备运转更快，矿物采集收获增加。','加工設備運轉更快，礦物採集收穫增加。','Las estaciones trabajan más deprisa y obtienes más minerales.','加工設備が速く働き、鉱物の収穫も増えます。'),
'gale_desc': ('Travel faster and spend less stamina while exploring.','探索时移动更快，消耗的体力更少。','探索時移動更快，消耗的體力更少。','Viajas más rápido y gastas menos energía al explorar.','探索時の移動が速くなり、スタミナの消費が減ります。'),
'warden': ('Challenge the regional warden','挑战区域守卫','挑戰區域守衛','Desafiar al guardián','地域の守り手に挑む'),
'warden_warning': ('Prepare food and healing supplies first. You may leave the clearing if you need to recover.','请先备好食物与疗伤物资。需要恢复时，可以离开这片空地。','請先備好食物與療傷物資。需要恢復時，可以離開這片空地。','Prepara comida y curación. Puedes abandonar el claro para recuperarte.','食べ物と回復アイテムを準備しましょう。回復が必要なら、広場から離れることもできます。'),
'warden_down': ('The region’s warden has fallen. Your atlas reveals new knowledge.','区域守卫已被击败。图志中显现了新的知识。','區域守衛已被擊敗。圖誌中顯現了新的知識。','El guardián ha caído. Tu atlas revela nuevos conocimientos.','地域の守り手を倒しました。地図帳に新たな知識が現れます。'),
'peaceful_restore': ('Complete the restoration offering','完成修复供奉','完成修復供奉','Completar la ofrenda de restauración','修復の供物を捧げる'),
'victory': ('The roads remember','道路重现','道路重現','Los caminos recuerdan','道は覚えている'),
'ending': ('The atlas is complete, but your story is not. Travelers are returning, the hearths are warm, and the wilds still hold their secrets. Your settlements remain yours to grow.','图志已经绘就，你的故事却还未完结。旅人陆续归来，炉火重燃，荒野仍藏着秘密。继续经营你亲手建立的家园吧。','圖誌已經繪就，你的故事卻還未完結。旅人陸續歸來，爐火重燃，荒野仍藏著祕密。繼續經營你親手建立的家園吧。','El atlas está completo, pero tu historia continúa. Los viajeros regresan, las hogueras calientan y la naturaleza aún guarda secretos. Tus asentamientos pueden seguir creciendo.','地図帳は完成しました。でも、あなたの物語は続きます。旅人が戻り、炉火が灯り、荒野にはまだ秘密が残っています。築いた集落を、これからも育てていきましょう。'),
'keep_playing': ('Keep exploring','继续探索','繼續探索','Seguir explorando','探索を続ける'),
'level': ('Level {level}','等级 {level}','等級 {level}','Nivel {level}','レベル {level}'),
'points': ('Skill points: {count}','技能点：{count}','技能點：{count}','Puntos de habilidad: {count}','スキルポイント：{count}'),
'learn': ('Learn skill','学习技能','學習技能','Aprender habilidad','スキルを覚える'),
'known': ('Learned','已学会','已學會','Aprendida','習得済み'),
'map_help': ('Your hearth, waystones, settlements and lost belongings appear here. Unexplored land is hidden until you visit it.','归处、路碑、聚落与遗物的位置都会标在这里。尚未探索的土地会在你到访后显现。','歸處、路碑、聚落與遺物的位置都會標在這裡。尚未探索的土地會在你到訪後顯現。','Aquí se muestran tu hogar, los hitos, los poblados y tus pertenencias perdidas. Visita nuevas tierras para descubrirlas.','炉火、道標、集落、落とした持ち物の場所を表示します。未探索の土地は、訪れると明らかになります。'),
'search': ('Search items or recipes…','搜索物品或配方……','搜尋物品或配方……','Buscar objetos o recetas…','アイテムやレシピを検索…'),
'all': ('All','全部','全部','Todo','すべて'),
'travel': ('Travel to a connected hearth','前往相连的炉火','前往相連的爐火','Viajar a una hoguera conectada','つながった炉火へ移動'),
'travel_blocked': ('Lose nearby enemies before traveling.','先摆脱附近的敌人再出发。','先擺脫附近的敵人再出發。','Aléjate de los enemigos antes de viajar.','近くの敵を振り切ってから移動しましょう。'),
'chest_hint': ('Store all materials','存入全部材料','存入全部材料','Guardar todos los materiales','素材をすべて預ける'),
'withdraw': ('Take all','全部取出','全部取出','Recoger todo','すべて取り出す'),
'contract': ('Travelers’ requests','旅人委托','旅人委託','Peticiones de viajeros','旅人の依頼'),
'deliver': ('Deliver supplies','交付物资','交付物資','Entregar suministros','物資を届ける'),
'contract_desc': ('The camp needs 12 wood and 8 fiber. Deliver them for amber, provisions and experience.','营地需要12份木材与8份纤维。交付后可获得琥珀、补给与经验。','營地需要12份木材與8份纖維。交付後可獲得琥珀、補給與經驗。','El campamento necesita 12 de madera y 8 de fibra. Entrégalos a cambio de ámbar, provisiones y experiencia.','キャンプでは木材12個と繊維8個を必要としています。届けると琥珀、食料、経験値を受け取れます。'),
'contract_done': ('The travelers thank you. Your supplies will keep their camp going.','旅人们向你道谢。你的物资能让营地继续维持下去。','旅人們向你道謝。你的物資能讓營地繼續維持下去。','Los viajeros te dan las gracias. Tus suministros mantendrán el campamento.','旅人たちに感謝されました。届けた物資がキャンプの支えになります。'),
'fishing': ('Cast your line beside water. Watch for the splash, then interact again.','在水边抛竿。看到水花时，再按一次互动键。','在水邊拋竿。看到水花時，再按一次互動鍵。','Lanza el anzuelo junto al agua. Cuando salpique, vuelve a interactuar.','水辺で釣り糸を垂らし、水しぶきが見えたらもう一度調べるボタンを押しましょう。'),
'bite': ('A bite! Reel it in!','上钩了！快收竿！','上鉤了！快收竿！','¡Ha picado! ¡Recoge el sedal!','かかった！ 引き上げよう！'),
'rested': ('You feel rested. Your health and stamina have recovered.','休息过后，你的生命与体力都恢复了。','休息過後，你的生命與體力都恢復了。','Te sientes descansado. Has recuperado salud y energía.','よく休めました。体力とスタミナが回復しました。'),
'storm': ('A storm is approaching. Shelter will protect you from the cold.','暴风雨即将来临。到庇护所里避寒吧。','暴風雨即將來臨。到庇護所裡避寒吧。','Se acerca una tormenta. Busca refugio para protegerte del frío.','嵐が近づいています。寒さをしのげる場所に避難しましょう。'),
'credits': ('Created for The Mossbound Atlas · Original art, music and sound · Built with Godot','为《苔生图志》创作 · 原创美术、音乐与音效 · 使用Godot制作','為《苔生圖誌》創作 · 原創美術、音樂與音效 · 使用Godot製作','Creado para El atlas del verdor · Arte, música y sonido originales · Hecho con Godot','「苔むす世界の地図」のために制作 · オリジナルのアート・音楽・効果音 · Godot製'),
'version': ('Version {version}','版本 {version}','版本 {version}','Versión {version}','バージョン {version}'),
'loading': ('Unfolding your atlas…','正在展开图志……','正在展開圖誌……','Desplegando tu atlas…','地図帳を広げています…'),
'read_only': ('This journey is preserved in the atlas. You can view the map, but this character cannot return.','这段旅程已珍藏于图志中。你可以查看地图，但这位角色无法再踏上旅途。','這段旅程已珍藏於圖誌中。你可以查看地圖，但這位角色無法再踏上旅途。','Este viaje se conserva en el atlas. Puedes consultar el mapa, pero este personaje no puede regresar.','この旅は地図帳に残されています。地図を見ることはできますが、この人物の旅を再開することはできません。'),
}
for key, values in UI.items(): text('ui.'+key, *values)

DIFFICULTIES = [
('peaceful',('Peaceful','和平','和平','Pacífica','ピースフル'),('Explore and build at your own pace. Restore the world through offerings instead of required battles.','自在探索与建造，通过供奉修复世界，无需强制战斗。','自在探索與建造，透過供奉修復世界，無需強制戰鬥。','Explora y construye a tu ritmo. Restaura el mundo con ofrendas sin combates obligatorios.','自分のペースで探索と建築を楽しめます。戦闘の代わりに供物で世界を修復できます。'),0,0,0),
('easy',('Easy','简单','簡單','Fácil','イージー'),('Gentler enemies and slower hunger and thirst. A welcoming first journey.','敌人更弱，饥饿与口渴增长更慢，适合初次踏上旅途。','敵人較弱，飢餓與口渴增加較慢，適合初次踏上旅途。','Enemigos más suaves y menos hambre y sed. Ideal para tu primer viaje.','敵が手強すぎず、空腹や渇きもゆっくり進みます。初めての旅におすすめです。'),0.7,0.75,0.6),
('normal',('Normal','普通','普通','Normal','ノーマル'),('Prepare for the wilds, learn your enemies and make each expedition count.','为荒野做好准备，了解敌人，让每次远行都满载而归。','為荒野做好準備，了解敵人，讓每次遠行都滿載而歸。','Prepárate, aprende de tus enemigos y aprovecha cada expedición.','荒野への備えと敵の観察が、実りある探索につながります。'),1,1,1),
('hard',('Hard','困难','困難','Difícil','ハード'),('Dangerous encounters and harsher conditions reward careful preparation.','遭遇更危险，环境更严酷，周全的准备将带来回报。','遭遇更危險，環境更嚴酷，周全的準備將帶來回報。','Los encuentros peligrosos y el clima duro exigen buena preparación.','危険な敵と厳しい環境が待っています。入念な準備が生死を分けます。'),1.35,1.2,1.15),
('insane',('Insane','极限','極限','Extrema','インセイン'),('For experienced survivors. Strong enemies leave little room for mistakes.','适合经验丰富的生存者。强敌不会给你太多犯错的机会。','適合經驗豐富的生存者。強敵不會給你太多犯錯的機會。','Para supervivientes expertos. Los enemigos dejan poco margen de error.','熟練の生存者向けです。強敵を相手に、わずかな油断も命取りになります。'),1.7,1.4,1.35)]
for k,n,d,*_ in DIFFICULTIES: text('difficulty.'+k,*n); text('difficulty.'+k+'.desc',*d)
for k,n,d in [
('easycore',('Easycore','轻度死亡惩罚','輕度死亡懲罰','Sin pérdida de objetos','アイテムを保持'),('Return to your hearth with everything you were carrying.','带着全部随身物品回到归处。','帶著全部隨身物品回到歸處。','Regresas a tu hogar con todos tus objetos.','持ち物をすべて保持して炉火に戻ります。')),
('mediumcore',('Mediumcore','遗物回收','遺物回收','Recuperación de objetos','アイテムを回収'),('Your belongings stay where you fell. Return to collect them.','随身物品留在倒下的位置，需要返回取回。','隨身物品留在倒下的位置，需要返回取回。','Tus objetos quedan donde caíste. Vuelve para recuperarlos.','倒れた場所に持ち物が残ります。戻って回収しましょう。')),
('hardcore',('Hardcore','永久死亡','永久死亡','Muerte permanente','永久の死'),('One life. Death ends this character’s journey permanently.','只有一次生命。死亡将永久结束这位角色的旅程。','只有一次生命。死亡將永久結束這位角色的旅程。','Una sola vida. La muerte pone fin al viaje de este personaje.','命は一度きり。倒れると、この人物の旅は永久に終わります。'))]:
    text('death.'+k,*n);text('death.'+k+'.desc',*d)

REGION_NAMES = [
('bracken',('Brackenreach','蕨野原','蕨野原','Praderas del Helecho','ワラビ野')),
('fen',('Reedglass Fen','苇镜沼泽','葦鏡沼澤','Marisma de Cristal','葦鏡の湿地')),
('cinder',('Cinderstep','烬阶荒地','燼階荒地','Tierras de Ceniza','灰踏みの荒地')),
('storm',('Stormpine Heights','风松高地','風松高地','Altos del Pino','嵐松の高原')),
('hollow',('Hollow Meridian','空寂中庭','空寂中庭','Meridiano Hueco','うつろの中庭'))]
REGIONS=[]
for i,(key,names) in enumerate(REGION_NAMES):
    text('region.'+key,*names)
    REGIONS.append({'id':key,'tier':min(i+1,4),'index':i,'name_key':'region.'+key})

ITEMS={}; RECIPES={}; STRUCTURES={}
def item(key,names,descs,**fields):
    text('item.'+key+'.name',*names);text('item.'+key+'.desc',*descs)
    ITEMS[key]={'name':names[0],'name_key':'item.'+key+'.name','description_key':'item.'+key+'.desc','stack':99,'kind':'material','tier':1,'icon':len(ITEMS),**fields}

MATERIALS=[
('wood',('Wood','木材','木材','Madera','木材'),('Gathered from trees and fallen branches. Used for shelters, tools and fuel.','从树木和落枝中获得，可用于搭建庇护所、制作工具及生火。','從樹木和落枝中獲得，可用於搭建庇護所、製作工具及生火。','Se obtiene de árboles y ramas caídas. Sirve para refugios, herramientas y combustible.','木や落ち枝から採れます。住まい、道具、燃料に使います。')),
('stone',('Stone','石料','石料','Piedra','石'),('Gather loose stones or break rock outcrops. A sturdy foundation for tools and buildings.','拾取散石或开采岩块获得，是制作工具和建造的基础材料。','拾取散石或開採岩塊獲得，是製作工具和建造的基礎材料。','Recoge piedras sueltas o rompe rocas. Esencial para herramientas y edificios.','落ちている石や岩から採れます。道具や建物の基礎になる丈夫な素材です。')),
('fiber',('Plant fiber','植物纤维','植物纖維','Fibra vegetal','植物の繊維'),('Gathered from tall grasses. Twist it into rope or weave it into useful supplies.','从高草中采集，可搓成绳索或编成实用物资。','從高草中採集，可搓成繩索或編成實用物資。','Se recoge de hierbas altas. Úsala para cuerdas y suministros tejidos.','背の高い草から採れます。縄や布製の道具の材料になります。')),
('amber',('Sun amber','日珀','日珀','Ámbar solar','陽の琥珀'),('Warm resin found among old roots and in travelers’ rewards. An offering for sleeping waystones.','可在老树根附近找到，也可通过旅人委托获得。用于供奉沉睡的路碑。','可在老樹根附近找到，也可透過旅人委託獲得。用於供奉沉睡的路碑。','Resina cálida que encuentras entre raíces antiguas y como recompensa. Despierta los hitos.','古い根元で見つかる温かな樹脂。依頼の報酬でも手に入り、道標への供物に使えます。')),
('raw_meat',('Raw meat','生肉','生肉','Carne cruda','生肉'),('Cook this at a cooking pot before eating. Gathered from wild animals.','从野生动物身上获得。请先用炊锅烹熟再食用。','從野生動物身上獲得。請先用炊鍋烹熟再食用。','Se obtiene de animales. Cocínala en una olla antes de comerla.','野生動物から手に入ります。食べる前に鍋で調理しましょう。')),
('hide',('Hide','兽皮','獸皮','Piel','獣の皮'),('Tough animal hide for protective clothing, straps and sturdy grips.','结实的兽皮，可用于防护衣物、绑带和耐用的握柄。','結實的獸皮，可用於防護衣物、綁帶和耐用的握柄。','Piel resistente para ropa protectora, correas y empuñaduras.','防具や革ひも、握りやすい柄の材料になる丈夫な皮です。')),
('reed',('Glass reed','镜苇','鏡葦','Junco de cristal','鏡の葦'),('A hollow wetland reed. Used for bows, fishing tackle and woven furniture.','生于湿地的中空苇草，可用于弓、渔具和编织家具。','生於濕地的中空葦草，可用於弓、漁具和編織家具。','Junco hueco de humedal. Se usa en arcos, aparejos y muebles tejidos.','湿地に生える中空の葦。弓や釣り具、編み家具に使います。')),
('clay',('River clay','河泥','河泥','Arcilla de río','川の粘土'),('Soft clay from the wetlands. Fire it in a kiln for stronger building materials.','来自湿地的软泥，可在窑中烧制成更坚固的建材。','來自濕地的軟泥，可在窯中燒製成更堅固的建材。','Arcilla de los humedales. Cuécela en un horno para hacer materiales resistentes.','湿地で採れる柔らかな粘土。窯で焼くと丈夫な建材になります。')),
('copper_ore',('Copper ore','铜矿石','銅礦石','Mineral de cobre','銅鉱石'),('Orange-veined stone. Smelt it into copper at a smelter.','带有橙色矿脉的石头，可用熔炉炼成铜锭。','帶有橙色礦脈的石頭，可用熔爐煉成銅錠。','Piedra con vetas anaranjadas. Fúndela para obtener cobre.','橙色の鉱脈を含む石。溶鉱炉で銅のインゴットに加工できます。')),
('copper',('Copper ingot','铜锭','銅錠','Lingote de cobre','銅のインゴット'),('Smelted copper for reliable weapons, tools and workshop fittings.','精炼的铜，可制作可靠的武器、工具及工坊配件。','精煉的銅，可製作可靠的武器、工具及工坊配件。','Cobre fundido para armas, herramientas y piezas de taller.','武器や道具、工房の部品に使う精錬済みの銅です。')),
('iron_ore',('Iron ore','铁矿石','鐵礦石','Mineral de hierro','鉄鉱石'),('Heavy ore from the Cinderstep. A copper pick can break its dark seams.','产自烬阶荒地的沉重矿石，需要铜镐才能开采。','產自燼階荒地的沉重礦石，需要銅鎬才能開採。','Mineral pesado de las Tierras de Ceniza. Se extrae con un pico de cobre.','灰踏みの荒地で採れる重い鉱石。銅のつるはしで掘れます。')),
('iron',('Iron ingot','铁锭','鐵錠','Lingote de hierro','鉄のインゴット'),('Smelted iron for equipment that can withstand the highlands.','精炼的铁，可制成足以应对高地险境的装备。','精煉的鐵，可製成足以應對高地險境的裝備。','Hierro fundido para equipo capaz de resistir las tierras altas.','高原の厳しい環境に耐える装備の材料になる鉄です。')),
('storm_shard',('Storm shard','风晶','風晶','Fragmento de tormenta','嵐の結晶'),('A crystal that hums in strong wind. Gather it in Stormpine with an iron pick.','会在强风中轻鸣的结晶，需要铁镐才能在风松高地采集。','會在強風中輕鳴的結晶，需要鐵鎬才能在風松高地採集。','Cristal que vibra con el viento. Se extrae en los Altos con un pico de hierro.','強風で音を立てる結晶。嵐松の高原で鉄のつるはしを使うと採れます。')),
('glass',('Meridian glass','中庭琉璃','中庭琉璃','Vidrio del meridiano','中庭の玻璃'),('Clear remnants of the old network. Used for the finest tools and resonance equipment.','古代网络留下的透亮碎片，可制作精良工具与共鸣装具。','古代網絡留下的透亮碎片，可製作精良工具與共鳴裝具。','Restos transparentes de la antigua red. Sirven para herramientas y equipo de resonancia.','古い網の透き通ったかけら。上等な道具や共鳴の装備に使います。')),
('charcoal',('Charcoal','木炭','木炭','Carbón vegetal','木炭'),('Wood slowly fired in a kiln. A clean, lasting fuel for metalworking.','木材在窑中慢烧而成，是炼制金属的耐烧燃料。','木材在窯中慢燒而成，是煉製金屬的耐燒燃料。','Madera cocida lentamente. Combustible duradero para trabajar metales.','窯で木をじっくり焼いた燃料。金属の加工に使います。')),
('brick',('Fired brick','烧砖','燒磚','Ladrillo','レンガ'),('Clay fired into a lasting building material. Used for hearths and stronger walls.','烧制而成的耐用建材，可用于炉火与坚固墙壁。','燒製而成的耐用建材，可用於爐火與堅固牆壁。','Arcilla cocida para hogares y muros más resistentes.','粘土を焼いた丈夫な建材。炉や頑丈な壁を作れます。')),
('rope',('Rope','绳索','繩索','Cuerda','縄'),('Twisted plant fiber. Holds bridges, tools and shelters together.','搓紧的植物纤维，可用于桥梁、工具和庇护所。','搓緊的植物纖維，可用於橋梁、工具和庇護所。','Fibra trenzada para puentes, herramientas y refugios.','植物の繊維をよったもの。橋、道具、住まいをつなぎます。')),
('cloth',('Woven cloth','织布','織布','Tela','織り布'),('Soft woven fiber for clothing, tents and home comforts.','柔软的编织纤维，可制作衣物、帐篷及家居用品。','柔軟的編織纖維，可製作衣物、帳篷及家居用品。','Fibra tejida para ropa, tiendas y comodidades del hogar.','衣服やテント、家具に使える柔らかな布です。')),
('seed',('Garden seed','菜种','菜種','Semilla de huerto','野菜の種'),('Plant in a garden bed. After several minutes of daylight, harvest fresh vegetables.','种在菜畦中，经过几分钟日照后即可收获新鲜蔬菜。','種在菜畦中，經過幾分鐘日照後即可收穫新鮮蔬菜。','Plántala en un bancal. Tras unos minutos de luz podrás cosechar verduras.','畑にまくと、日中の数分間で育ち、新鮮な野菜を収穫できます。')),
('gel',('Dew gel','露胶','露膠','Gel de rocío','露のしずく'),('A cool gel left by wetland creatures. Used in healing salves and lamps.','湿地生物留下的清凉凝胶，可用于疗伤膏与灯具。','濕地生物留下的清涼凝膠，可用於療傷膏與燈具。','Gel fresco de criaturas del humedal. Sirve para ungüentos y lámparas.','湿地の生き物が残す冷たいしずく。軟膏や明かりの材料になります。')),
('venom_sac',('Bitter sac','苦囊','苦囊','Saco amargo','苦みの袋'),('Handled carefully, its bitter oils make powerful expedition tonics.','小心处理其中的苦油，可制成强效远行药剂。','小心處理其中的苦油，可製成強效遠行藥劑。','Sus aceites amargos sirven para preparar tónicos de expedición.','中の苦い油を慎重に扱うと、探索用の強力な薬を作れます。')),
('feather',('Wind feather','风羽','風羽','Pluma del viento','風切り羽'),('A light, strong feather for arrows, charms and highland equipment.','轻而坚韧的羽毛，可用于箭矢、护符和高地装备。','輕而堅韌的羽毛，可用於箭矢、護符和高地裝備。','Pluma ligera y resistente para flechas, amuletos y equipo de montaña.','軽く丈夫な羽根。矢やお守り、高原用の装備に使います。')),
('relic',('Survey relic','测绘遗物','測繪遺物','Reliquia de agrimensor','測量の遺物'),('A surviving piece of the old survey network. Bring it to a resonance bench.','古代测绘网络的残件，可在共鸣台上利用。','古代測繪網絡的殘件，可在共鳴台上利用。','Pieza de la antigua red de agrimensura. Úsala en una mesa de resonancia.','かつての測量網の部品。共鳴台で役立ちます。'))]
for key,n,d in MATERIALS:item(key,n,d)

FOODS=[
('berry',('Wild berries','野莓','野莓','Bayas silvestres','野イチゴ'),12,0,0),
('water',('Spring water','泉水','泉水','Agua de manantial','泉の水'),0,35,0),
('mushroom',('Field mushroom','原野菇','原野菇','Seta de campo','野のキノコ'),8,0,0),
('vegetable',('Garden vegetables','园蔬','園蔬','Verduras del huerto','畑の野菜'),22,8,0),
('fish',('Fresh fish','鲜鱼','鮮魚','Pescado fresco','釣りたての魚'),10,0,0),
('honey',('Wild honey','野蜜','野蜜','Miel silvestre','野のハチミツ'),16,0,6),
('roast',('Campfire roast','营火烤肉','營火烤肉','Carne asada','焚き火の焼き肉'),42,0,15),
('stew',('Trail stew','行旅炖菜','行旅燉菜','Estofado de viaje','旅人のシチュー'),48,20,20),
('grilled_fish',('Herb-grilled fish','香草烤鱼','香草烤魚','Pescado a las hierbas','香草焼き魚'),38,0,16),
('ration',('Travel provisions','远行口粮','遠行口糧','Provisiones de viaje','旅の保存食'),55,12,10),
('tea',('Reed tea','苇叶茶','葦葉茶','Infusión de junco','葦の葉茶'),0,55,8),
('salve',('Healing salve','疗伤膏','療傷膏','Ungüento curativo','傷薬'),0,0,38),
('bandage',('Clean bandage','洁净绷带','潔淨繃帶','Venda limpia','清潔な包帯'),0,0,20),
('tonic',('Restoring tonic','复元药剂','復元藥劑','Tónico reconstituyente','回復の薬'),12,15,60)]
for key,n,food,water,heal in FOODS:
    d=(f'Restores {food} food, {water} water and {heal} health. Use it from your backpack when needed.',f'恢复{food}点饱腹、{water}点饮水和{heal}点生命。需要时可在背包中使用。',f'恢復{food}點飽食、{water}點飲水和{heal}點生命。需要時可在背包中使用。',f'Recupera {food} de alimento, {water} de agua y {heal} de salud. Úsalo desde la mochila.',f'満腹度を{food}、水分を{water}、体力を{heal}回復します。必要なときに持ち物から使えます。')
    item(key,n,d,kind='consumable',effects={'hunger':food,'thirst':water,'health':heal,'stamina':min(heal+food,30)})

WEAPON_STYLES=[('blade',('Blade','短剑','短劍','Espada','短剣')),('spear',('Spear','长矛','長矛','Lanza','槍')),('bow',('Bow','弓','弓','Arco','弓')),('focus',('Resonance focus','共鸣器','共鳴器','Foco de resonancia','共鳴器')),('axe',('Axe','斧','斧','Hacha','斧')),('pick',('Pickaxe','镐','鎬','Pico','つるはし'))]
TIER_NAMES=[('field',('Trail','石制','石製','de campaña','石の'),'stone'),('copper',('Copper','铜制','銅製','de cobre','銅の'),'copper'),('iron',('Iron','铁制','鐵製','de hierro','鉄の'),'iron'),('storm',('Stormglass','风琉璃','風琉璃','de vidrio tormenta','嵐玻璃の'),'storm_shard')]
for tier,(prefix,pnames,mat) in enumerate(TIER_NAMES,1):
    for style,snames in WEAPON_STYLES:
        key=prefix+'_'+style
        names=(pnames[0]+' '+snames[0].lower(),pnames[1]+snames[1],pnames[2]+snames[2],snames[3]+' '+pnames[3],pnames[4]+snames[4])
        is_tool=style in ('axe','pick')
        desc=(f'A tier {tier} {snames[0].lower()}. '+('Use it to gather stronger materials and defend yourself.' if is_tool else 'Equip it, aim toward your target and use the attack button.'),f'{tier}阶{snames[1]}。'+('可采集更坚硬的材料，也能用来自卫。' if is_tool else '装备后朝目标瞄准，按攻击键即可使用。'),f'{tier}階{snames[2]}。'+('可採集更堅硬的材料，也能用來自衛。' if is_tool else '裝備後朝目標瞄準，按攻擊鍵即可使用。'),f'{snames[3]} de nivel {tier}. '+('Úsalo para recoger materiales resistentes y defenderte.' if is_tool else 'Equípalo, apunta y pulsa el botón de ataque.'),f'{tier}段階目の{snames[4]}。'+('硬い素材の採取と身を守るために使えます。' if is_tool else '装備して目標に向き、攻撃ボタンで使います。'))
        item(key,names,desc,kind='tool' if is_tool else 'weapon',style=style,tier=tier,stack=1,damage=[8,14,23,35][tier-1],reach=72 if style=='spear' else 45,cooldown=0.65 if style not in ('bow','focus') else 0.9)
        RECIPES[key]={'result':{'id':key,'count':1},'ingredients':[{'id':mat,'count':3+tier},{'id':'wood','count':3},{'id':'fiber','count':2}],'tier':tier,'station':'' if tier==1 else 'workbench' if tier==2 else 'forge' if tier==3 else 'resonator'}
    names=(pnames[0]+' field coat',pnames[1]+'外衣',pnames[2]+'外衣','Abrigo '+pnames[3],pnames[4]+'外套')
    desc=(f'Reduces incoming damage by {tier*2}. Equip from your backpack.',f'受到的伤害降低{tier*2}点。可在背包中装备。',f'受到的傷害降低{tier*2}點。可在背包中裝備。',f'Reduce el daño recibido en {tier*2}. Equípalo desde la mochila.',f'受けるダメージを{tier*2}軽減します。持ち物から装備できます。')
    item(prefix+'_coat',names,desc,kind='armor',tier=tier,armor=tier*2,stack=1)
    RECIPES[prefix+'_coat']={'result':{'id':prefix+'_coat','count':1},'ingredients':[{'id':mat,'count':4+tier},{'id':'hide','count':3},{'id':'fiber','count':4}],'tier':tier,'station':'' if tier==1 else 'workbench'}

BUILDINGS=[
('floor',('Timber floor','木地板','木地板','Suelo de madera','木の床'),'wood',2,'floor',1),
('path',('Packed trail','夯土小径','夯土小徑','Sendero firme','踏み固めた道'),'stone',1,'path',1),
('wall',('Timber wall','木墙','木牆','Muro de madera','木の壁'),'wood',4,'wall',1),
('fence',('Garden fence','园篱','園籬','Valla de huerto','庭の柵'),'wood',2,'fence',1),
('gate',('Timber gate','木门','木門','Puerta de madera','木の門'),'wood',4,'gate',1),
('bridge',('Footbridge','步桥','步橋','Pasarela','小さな橋'),'wood',5,'bridge',1),
('tent',('Canvas shelter','帆布庇护所','帆布庇護所','Refugio de lona','帆布の小屋'),'fiber',8,'shelter',1),
('bed',('Bedroll','铺盖','鋪蓋','Petate','寝袋'),'fiber',5,'bed',1),
('hearth',('Hearth','炉火','爐火','Hoguera','炉火'),'stone',6,'hearth',1),
('workbench',('Workbench','工作台','工作臺','Banco de trabajo','作業台'),'wood',8,'station',1),
('cooking_pot',('Cooking pot','炊锅','炊鍋','Olla de cocina','料理鍋'),'stone',5,'station',1),
('chest',('Storage chest','储物箱','儲物箱','Cofre','チェスト'),'wood',6,'chest',1),
('garden',('Garden bed','菜畦','菜畦','Bancal','畑'),'wood',3,'garden',1),
('well',('Stone well','石井','石井','Pozo de piedra','石の井戸'),'stone',12,'well',1),
('lantern',('Trail lantern','行路灯','行路燈','Farol del camino','道のランタン'),'wood',3,'light',1),
('waypost',('Waypost','路标','路標','Poste del camino','道しるべ'),'wood',3,'route',1),
('kiln',('Clay kiln','陶窑','陶窯','Horno de arcilla','粘土の窯'),'clay',6,'station',2),
('smelter',('Smelter','熔炉','熔爐','Fundición','溶鉱炉'),'stone',10,'station',2),
('forge',('Forge','锻炉','鍛爐','Forja','鍛冶炉'),'copper',6,'station',2),
('loom',('Loom','织机','織機','Telar','織り機'),'wood',8,'station',2),
('courier_board',('Courier board','驿递告示板','驛遞告示板','Tablón de mensajería','配達の掲示板'),'wood',8,'courier',2),
('fish_trap',('Fish trap','鱼篓','魚簍','Trampa para peces','魚のわな'),'reed',6,'trap',2),
('drying_rack',('Drying rack','晾晒架','晾曬架','Secadero','干し棚'),'wood',6,'station',2),
('planter',('Reed planter','苇编花盆','葦編花盆','Macetero de junco','葦の鉢植え'),'reed',4,'decor',1),
('banner',('Survey banner','测绘旗','測繪旗','Estandarte de agrimensor','測量隊の旗'),'fiber',6,'decor',1),
('stool',('Camp stool','营凳','營凳','Taburete','丸椅子'),'wood',3,'decor',1),
('table',('Writing table','书桌','書桌','Mesa de escritura','書き物机'),'wood',7,'decor',1),
('chair',('Wooden chair','木椅','木椅','Silla de madera','木の椅子'),'wood',4,'decor',1),
('rug',('Woven rug','编织地毯','編織地毯','Alfombra tejida','織り敷物'),'fiber',6,'floor',1),
('bookshelf',('Map shelves','地图书架','地圖書架','Estantería de mapas','地図の本棚'),'wood',10,'decor',2),
('sign',('Trail sign','行路牌','行路牌','Cartel del camino','道の看板'),'wood',3,'decor',1),
('windmill',('Windmill','风车','風車','Molino de viento','風車'),'iron',8,'station',3),
('mill',('Grain mill','磨坊','磨坊','Molino de grano','製粉機'),'stone',10,'station',2),
('apiary',('Beehive','蜂箱','蜂箱','Colmena','養蜂箱'),'wood',8,'apiary',2),
('scarecrow',('Scarecrow','稻草人','稻草人','Espantapájaros','かかし'),'fiber',8,'decor',1),
('stone_wall',('Stone wall','石墙','石牆','Muro de piedra','石の壁'),'brick',4,'wall',2),
('stone_floor',('Stone paving','石铺地','石鋪地','Pavimento de piedra','石畳'),'stone',3,'floor',1),
('stone_hearth',('Brick hearth','砖炉','磚爐','Hogar de ladrillo','レンガの炉'),'brick',8,'hearth',2),
('glass_lamp',('Meridian lamp','中庭灯','中庭燈','Lámpara del meridiano','中庭の明かり'),'glass',3,'light',4),
('resonator',('Resonance bench','共鸣台','共鳴臺','Mesa de resonancia','共鳴台'),'storm_shard',6,'station',4),
('fountain',('Courtyard spring','庭院泉','庭院泉','Fuente del patio','庭の泉'),'stone',12,'well',2)]
FUNCTION_DESCS={
'hearth':('A warm place to return to. Interact to set your home, rest or travel along restored routes.','温暖的归处。互动可设为家园、休息或沿已修复的道路旅行。','溫暖的歸處。互動可設為家園、休息或沿已修復的道路旅行。','Un lugar cálido al que regresar. Permite fijar tu hogar, descansar y viajar por rutas restauradas.','温かな帰還場所。調べると帰還地点の設定、休息、修復済みの道を使った移動ができます。'),
'garden':('Plant a seed here and return after it has grown. Harvest vegetables and a new seed.','播种后，待作物长成再来收获蔬菜与新的种子。','播種後，待作物長成再來收穫蔬菜與新的種子。','Planta una semilla y vuelve cuando crezca. Cosecharás verduras y otra semilla.','種をまいて育つのを待ちましょう。野菜と新しい種を収穫できます。'),
'chest':('Store materials safely. Nearby crafting stations can use the materials inside.','安全存放材料。附近制作时也能使用箱中的材料。','安全存放材料。附近製作時也能使用箱中的材料。','Guarda materiales a salvo. Puedes usarlos al fabricar cerca del cofre.','素材を安全に保管します。近くでクラフトすると、中の素材も使えます。'),
'station':('A crafting station. Stand nearby to make its recipes in the crafting menu.','制作设备。站在附近，即可在制作菜单中使用相应配方。','製作設備。站在附近，即可在製作選單中使用相應配方。','Estación de fabricación. Acércate para usar sus recetas en el menú.','クラフト用の設備。近くに立つと、クラフト画面で対応するレシピを使えます。'),
'well':('A dependable source of drinking water. Interact to refill your supplies.','可靠的饮水来源。互动即可补充饮水。','可靠的飲水來源。互動即可補充飲水。','Fuente fiable de agua potable. Interactúa para reponer tus reservas.','いつでも飲み水を補給できます。調べて水をくみましょう。'),
'bed':('A simple bed that makes your camp a comfortable resting place.','朴素的床铺，让营地成为舒适的休息之所。','樸素的床鋪，讓營地成為舒適的休息之所。','Una cama sencilla para descansar cómodamente en tu campamento.','キャンプで心地よく休める、簡素な寝床です。'),
'courier':('Connect a chest and a hearth nearby. Couriers move stored materials between your connected camps.','在附近放置储物箱与炉火。驿递员会在相连的营地间运送材料。','在附近放置儲物箱與爐火。驛遞員會在相連的營地間運送材料。','Coloca un cofre y una hoguera cerca. Los mensajeros transportan materiales entre campamentos conectados.','近くにチェストと炉火を置くと、つながったキャンプの間で素材が運ばれます。'),
'trap':('Set beside water. Return later to collect fish.','放在水边，过一段时间后回来收鱼。','放在水邊，過一段時間後回來收魚。','Colócala junto al agua. Vuelve más tarde para recoger pescado.','水辺に設置し、しばらく待って魚を回収しましょう。'),
'apiary':('A home for bees. Collect honey once the hive has had time to fill.','蜜蜂的新家。等待蜂巢积满后即可采蜜。','蜜蜂的新家。等待蜂巢積滿後即可採蜜。','Un hogar para abejas. Recoge miel cuando la colmena se llene.','ミツバチの住まい。蜜がたまるまで待つと、ハチミツを採れます。'),
'bridge':('Build over shallow water to make a safe crossing.','在浅水上搭建，铺出安全的过水道路。','在淺水上搭建，鋪出安全的過水道路。','Construye sobre aguas poco profundas para cruzarlas con seguridad.','浅瀬の上に架けると、安全に渡れるようになります。'),
}
for key,n,mat,cost,kind,tier in BUILDINGS:
    desc=FUNCTION_DESCS.get(kind,('A practical piece for making your camp your own. Place it on clear ground.','让营地更合心意的实用部件。可放在空地上。','讓營地更合心意的實用部件。可放在空地上。','Una pieza para dar personalidad a tu campamento. Colócala en suelo despejado.','キャンプを自分らしく整える部材です。空いている場所に置けます。'))
    item(key,n,desc,kind='building',tier=tier,stack=99)
    STRUCTURES[key]={'kind':kind,'solid':kind in ['wall','fence','station','chest','well','shelter','decor','apiary'],'cost':{mat:cost},'tier':tier,'art':len(STRUCTURES),'health':80+tier*40}
    RECIPES[key]={'result':{'id':key,'count':1},'ingredients':[{'id':mat,'count':cost}],'tier':tier,'station':''}

for key,ingredients,station,tier,count in [
('rope',{'fiber':3},'',1,1),('cloth',{'fiber':4},'loom',2,1),('charcoal',{'wood':3},'kiln',2,2),('brick',{'clay':2},'kiln',2,2),('copper',{'copper_ore':2,'wood':1},'smelter',2,1),('iron',{'iron_ore':2,'charcoal':1},'smelter',3,1),('glass',{'storm_shard':2,'relic':1},'resonator',4,2),('bandage',{'fiber':3},'',1,1),('roast',{'raw_meat':1,'wood':1},'cooking_pot',1,1),('stew',{'vegetable':2,'mushroom':1,'water':1},'cooking_pot',1,1),('grilled_fish',{'fish':1,'mushroom':1,'wood':1},'cooking_pot',1,1),('ration',{'roast':1,'berry':3},'drying_rack',2,2),('tea',{'reed':2,'water':1},'cooking_pot',1,1),('salve',{'mushroom':2,'gel':1},'workbench',2,1),('tonic',{'honey':1,'venom_sac':1,'water':1},'workbench',3,1)]:
    RECIPES[key]={'result':{'id':key,'count':count},'ingredients':[{'id':k,'count':v} for k,v in ingredients.items()],'station':station,'tier':tier}
item('fishing_rod',('Fishing rod','钓竿','釣竿','Caña de pescar','釣り竿'),UI['fishing'],kind='tool',style='fish',damage=2,stack=1)
RECIPES['fishing_rod']={'result':{'id':'fishing_rod','count':1},'ingredients':[{'id':'wood','count':3},{'id':'fiber','count':4}],'station':'','tier':1}

MOB_NAMES=[
('bristleback',('Bristleback','棘背野猪','棘背野豬','Lomo de púas','トゲイノシシ'),'charge'),('thornling',('Thornling','荆棘灵','荊棘靈','Zarzillo','イバラの子'),'melee'),('brush_prowler',('Brush prowler','林丛潜猫','林叢潛貓','Acechador del matorral','ヤブヤマネコ'),'leap'),
('reed_lurker',('Reed lurker','苇丛伏蛙','葦叢伏蛙','Acechador del junco','アシガエル'),'leap'),('tidejaw',('Tidejaw','潮颚鳄','潮顎鱷','Mandíbula de marea','シオアゴワニ'),'shield'),('lantern_moth',('Lantern moth','灯翅蛾','燈翅蛾','Polilla farol','トウロウガ'),'ranged'),
('ash_crawler',('Ash crawler','灰甲虫','灰甲蟲','Escarabajo de ceniza','ハイムシ'),'melee'),('slag_gnaw',('Slag gnawer','熔渣啮兽','熔渣齧獸','Roedor de escoria','スラグイ'),'charge'),('cinder_wasp',('Cinder wasp','烬蜂','燼蜂','Avispa de ascua','ヒバチ'),'ranged'),
('gustwing',('Gustwing','疾风翼','疾風翼','Ala de vendaval','ハヤテドリ'),'leap'),('pine_wraith',('Pine wraith','松影灵','松影靈','Espectro del pino','マツカゲ'),'ranged'),('antlerbound',('Antlerbound','缚角鹿','縛角鹿','Ciervo ligado','ツノシバリ'),'charge'),
('brass_sentry',('Brass sentry','黄铜哨卫','黃銅哨衛','Centinela de latón','真鍮の歩哨'),'shield'),('glass_weaver',('Glass weaver','琉璃织蛛','琉璃織蛛','Tejedor de vidrio','ハリグモ'),'ranged'),('echo_husk',('Echo husk','回声空壳','回聲空殼','Cascarón de eco','残響の抜け殻'),'leap'),
('hare',('Meadow hare','草原兔','草原兔','Liebre de pradera','野ウサギ'),'passive'),('deer',('Fallow deer','原野鹿','原野鹿','Gamo','野のシカ'),'passive'),('fox',('Red fox','赤狐','赤狐','Zorro rojo','アカギツネ'),'passive'),('crane',('Marsh crane','沼鹤','沼鶴','Grulla de marisma','湿地のツル'),'passive'),('tortoise',('Moss tortoise','苔背龟','苔背龜','Tortuga de musgo','コケガメ'),'passive'),
('old_briar',('Old Briar','古荆守卫','古荊守衛','Viejo Espino','古きイバラ'),'boss_charge'),('reedmother',('The Reedmother','苇泽之母','葦澤之母','Madre del Junco','葦原の母'),'boss_ranged'),('cinder_heart',('Cinder Heart','烬心','燼心','Corazón de Ascua','熾火の心臓'),'boss_charge'),('storm_stag',('The Storm Stag','风暴之鹿','風暴之鹿','Ciervo de la Tormenta','嵐の大鹿'),'boss_leap'),('atlas_keeper',('The Atlas Keeper','图志守望者','圖誌守望者','Guardián del Atlas','地図帳の守り手'),'boss_ranged')]
MOBS={}
for i,(key,n,pattern) in enumerate(MOB_NAMES):
    boss=i>=20; passive=15<=i<20
    region=(i-20 if boss else i//3 if i<15 else [0,3,2,1,4][i-15])
    tier=min(region+1,4)
    text('mob.'+key,*n)
    drops=[{'id':['raw_meat','gel','iron_ore','feather','relic'][region],'count':2 if not boss else 8}]
    if passive:drops=[{'id':'raw_meat','count':1},{'id':'hide','count':1}]
    if boss:drops.append({'id':'amber','count':8})
    MOBS[key]={'name':n[0],'name_key':'mob.'+key,'behavior':'passive' if passive else 'ranged' if 'ranged' in pattern else 'aggressive','pattern':pattern,'region':region,'tier':tier,'health':(180+region*130) if boss else 18+tier*12,'speed':38 if boss else 35+tier*5,'damage':(9+region*4) if boss else 3+tier*2,'aggro_range':190,'attack_range':160 if 'ranged' in pattern else 30,'attack_cooldown':1.8 if boss else 1.5,'biomes':[REGIONS[region]['id']],'drops':drops,'boss':boss,'passive':passive,'art':i}

NPC_NAMES=[('mara',('Mara · Cartographer','玛拉 · 绘图师','瑪拉 · 繪圖師','Mara · Cartógrafa','マーラ・地図師')),('ivo',('Ivo · Carpenter','伊沃 · 木匠','伊沃 · 木匠','Ivo · Carpintero','イーヴォ・大工')),('suri',('Suri · Camp cook','苏莉 · 营厨','蘇莉 · 營廚','Suri · Cocinera','スーリ・料理人')),('bo',('Bo · Prospector','博 · 矿工','博 · 礦工','Bo · Prospector','ボウ・探鉱家')),('sela',('Sela · Herbalist','塞拉 · 草药师','塞拉 · 草藥師','Sela · Herbolaria','セラ・薬草師')),('neri',('Neri · Courier','内莉 · 驿递员','內莉 · 驛遞員','Neri · Mensajera','ネリ・配達人')),('toma',('Toma · Waykeeper','托马 · 守路人','托馬 · 守路人','Toma · Guardacaminos','トーマ・道守')),('elin',('Elin · Archivist','艾琳 · 典藏员','艾琳 · 典藏員','Elin · Archivera','エリン・記録係'))]
NPC_DIALOGUE=[
('The roads used to meet here. Now even the trees have forgotten them. Gather wood and stone, make this camp your home, then follow the old trail east to the sleeping waystone. I marked it in your atlas.','从前，所有道路都在这里交汇。如今，连树木都忘了它们。先收集木材和石料，把这里安顿成家，再沿旧路向东寻找沉睡的路碑。我已经在你的图志上标好了位置。','從前，所有道路都在這裡交會。如今，連樹木都忘了它們。先收集木材和石料，把這裡安頓成家，再沿舊路向東尋找沉睡的路碑。我已經在你的圖誌上標好了位置。','Los caminos se cruzaban aquí. Ahora hasta los árboles los han olvidado. Reúne madera y piedra, instala tu hogar y sigue el sendero al este hasta el hito dormido. Lo he marcado en tu atlas.','昔はここで道が交わっていたの。今では木々まで道を忘れてしまった。まず木と石を集めて、ここを住まいにしてね。それから古い道を東へ進めば、眠る道標があるわ。地図帳に印をつけておいたから。'),
('A good camp begins with a dry floor and a place for your tools. Build a workbench nearby and you can make copper equipment. Chests keep your supplies safe and let you craft without carrying everything.','好营地要有干燥的地板，还得有放工具的地方。附近建个工作台，就能制作铜制装备。箱子既能保管物资，也能让你不用背着全部材料来制作。','好營地要有乾燥的地板，還得有放工具的地方。附近建個工作臺，就能製作銅製裝備。箱子既能保管物資，也能讓你不用背著全部材料來製作。','Un buen campamento necesita un suelo seco y sitio para las herramientas. Un banco te permitirá fabricar equipo de cobre. Guarda materiales en cofres: podrás usarlos al fabricar cerca.','いいキャンプには乾いた床と、道具を置く場所がいる。近くに作業台を置けば、銅の装備が作れるよ。素材はチェストに預けな。近くにいれば、中の素材もクラフトに使える。'),
('Warm food turns a difficult journey into a manageable one. A cooking pot makes meat and fish much more nourishing. Bring vegetables and mushrooms if you want a proper stew.','热乎的饭菜能让艰难旅途轻松些。用炊锅烹调，肉和鱼就更顶饿。要是想吃一锅像样的炖菜，记得带上蔬菜和蘑菇。','熱乎的飯菜能讓艱難旅途輕鬆些。用炊鍋烹調，肉和魚就更耐餓。要是想吃一鍋像樣的燉菜，記得帶上蔬菜和蘑菇。','Una comida caliente cambia un viaje difícil. La olla hace que carne y pescado alimenten más. Trae verduras y setas para preparar un buen estofado.','温かい料理があれば、つらい旅も少し楽になるよ。肉や魚は鍋で料理すると、ずっと腹持ちがよくなる。野菜とキノコがあれば、シチューも作れるね。'),
('Copper comes from the fen’s orange seams. Iron lies farther east, beneath the ash. Build a smelter before you haul too much ore home, and bring a better pick for the harder rock.','沼泽里橙色的矿脉能采出铜。铁则藏在更东边的灰烬之下。别运回太多矿石才想起建熔炉，碰到硬岩也得带把好镐。','沼澤裡橙色的礦脈能採出銅。鐵則藏在更東邊的灰燼之下。別運回太多礦石才想起建熔爐，碰到硬岩也得帶把好鎬。','El cobre sale de las vetas naranjas del pantano. El hierro está más al este, bajo la ceniza. Construye una fundición y lleva un pico mejor para las rocas duras.','銅は湿地の橙色の鉱脈から採れる。鉄はもっと東、灰の下だ。鉱石を山ほど持ち帰る前に溶鉱炉を作っておけよ。硬い岩には、それなりのつるはしも必要だ。'),
('Field mushrooms and dew gel make a soothing salve. Do not wait until a warden has you cornered to prepare it. Gardens will keep your camp fed while you explore.','原野菇和露胶能调成舒缓伤势的药膏。别等守卫把你逼进死角了才想起来准备。外出探索时，菜畦还能为营地种出口粮。','原野菇和露膠能調成舒緩傷勢的藥膏。別等守衛把你逼進死角了才想起來準備。外出探索時，菜畦還能為營地種出口糧。','Las setas y el gel de rocío sirven para hacer ungüento. Prepáralo antes de enfrentarte a un guardián. Un huerto alimentará el campamento mientras exploras.','野のキノコと露のしずくで、傷によく効く薬が作れるわ。守り手に追い詰められる前に準備してね。探索している間も、畑はキャンプの食料を育ててくれるから。'),
('Light a hearth in each camp and restore the waystones between them. Then we can travel safely again. Put a courier board beside a chest when you want help moving materials.','在各处营地点起炉火，再修好沿途路碑，我们就能重新安全通行了。想让人帮忙运送材料，就在箱子旁放块驿递告示板。','在各處營地點起爐火，再修好沿途路碑，我們就能重新安全通行了。想讓人幫忙運送材料，就在箱子旁放塊驛遞告示板。','Enciende hogueras en tus campamentos y restaura los hitos entre ellos. Volveremos a viajar seguros. Coloca un tablón junto a un cofre para que transportemos materiales.','キャンプごとに炉火を灯して、その間の道標を修復しよう。そうすれば、また安全に行き来できる。素材を運んでほしいときは、チェストのそばに配達の掲示板を置いてね。'),
('The wardens warn before they strike. Watch their stance, step away from the marked ground, then answer while they recover. A longer weapon is useful, but an empty stomach will undo any advantage.','守卫出招前都有征兆。看准架势，离开标记的地面，趁它收招时还击。长兵器确实好用，可空着肚子，再大的优势也会白费。','守衛出招前都有徵兆。看準架勢，離開標記的地面，趁牠收招時還擊。長兵器確實好用，可空著肚子，再大的優勢也會白費。','Los guardianes avisan antes de atacar. Observa su postura, sal de la zona marcada y golpea mientras se recuperan. Un arma larga ayuda, pero no luches con el estómago vacío.','守り手は攻撃の前に構える。姿勢をよく見て、地面の印から離れろ。反撃するなら、相手が立て直している間だ。長い武器は有利だが、空腹では役に立たんぞ。'),
('The old network did not fail all at once. Its keepers tried to force every region into the same season. Perhaps a living world needs more than one answer. Your atlas may yet show us how.','古代网络并非一夕崩塌。守望者曾试图让所有区域停在同一个季节。可鲜活的世界，也许需要不止一种答案。你的图志或许能让我们明白该怎么做。','古代網絡並非一夕崩塌。守望者曾試圖讓所有區域停在同一個季節。可鮮活的世界，也許需要不只一種答案。你的圖誌或許能讓我們明白該怎麼做。','La antigua red no cayó de golpe. Sus guardianes quisieron imponer una sola estación a todas las regiones. Quizá un mundo vivo necesite más de una respuesta. Tu atlas podría mostrarnos el camino.','古い網は一度に崩れたのではありません。守り手たちは、どの地域も同じ季節に閉じ込めようとしたのです。生きた世界には、答えが一つでは足りないのでしょう。あなたの地図帳なら、道を示せるかもしれませんね。')]
NPCS=[]
for i,(key,n) in enumerate(NPC_NAMES):
    text('npc.'+key,*n);text('npc.'+key+'.dialogue',*NPC_DIALOGUE[i]);NPCS.append({'id':key,'region':min(i//2,3),'art':i,'name_key':'npc.'+key,'dialogue_key':'npc.'+key+'.dialogue'})

PERKS=[
('trailfeet',('Trail feet','行路健足','行路健足','Paso firme','旅慣れた足'),('Move 12% faster while exploring.','探索时移动速度提高12%。','探索時移動速度提高12%。','Te mueves un 12% más rápido al explorar.','探索中の移動速度が12%上がります。')),
('forager',('Careful forager','细心采集者','細心採集者','Recolector atento','丁寧な採取'),('Gather one extra plant resource with each harvest.','每次采集植物时额外获得1份材料。','每次採集植物時額外獲得1份材料。','Obtienes un recurso vegetal adicional por cosecha.','植物の採取で、素材が1個多く手に入ります。')),
('deep_breath',('Deep breath','深呼吸','深呼吸','Aliento profundo','深呼吸'),('Gain 25 maximum stamina.','体力上限增加25。','體力上限增加25。','Aumenta tu energía máxima en 25.','スタミナの最大値が25増えます。')),
('steady_hand',('Steady hand','稳健出手','穩健出手','Mano firme','確かな手'),('Deal 15% more weapon damage.','武器伤害提高15%。','武器傷害提高15%。','Infliges un 15% más de daño con armas.','武器のダメージが15%上がります。')),
('thick_coat',('Weathered coat','耐候外衣','耐候外衣','Abrigo curtido','丈夫な外套'),('Take 2 less damage from each hit.','每次受到的伤害降低2点。','每次受到的傷害降低2點。','Recibes 2 puntos menos de daño por golpe.','受けるダメージを2軽減します。')),
('second_wind',('Second wind','重振精神','重振精神','Segundo aliento','立て直し'),('Recover stamina 30% faster.','体力恢复速度提高30%。','體力恢復速度提高30%。','Recuperas energía un 30% más rápido.','スタミナの回復が30%速くなります。')),
('packcraft',('Well-packed','妥善打包','妥善打包','Buen equipaje','旅支度の知恵'),('Gain 8 backpack slots.','背包容量增加8格。','背包容量增加8格。','Añade 8 espacios a tu mochila.','持ち物の枠が8増えます。')),
('green_thumb',('Green thumb','园艺巧手','園藝巧手','Buena mano','緑の手'),('Gardens grow 30% faster.','菜畦作物生长速度提高30%。','菜畦作物生長速度提高30%。','Los cultivos crecen un 30% más rápido.','畑の作物が30%速く育ちます。')),
('hearthkeeper',('Hearthkeeper','炉火守护者','爐火守護者','Guardián del hogar','炉火の守り'),('Recover health while resting near a hearth.','在炉火附近休息时恢复生命。','在爐火附近休息時恢復生命。','Recuperas salud al descansar cerca de una hoguera.','炉火の近くで休むと、体力が回復します。'))]
for key,n,d in PERKS:text('perk.'+key,*n);text('perk.'+key+'.desc',*d)

QUESTS=[
('talk',('Speak to Mara beside the hearth.','与炉火旁的玛拉交谈。','與爐火旁的瑪拉交談。','Habla con Mara junto a la hoguera.','炉火のそばにいるマーラと話す。')),
('gather',('Gather 8 wood and 6 stone from the nearby woodland.','在附近林地收集8份木材与6份石料。','在附近林地收集8份木材與6份石料。','Recoge 8 de madera y 6 de piedra en el bosque.','近くの林で木材8個と石6個を集める。')),
('camp',('Make a workbench and place it beside your camp.','制作工作台，并放在营地旁。','製作工作臺，並放在營地旁。','Fabrica un banco de trabajo y colócalo en el campamento.','作業台を作り、キャンプに設置する。')),
('waystone',('Follow the eastern trail and restore the Brackenreach waystone.','沿东边的小径前进，修复蕨野原路碑。','沿東邊的小徑前進，修復蕨野原路碑。','Sigue el sendero del este y restaura el hito de las Praderas.','東の道をたどり、ワラビ野の道標を修復する。')),
('warden',('Prepare supplies, then face Old Briar at the waystone.','备好物资，然后在路碑处挑战古荆守卫。','備好物資，然後在路碑處挑戰古荊守衛。','Prepara suministros y enfréntate al Viejo Espino junto al hito.','物資を準備して、道標で古きイバラに挑む。')),
('regions',('Explore the other regions. Restore their waystones and overcome their wardens.','探索其他区域，修复路碑并战胜各地守卫。','探索其他區域，修復路碑並戰勝各地守衛。','Explora las demás regiones. Restaura sus hitos y supera a sus guardianes.','ほかの地域を探索し、道標を修復して守り手たちを越える。')),
('meridian',('Enter the Hollow Meridian and meet the Atlas Keeper.','进入空寂中庭，寻找图志守望者。','進入空寂中庭，尋找圖誌守望者。','Entra en el Meridiano Hueco y encuentra al Guardián del Atlas.','うつろの中庭に入り、地図帳の守り手に会う。')),
('free',('The world is connected. Build, explore, and write the next chapter of your journey.','世界已再度相连。继续建造、探索，谱写下一段旅程。','世界已再度相連。繼續建造、探索，譜寫下一段旅程。','El mundo está conectado. Construye, explora y escribe el siguiente capítulo.','世界はつながりました。建築と探索を楽しみ、旅の続きを記しましょう。'))]
for key,n in QUESTS:text('quest.'+key,*n)


def write_all():
    DATA.mkdir(parents=True, exist_ok=True); LOCALE.mkdir(parents=True, exist_ok=True)
    data={'items':ITEMS,'recipes':RECIPES,'mobs':MOBS,'structures':STRUCTURES,'regions':REGIONS,'npcs':NPCS,'perks':[x[0] for x in PERKS],'difficulties':{k:{'damage':d,'density':s,'needs':n} for k,_,_,d,s,n in DIFFICULTIES},'releases':[]}
    from expand_content import expand
    data.update(expand(text,item,ITEMS,RECIPES,STRUCTURES,REGIONS,NPCS))
    from release_content import releases
    data['releases']=releases(text)
    for catalog in CAT.values():catalog.pop('release.020',None)
    from polish_text import polish
    polish(text,ITEMS,CAT)
    for name,value in data.items(): (DATA/(name+'.json')).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for lang,catalog in CAT.items(): (LOCALE/(lang+'.json')).write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'{len(ITEMS)} items, {len(RECIPES)} recipes, {len(STRUCTURES)} structures, {len(MOBS)} creatures, {len(CAT["en"])} keys per language')

if __name__ == '__main__':write_all()
