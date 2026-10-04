"""Import generated sprite sheets and approved icon art as compact engine textures.
This is an asset conversion pipeline: crop cells, trim alpha, pad, and resize.
"""
from pathlib import Path
from PIL import Image
from collections import deque
import json

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'native/assets/illustrated'

def sheet(source, columns, rows, folder, names):
    image = Image.open(source).convert('RGBA')
    target = DEST / folder
    target.mkdir(exist_ok=True)
    for index, name in enumerate(names):
        x, y = index % columns, index // columns
        cell = image.crop((round(x*image.width/columns), round(y*image.height/rows), round((x+1)*image.width/columns), round((y+1)*image.height/rows)))
        bbox = cell.getchannel('A').getbbox()
        if folder in ['scenery','creatures']:
            # Generated grids have uneven gutters. Select the main object's
            # bounding rectangle so a neighbouring cell's edge is not imported.
            alpha=cell.getchannel('A');pixels=alpha.load();visited=set();largest=[]
            for cy in range(cell.height):
                for cx in range(cell.width):
                    if (cx,cy) in visited or pixels[cx,cy]<64: continue
                    queue=deque([(cx,cy)]);component=[];visited.add((cx,cy))
                    while queue:
                        px,py=queue.popleft();component.append((px,py))
                        for nx,ny in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
                            if 0<=nx<cell.width and 0<=ny<cell.height and (nx,ny) not in visited and pixels[nx,ny]>=64:
                                visited.add((nx,ny));queue.append((nx,ny))
                    if len(component)>len(largest): largest=component
            if largest:
                bbox=(max(0,min(p[0] for p in largest)-2),max(0,min(p[1] for p in largest)-2),min(cell.width,max(p[0] for p in largest)+3),min(cell.height,max(p[1] for p in largest)+3))
        if bbox: cell = cell.crop(bbox)
        cell.thumbnail((244,244),Image.Resampling.LANCZOS)
        out=Image.new('RGBA',(256,256))
        out.alpha_composite(cell,((256-cell.width)//2,250-cell.height))
        out.save(target/(name+'.png'),optimize=True)

def weapons():
    image=Image.open(DEST/'icons.png').convert('RGBA')
    target=DEST/'weapons';target.mkdir(exist_ok=True)
    names=['gun','shotgun','flame','poison','ice','rail','lightning','saw','rocket','ghost','flowers','turret']
    for index,name in enumerate(names):
        cell=image.crop(((index%6)*128,(index//6)*128,(index%6+1)*128,(index//6+1)*128))
        # Remove only the connected cream surround, preserving pale paint inside outlines.
        pixels=cell.load();queue=deque();seen=set()
        for i in range(128): queue.extend([(i,0),(i,127),(0,i),(127,i)])
        while queue:
            x,y=queue.popleft()
            if (x,y) in seen or not (0<=x<128 and 0<=y<128): continue
            seen.add((x,y));r,g,b,a=pixels[x,y]
            if r<215 or g<200 or b<165 or r-b>75: continue
            pixels[x,y]=(r,g,b,0)
            queue.extend([(x+1,y),(x-1,y),(x,y+1),(x,y-1)])
        cell.save(target/(name+'.png'),optimize=True)

if __name__=='__main__':
    import sys
    heroes=['rubber_duck_toy','pipe_wrench','sweet_potato','marble_bust_01','street_rat','hamburger_buns','florist','teapot','octopus','astronaut','cactus','book','snail','bee','sushi','mushroom','clock','icecream','bathtub','peacock','toaster']
    creatures=[f'creature_{b}_{s}' for b in range(6) for s in range(6)]
    sheet(sys.argv[1],6,6,'creatures',creatures)
    sheet(sys.argv[2],7,3,'heroes',heroes)
    terrain=Image.open(sys.argv[3]).convert('RGB')
    for i in range(6):
        x,y=i%3,i//3
        terrain.crop((round(x*terrain.width/3),round(y*terrain.height/2),round((x+1)*terrain.width/3),round((y+1)*terrain.height/2))).resize((256,256),Image.Resampling.LANCZOS).save(DEST/f'terrain-{i}.png',optimize=True)
    weapons()
    print('Imported 36 creatures, 21 heroes, 12 weapons and six terrain materials.')
