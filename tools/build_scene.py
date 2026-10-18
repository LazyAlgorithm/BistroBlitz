#!/usr/bin/env python3
"""Create a bright, readable kitchen from existing Kenney models and simple color accents."""
from pathlib import Path
import math
import json
import struct
parts=['''scene "Bistro Blitz - Sunny Kitchen"
env skyZenith 0.55 0.76 0.95 1
env skyHorizon 0.85 0.93 1 1
env skyGround 0.55 0.63 0.69 1
env ambientSky 0.92 0.96 1 1
env ambientGround 0.65 0.70 0.74 1
env ambientIntensity 1.1
env fogDensity 0
env exposure 1.05
env shadowDistance 40
''']
sequence=0

def obj(name,pos=(0,0,0),scale=(1,1,1),parent=0,rotation=(0,0,0,1)):
 global sequence
 sequence+=1
 parts.append(f'object {sequence} parent {parent} active 1 name "{name}"\ntransform '+ ' '.join(str(v) for v in (*pos,*rotation,*scale))+'\n')
 return sequence

def component(name,**fields):
 parts.append(f'component {name} enabled 1\n')
 for key,value in fields.items():
  if isinstance(value,str): value='"'+value+'"'
  elif isinstance(value,tuple): value=' '.join(map(str,value))
  parts.append(f'field {key} {value}\n')

def mesh(name,pos,scale,color,parent=0,model='builtin:cube',rotation=(0,0,0,1)):
 identifier=obj(name,pos,scale,parent,rotation)
 fields = dict(mesh=model,color=color,roughness=0.85)
 if model.startswith('Models/'):
  data=(Path('src')/model).read_bytes()
  size=struct.unpack_from('<I',data,12)[0]
  if json.loads(data[20:20+size]).get('images'):
   fields['texture']='Models/Textures/colormap.png'
 component('Tessera.MeshRenderer',**fields)
 return identifier

obj('Main Camera',(0,17,-7.5),rotation=(math.sin(math.radians(33)),0,0,math.cos(math.radians(33))))
component('Tessera.Camera',orthographic=1,orthographicSize=8.4,fieldOfView=60,nearClip=0.1,farClip=80)
component('Tessera.AudioListener')
obj('Soft daylight',(0,12,-4),rotation=(.45,-.2,.1,.8646))
component('Tessera.Light',type=0,color=(1,.97,.90,1),intensity=1.4,castShadows=1,shadowStrength=.35)
obj('Game Manager');component('Tessera.NetworkIdentity');component('BistroBlitz.Game');component('Tessera.UIDocument',document='UI/menu.tui',referenceHeight=1080,referenceWidth=1920)
mesh('Floor',(0,-.15,0),(18,.3,14),(.71,.81,.82,1));component('Tessera.BoxCollider',size=(1,1,1))
for x in range(-8,9):
 for z in range(-6,7):
  mesh('Floor tile',(x,.006,z),(.985,.01,.985),((.88,.93,.91,1) if (x+z)%2==0 else (.76,.86,.85,1)))
for name,pos,scale in [('North',(0,.3,6.8),(18,.6,.3)),('South',(0,.3,-6.8),(18,.6,.3)),('West',(-8.8,.3,0),(.3,.6,14)),('East',(8.8,.3,0),(.3,.6,14))]:
 mesh('Low '+name+' wall',pos,scale,(.25,.42,.47,1));component('Tessera.BoxCollider',size=(1,1,1))
