"""Compose challenge badges from the game's approved illustrated icon atlas."""
from pathlib import Path
import json,math,hashlib
from PIL import Image,ImageDraw,ImageEnhance,ImageOps
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'native/data/catalog.json').read_text(encoding='utf8'))
source=Image.open(ROOT/'native/assets/illustrated/icons.png').convert('RGB')
tex=Image.open(ROOT/'native/assets/illustrated/paper.png').convert('RGB')
output=ROOT/'community/achievement-icons';output.mkdir(exist_ok=True)
keys={'burn':12,'freeze':14,'poison':13,'lifesteal':15,'shield':16,'thorns':21,'ghost':9,'burrow':19,'blind':22,'chain':6,'ricochet':6,'splash':12,'pierce':5,'regen':15,'armor':16,'dashblast':12,'pools':13,'slow':14,'storm':6,'nova':23,'berserk':7,'walkgold':19,'coinradius':17,'interest':17,'discount':17,'keypower':18,'luck':23,'hurtgold':15,'repair':15,'turretdamage':11,'flowerpollen':13,'flowerroots':10,'flowerheal':15,'flowerpower':10}
families={'Engineering':11,'Ballistics':0,'Explosives':8,'Fire':12,'Frost':14,'Electric':6,'Toxic':13,'Defense':16,'Recovery':15,'Mobility':19,'Vampiric':15,'Scavenging':20,'Fortune':18,'Precision':5,'Assassin':7,'Aura':23,'Spectral':9,'Burrowing':19,'Shadow':22,'Berserker':7,'Storm':6,'Arcane':23,'Nature':21,'Economy':17,'Garden':10}
heroes={'wrench':11,'duck':0,'broccoli':16,'grandma':8,'goblin':17,'loaf':7,'florist':10}
specific={'LOCKED_GATE':18,'RUINS':16,'HIGH_CHEST':18,'THREE_REALMS':23,'LONG_WALK':19,'AIRTIME':19,'FREE_KEY':18,'LAST_COIN':17,'SALE':17,'INTEREST':17,'WALK_PAY':19,'HURT_PAY':15,'BOSS_GIFT':18,'LEGENDARY':23,'MIXED_BAG':20,'TRIPLE_WEAPON':0,'REPLACE':1,'RANK_UP':5,'GARDEN':10,'BLOOM_CHAIN':10,'FLOWER_HEAL':10,'FLOWER_BOSS':10,'POLLEN':13,'GARDEN_MOVE':10,'PURE_GARDEN':10,'ROOTS':21,'NO_HIT_BOSS':16,'ONE_WEAPON':0,'COMEBACK':15,'NO_GUN':7,'HOT_COLD':12,'TOXIC_DARK':13,'BOSS_BLIND':22,'BOSS_ICE':14,'REVIVE':15,'BUBBLE':16,'MIX_TURRET':11,'FULL_EXPLORER':19,'ROADMAP':23,'FEEDBACK':20}
def stamp(canvas,index,box):
 x=(index%6)*128;y=(index//6)*128
 tile=source.crop((x+6,y+6,x+122,y+122)).resize((box[2]-box[0],box[3]-box[1]),Image.Resampling.LANCZOS)
 canvas.paste(tile,(box[0],box[1]))
atlases=[Image.new('RGB',(960,960),'#f3e7cf') for _ in range(2)]
manifest=[]
for n,a in enumerate(data['achievements']):
 identity=a['id'].removeprefix('WF_');key=a['key'];motif='badge';secondary=None
 if key.startswith('combo_'):
  pair=key[6:].lower().split('_');primary=keys.get(pair[0],23);secondary=keys.get(pair[1],23);motif='combo'
 elif key.startswith('family_'):primary=families.get(key[7:],23);motif='build'
 elif key.startswith(('play_','win_')):primary=heroes[key.split('_')[1]];motif='win' if key.startswith('win_') else 'hero'
 else:primary=specific.get(identity,23);motif='boss' if 'BOSS' in identity or identity in ['COMEBACK','ONE_WEAPON','NO_GUN','PURE_GARDEN'] else 'explore' if identity in ['RUINS','THREE_REALMS','LONG_WALK','FULL_EXPLORER','AIRTIME','HIGH_CHEST','GARDEN_MOVE'] else 'badge'
 image=tex.resize((256,256)).copy();draw=ImageDraw.Draw(image)
 draw.rounded_rectangle((6,6,249,249),radius=25,outline='#795d47',width=5)
 draw.rounded_rectangle((16,16,239,239),radius=20,outline='#c7a77e',width=2)
 model=next((h['model'] for h in data['heroes'] if h['id']==key.split('_')[-1]),'')
 if key.startswith(('play_','win_')) and (ROOT/'native/assets/illustrated/heroes'/f"{model}.png").exists():
  hero=Image.open(ROOT/'native/assets/illustrated/heroes'/f"{model}.png").convert('RGBA').resize((216,216),Image.Resampling.LANCZOS);image.paste(hero,(20,20),hero)
 elif secondary is None:stamp(image,primary,(32,29,224,221))
 else:
  stamp(image,primary,(20,30,171,181));stamp(image,secondary,(100,104,234,238))
 draw=ImageDraw.Draw(image)
 # Peripheral motifs encode a challenge rather than using a star for every achievement.
 if motif in ['boss','win']:
  draw.polygon([(84,40),(82,14),(104,29),(128,7),(152,29),(174,14),(171,40)],fill='#dfb866',outline='#795d47',width=3)
 elif motif=='build':
  for i in range(5):draw.ellipse((57+i*30,220,75+i*30,238),fill='#96b18a',outline='#795d47',width=2)
 elif motif=='explore':
  draw.line([(25,228),(50,218),(78,230),(97,215)],fill='#94745c',width=4)
  draw.polygon([(199,43),(199,15),(225,22),(199,31)],fill='#dfa48c',outline='#795d47');draw.line([(199,13),(199,49)],fill='#795d47',width=3)
 elif motif=='hero':
  draw.ellipse((204,16,237,49),fill='#e7c790',outline='#795d47',width=3);draw.arc((210,24,232,42),0,180,fill='#795d47',width=2)
 elif motif=='combo':draw.line([(69,214),(69,233),(89,233)],fill='#795d47',width=4)
 else:
  draw.polygon([(208,211),(215,226),(231,226),(219,236),(224,250),(208,241),(194,250),(197,236),(186,226),(202,226)],fill='#dfbc78',outline='#795d47',width=2)
 # Small stitched perimeter variation gives every API ID a stable individual badge.
 pattern=int.from_bytes(hashlib.sha256(a['id'].encode()).digest()[:2],'big')
 for i in range(8):
  if pattern&(1<<i):draw.line([(14,65+i*17),(21,68+i*17)],fill='#a38468',width=2)
 locked=ImageOps.colorize(ImageOps.grayscale(image),'#8d8175','#eadfc9')
 for state,icon in enumerate([image,locked]):
  suffix='unlocked' if state==0 else 'locked';icon.save(output/f"{a['id'].lower()}-{suffix}.png",optimize=True)
  atlases[state].paste(icon.resize((96,96),Image.Resampling.LANCZOS),((n%10)*96,(n//10)*96))
 manifest.append({'id':a['id'],'tile':n,'motif':motif,'sourceTile':primary,'secondaryTile':secondary})
for state,name in enumerate(['achievements.png','achievements-locked.png']):atlases[state].save(ROOT/'native/assets/illustrated'/name,optimize=True)
(ROOT/'native/assets/illustrated/achievement-art.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
print('100 illustrated challenge badges, 200 achievement images, two native atlases.')