# Uniform station roots keep physics, interaction distance and item heights consistent.
stations=[('STOVE',-2,4.5,2),('STOVE',0,4.5,2),('STOVE',2,4.5,2),('BUN',-7,3.5,3),('PATTY',-7,2,4),('SAUSAGE',-7,.5,5),('TOMATO',-7,-1,6),('CHEESE',-7,-2.5,7),('ASSEMBLE',-3,0,0),('CHOP',-1,0,1),('CHOP',1,0,1),('ASSEMBLE',3,0,0),('ASSEMBLE',-2,-4.5,0),('SERVE',6.5,-2,9),('ASSEMBLE',2,-4.5,0),('TRASH',4.5,-4.5,10)]
colors={0:(.20,.56,.68,1),1:(.19,.65,.43,1),2:(.90,.29,.16,1),3:(.94,.65,.21,1),4:(.83,.34,.42,1),5:(.69,.37,.20,1),6:(.88,.20,.19,1),7:(.96,.74,.15,1),9:(.12,.70,.61,1),10:(.30,.34,.43,1)}
foods={3:('builtin:cylinder',(.58,.2,.58)),4:('Models/meat-raw.glb',(1.25,1.25,1.25)),5:('Models/hot-dog-raw.glb',(1.3,1.3,1.3)),6:('Models/tomato.glb',(3.8,3.8,3.8)),7:('Models/cheese.glb',(1.7,1.7,1.7))}
for name,x,z,kind in stations:
 root=obj(name,(x,0,z));component('Tessera.NetworkIdentity');component('BistroBlitz.KitchenStation',kind=kind);component('Tessera.BoxCollider',size=(1.35,1.05,1.25),center=(0,.525,0))
 mesh('Colored station body',(0,.45,0),(1.3,.9,1.18),(.66,.43,.25,1) if kind==0 else colors[kind],root)
 mesh('Wood work surface',(0,.98,0),(1.4,.12,1.3),(.76,.55,.34,1) if kind!=2 else (.25,.30,.35,1),root)
 if kind!=2:
  for grain in range(6):
   mesh('Wood grain',(-.52+grain*.20,1.043,0),(.012,.006,1.13),(.64,.43,.25,1),root)
 mesh('Station color stripe',(0,1.052,.50),(1.35,.018,.08),colors[kind],root)
 # Kenney furniture is 0.43 wide and offset from its origin. Center it and match station dimensions.
 if kind==2:
  mesh('Kenney stove',(-.60,0,-.63),(2.8,2.2,2.8),(1,1,1,1),root,'Models/kitchenStove.glb')
  mesh('Pan',(.0,1.08,.10),(1.5,1.5,1.5),(1,1,1,1),root,'Models/frying-pan.glb')
 elif kind==1:
  mesh('Cutting board',(0,1.06,0),(1.35,1.35,1.35),(1,1,1,1),root,'Models/cutting-board.glb')
  mesh('Knife',(.30,1.15,0),(.65,.65,.65),(1,1,1,1),root,'Models/cooking-knife.glb')
 elif kind in foods:
  model,scale=foods[kind]
  mesh('Ingredient display',(0,1.14,0),scale,colors[kind] if kind==3 else (1,1,1,1),root,model)
 elif kind==10:
  mesh('Kenney bin',(.0,1.07,0),(1.4,1.4,1.4),(1,1,1,1),root,'Models/trashcan.glb')
 elif kind==9:
  mesh('Teal delivery pad',(0,1.07,0),(1.08,.06,.88),(.08,.62,.48,1),root)
  mesh('Delivery arrow stem',(-.22,1.108,0),(.38,.02,.12),(1,.88,.30,1),root)
  mesh('Delivery arrow upper',(.08,1.108,.09),(.29,.02,.09),(1,.88,.30,1),root,rotation=(0,.382683,0,.92388))
  mesh('Delivery arrow lower',(.08,1.108,-.09),(.29,.02,.09),(1,.88,.30,1),root,rotation=(0,-.382683,0,.92388))
 elif kind==0:
  mesh('Kenney cabinet',(-.60,0,-.63),(2.8,2,2.8),(1,1,1,1),root,'Models/kitchenCabinet.glb')
for i in range(4):
 mesh('Customer waiting spot',(8,.022,3-i*2),(1.1,.025,1.5),(.38,.62,.63,1))
obj('SpawnPoint',(-1.8,.2,-2))
Path('src/Scenes/Main.tscene').write_text('\n'.join(parts))
print('Created sunny kitchen scene with',sequence,'objects.')
