"""Original GALAXY 1942 mesh assets. Python stdlib; deterministic glTF 2.0/GLB.
Y-up, metre units, ground contact at y=0, front +Z. Surfaces are batched
per material and animated part. No external assets, atlases, or dependencies.
"""
from pathlib import Path
import math, struct, json, random
from collections import defaultdict
OUT=Path(__file__).resolve().parents[1]/'godot_override/assets/models'
OUT.mkdir(parents=True,exist_ok=True)
TAU=math.tau
NAMES=['galactic_core','fusion_reactor','metal_extractor','oil_processor','crystal_mine','resource_vault','star_hangar','research_lab','laser_tower','shield_generator','gold_refinery','missile_bastion','vehicle_factory','barracks']
ACCENTS=['38d6f1','60eccb','f5b74b','fa9851','bf88ff','ecc779','65c8ff','71e1e3','6fbdff','68e4e6','ffd065','ff9852','ffbc57','79e6b0']
def rgb(h):
    values=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return [v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in values]
def material(name,h,metal=.2,rough=.55,emission=False):
    m={'name':name,'pbrMetallicRoughness':{'baseColorFactor':rgb(h)+[1],'metallicFactor':metal,'roughnessFactor':rough}}
    if emission:m['emissiveFactor']=rgb(h)
    return m
class Model:
    def __init__(self,accent='38d6f1'):
        self.parts=defaultdict(lambda:defaultdict(list));self.part='Hull';self.pivots={}
        self.materials=[material('ceramic_armor','a9bec7',.25,.43),material('navy_titanium','293e50',.5,.48),material('recess','101e2b',.12,.8),material('alloy_edges','728c9b',.55,.42),material('power_emission',accent,.15,.34,True),material('safety_ochre','e7ab58',.25,.55),material('glass','1c7b94',.45,.22)]
    def tri(self,a,b,c,mat):
        u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
        n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];l=math.sqrt(sum(x*x for x in n))
        if l<1e-9:return
        n=[x/l for x in n]
        self.parts[self.part][mat].extend([(a,n),(b,n),(c,n)])
    def quad(self,a,b,c,d,mat):self.tri(a,b,c,mat);self.tri(a,c,d,mat)
    def profile(self,poly,levels,mat,pos=(0,0,0),yaw=0):
        # CCW polygon in X/Z, levels=(height, horizontal_scale).
        co,si=math.cos(yaw),math.sin(yaw)
        rings=[]
        for y,s in levels:rings.append([(pos[0]+co*x*s+si*z*s,pos[1]+y,pos[2]-si*x*s+co*z*s) for x,z in poly])
        for k in range(len(rings)-1):
            a,b=rings[k:k+2]
            for i in range(len(poly)):
                j=(i+1)%len(poly);self.quad(a[i],b[i],b[j],a[j],mat)
        for i in range(1,len(poly)-1):
            self.tri(rings[0][0],rings[0][i],rings[0][i+1],mat)
            self.tri(rings[-1][0],rings[-1][i+1],rings[-1][i],mat)
    def block(self,size,pos=(0,0,0),mat=0,bevel=.12,yaw=0):
        x,y,z=size;x/=2;z/=2;b=min(bevel,x*.45,z*.45,y*.3)
        p=[(-x+b,-z),(x-b,-z),(x,-z+b),(x,z-b),(x-b,z),(-x+b,z),(-x,z-b),(-x,-z+b)]
        self.profile(p,[(-y/2,.94),(-y/2+b,1),(y/2-b,1),(y/2,.94)],mat,pos,yaw)
    def lathe(self,profile,mat=0,pos=(0,0,0),n=20):
        for j in range(len(profile)-1):
            r0,y0=profile[j];r1,y1=profile[j+1]
            for i in range(n):
                a,b=i*TAU/n,(i+1)*TAU/n
                p=lambda r,y,t:(pos[0]+r*math.cos(t),pos[1]+y,pos[2]+r*math.sin(t))
                self.quad(p(r0,y0,a),p(r1,y1,a),p(r1,y1,b),p(r0,y0,b),mat)
    def drum(self,r,h,pos=(0,0,0),mat=0,n=16):
        self.lathe([(0,-h/2),(r*.9,-h/2),(r,-h/2+.07),(r,h/2-.07),(r*.9,h/2),(0,h/2)],mat,pos,n)
    def ring(self,r,y,mat=4,width=.09,pos=(0,0,0),n=32):self.lathe([(r-width,y),(r-width,y+.06),(r,y+.06),(r,y),(r-width,y)],mat,pos,n)
    def strut(self,a,b,width=.15,mat=3):
        # Axis independent square-section beam with closed ends.
        d=[b[i]-a[i] for i in range(3)];l=math.sqrt(sum(x*x for x in d));d=[x/l for x in d]
        ref=[0,1,0] if abs(d[1])<.9 else [1,0,0]
        u=[d[1]*ref[2]-d[2]*ref[1],d[2]*ref[0]-d[0]*ref[2],d[0]*ref[1]-d[1]*ref[0]];q=math.sqrt(sum(x*x for x in u));u=[x/q*width/2 for x in u]
        v=[d[1]*u[2]-d[2]*u[1],d[2]*u[0]-d[0]*u[2],d[0]*u[1]-d[1]*u[0]]
        aa=[tuple(a[k]+s*u[k]+t*v[k] for k in range(3)) for s,t in [(-1,-1),(1,-1),(1,1),(-1,1)]]
        bb=[tuple(b[k]+s*u[k]+t*v[k] for k in range(3)) for s,t in [(-1,-1),(1,-1),(1,1),(-1,1)]]
        self.quad(*reversed(aa),mat);self.quad(*bb,mat)
        for i in range(4):j=(i+1)%4;self.quad(aa[i],aa[j],bb[j],bb[i],mat)
    def export(self,name):
        binary=bytearray();views=[];access=[];meshes=[];nodes=[];tris=0
        def buf(vals,typ):
            while len(binary)%4:binary.append(0)
            start=len(binary);binary.extend(struct.pack('<%sf'%len(vals),*vals));vi=len(views);views.append({'buffer':0,'byteOffset':start,'byteLength':len(vals)*4,'target':34962})
            a={'bufferView':vi,'componentType':5126,'count':len(vals)//3,'type':'VEC3'}
            if typ=='pos':a.update(min=[min(vals[i::3]) for i in range(3)],max=[max(vals[i::3]) for i in range(3)])
            access.append(a);return len(access)-1
        for part,mats in self.parts.items():
            pivot=self.pivots.get(part,{'Drill':(1.25,0,0),'Radar':(1.9,3.65,-1.6)}.get(part,(0,0,0)))
            mats={k:[(tuple(p[i]-pivot[i] for i in range(3)),n) for p,n in v] for k,v in mats.items()}
            primitives=[]
            for mat,verts in mats.items():
                if not verts:continue
                pi=buf([v for p,n in verts for v in p],'pos');ni=buf([v for p,n in verts for v in n],'normal');tris+=len(verts)//3
                primitives.append({'attributes':{'POSITION':pi,'NORMAL':ni},'material':mat,'mode':4})
            meshes.append({'name':part,'primitives':primitives});nodes.append({'name':part,'mesh':len(meshes)-1,'translation':list(pivot)})
        data={'asset':{'version':'2.0','generator':'GALAXY 1942 original mesh workshop'},'scene':0,'scenes':[{'nodes':list(range(len(nodes)))}],'nodes':nodes,'meshes':meshes,'materials':self.materials,'buffers':[{'byteLength':len(binary)}],'bufferViews':views,'accessors':access}
        js=json.dumps(data,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
        output=struct.pack('<4sII',b'glTF',2,12+8+len(js)+8+len(binary))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(binary),b'BIN\0')+binary
        (OUT/(name+'.glb')).write_bytes(output)
        return {'file':name+'.glb','triangles':tris,'materials':len(self.materials),'parts':list(self.parts),'bytes':len(output)}

def pad(m,w=5,d=5):
    m.block((w,.28,d),(0,.14,0),1,.25);m.block((w-.18,.16,d-.18),(0,.36,0),3,.2)
    m.block((w-.4,.12,d-.4),(0,.47,0),1,.18)
    for x in [-1,1]:
        for z in [-1,1]:
            m.block((.6,.09,.13),(x*(w/2-.55),.57,z*(d/2-.25)),4,.02)
    # Visible stair treads and arrival ramp.
    for k in range(3):m.block((1.6,.12*(k+1),.34),(0,.06*(k+1),d/2+.68-k*.3),3,.03)

def fins(m,r,y,height,count=8):
    for i in range(count):
        a=i*TAU/count;x,z=math.sin(a)*r,math.cos(a)*r
        m.block((.28,height,.55),(x,y,z),0,.08,a)
        m.block((.09,height*.55,.07),(math.sin(a)*(r+.3),y,math.cos(a)*(r+.3)),4,.01,a)

def windows(m,r,y,n=12):
    for i in range(n):
        a=i*TAU/n;m.block((.45,.28,.075),(math.sin(a)*r,y,math.cos(a)*r),4,.01,a)

def vents(m,x,y,z,n=5):
    m.block((1,.1,n*.2+.15),(x,y,z),2,.03)
    for k in range(n):m.block((.86,.09,.055),(x,y+.05,z+(k-(n-1)/2)*.2),3,.01)

def building(t):
    m=Model(ACCENTS[t]);pad(m,6.6 if t==0 else 6.4 if t==6 else 5.3,5.8 if t==6 else 5.3)
    if t==0:
        m.drum(2.55,.65,(0,.88,0),0,8);m.drum(2.2,1.55,(0,1.85,0),1,8)
        windows(m,2.19,1.95,8);fins(m,2.25,1.6,1.6,8)
        m.lathe([(0,2.6),(2.55,2.6),(2.55,2.85),(1.85,3.05),(1.45,3.65),(.75,3.85),(0,3.85)],0,n=8)
        for i in range(8):
            a=i*TAU/8+TAU/16;nx,nz=math.cos(a),math.sin(a);tx,tz=-nz,nx
            m.quad((nx*2.29-tx*.24,3.09,nz*2.29-tz*.24),(nx*1.37-tx*.16,3.7,nz*1.37-tz*.16),(nx*1.37+tx*.16,3.7,nz*1.37+tz*.16),(nx*2.29+tx*.24,3.09,nz*2.29+tz*.24),3)
        m.ring(1.28,3.79,4,.18);m.drum(.55,.9,(0,4.1,0),2,12);m.drum(.35,.8,(0,4.4,0),4,12)
        for a in [0,math.pi/2,math.pi,math.pi*1.5]:
            x,z=math.sin(a)*1.45,math.cos(a)*1.45;m.block((.5,1.4,.55),(x,3.55,z),1,.09,a);m.block((.18,.65,.16),(x,4.4,z),4,.02,a)
        for x in [-1,1]:m.block((1.15,1.2,1.5),(x*2.3,1.05,1.25),0,.15);vents(m,x*2.3,1.7,1.25)
        m.block((1.25,.95,.14),(0,1,2.45),2,.1);m.block((.7,.08,.18),(0,1.5,2.49),4,.01)
        m.part='Rotor';m.ring(.95,4.65,4,.08)
        for a in [0,math.pi/2,math.pi,math.pi*1.5]:m.block((.17,.16,.25),(math.cos(a)*.95,4.75,math.sin(a)*.95),0,.02,a)
    elif t==1:
        m.drum(1.8,.4,(0,.72,0),3);m.drum(1.25,2.3,(0,1.9,0),2)
        m.drum(.95,1.95,(0,2,0),4);fins(m,1.15,1.8,2.5,8)
        m.lathe([(0,3.1),(1.6,3.1),(1.6,3.35),(.9,3.6),(0,3.6)],0)
        m.drum(.73,.2,(0,3.62,0),2);m.ring(.69,3.74,4,.12)
        for a in [0,math.pi/2,math.pi,3*math.pi/2]:m.block((.18,.18,.5),(math.cos(a),3.47,math.sin(a)),1,.02,a)
        for x in [-1,1]:
            m.drum(.5,1.35,(x*1.95,1.15,0),0);m.ring(.52,1.4,4,pos=(x*1.95,0,0));m.strut((x*1.95,.7,0),(x*.8,.7,0),.23)
        m.part='Rotor';m.ring(1.45,2.9,4,.12)
    elif t==2:
        m.block((2.15,1.2,3.4),(-1,1.12,0),0,.18);vents(m,-1,1.77,0,8)
        for z in [-1,1]:m.block((.5,2.5,.55),(1.25,1.7,z*1.3),1,.1)
        m.strut((1.25,2.9,-1.3),(1.25,2.9,1.3),.48,5)
        m.strut((1.25,1.1,-1.3),(1.25,2.8,1.3),.12,3)
        m.drum(.8,.2,(1.25,.63,0),2)
        m.part='Drill';m.lathe([(0,.65),(.15,.65),(.6,1.25),(.5,1.4),(.65,1.6),(.5,1.8),(.6,2),(.2,2.1),(.2,2.9),(0,2.9)],3,pos=(1.25,0,0),n=12)
    elif t==3:
        for x,h in [(-1.3,2.5),(0,3.15),(1.3,2.25)]:
            m.drum(.56,h,(x,.55+h/2,-.25),0);m.ring(.58,1.05,5,pos=(x,0,-.25));m.ring(.58,h+.32,3,pos=(x,0,-.25));m.drum(.24,.65,(x,h+.8,-.25),1)
            m.strut((x,.85,-.25),(x,.85,1.65),.15,3)
        m.block((3.6,.75,.8),(0,.95,1.6),1,.12);m.block((1.5,.28,.1),(0,1.1,2.02),4,.02)
    elif t==4:
        m.drum(1.9,.5,(0,.8,0),2,8);m.ring(1.9,1,4,.09,n=24)
        for x,z,h,r in [(0,0,3.5,.62),(-.9,.6,2.25,.43),(.8,.7,2.4,.45),(.7,-.9,2.3,.4),(-.7,-.75,1.9,.35)]:
            m.lathe([(0,.9),(r*.6,.9),(r,1.2),(r,h-.7),(0,h)],4,pos=(x,0,z),n=5)
        for a in [0,math.pi/2,math.pi,3*math.pi/2]:
            x,z=math.sin(a)*1.9,math.cos(a)*1.9;m.block((.45,1.1,.5),(x,1.2,z),0,.1,a)
    elif t==5:
        m.block((3.7,1.8,3.2),(0,1.5,0),1,.3);m.block((4.05,.45,3.55),(0,2.55,0),0,.2)
        for x in [-1.55,1.55]:m.block((.45,1.6,3.45),(x,1.6,0),0,.1)
        m.block((2.15,1.35,.25),(0,1.47,1.72),3,.16);m.block((1.8,1.04,.14),(0,1.5,1.88),2,.16)
        m.strut((-.65,1,1.98),(.65,2,1.98),.15,5);m.strut((.65,1,1.98),(-.65,2,1.98),.15,5)
        vents(m,0,2.81,0,7);m.block((1.35,.09,.12),(0,2.47,1.83),4,.02)
    elif t==6:
        # Open hangar: actual deep bay, side walls and roof; no painted doorway.
        for x in [-2.3,2.3]:
            m.block((1,2.4,4.5),(x,1.7,-.25),0,.2)
            m.block((.5,.75,3.8),(x,3,-.25),1,.1);vents(m,x,3.41,-.25,11)
        m.block((3.75,2.4,.45),(0,1.7,-2.28),1,.12)
        m.profile([(-2.8,-2.2),(2.8,-2.2),(2.8,1.6),(1.8,2.2),(-1.8,2.2),(-2.8,1.6)],[(2.8,1),(3.12,1),(3.35,.82)],0)
        m.block((3.4,.16,.13),(0,2.75,1.97),4,.02)
        m.block((1.6,.035,2.6),(0,3.37,-.25),1,.08)
        for x in [-.5,.5]:m.block((.1,.04,2),(x,3.4,-.25),5,.02)
        for x in [-1.35,1.35]:m.block((.08,.03,2.9),(x,.56,1.85),4,.01)
        m.block((2.65,.08,2.6),(0,.57,2.25),1,.08)
        for k in range(3):m.block((.65,.03,.12),(0,.63,1.7+k*.55),0,.01)
    elif t==7:
        m.drum(1.65,1.75,(0,1.38,0),0,12);windows(m,1.67,1.65,12)
        m.lathe([(0,2.3),(1.8,2.3),(1.65,2.8),(1.25,3.18),(.6,3.43),(0,3.5)],6,n=24)
        for i in range(6):
            a=i*TAU/6;m.strut((math.sin(a)*1.7,2.35,math.cos(a)*1.7),(0,3.55,0),.085,3)
        m.block((1.6,1.2,1.2),(-1.65,1.1,1.2),1,.16);vents(m,-1.65,1.75,1.2)
        m.strut((1.9,.6,-1.6),(1.9,3.6,-1.6),.15,3)
        m.part='Radar';m.lathe([(0,3.65),(.85,3.9),(.9,4.05),(.75,3.96),(0,3.8)],0,pos=(1.9,0,-1.6),n=16)
    elif t==8:
        m.lathe([(0,.55),(1.7,.55),(1.7,.8),(1.05,1.1),(.95,2.5),(1.15,2.7),(0,2.7)],1,n=8)
        fins(m,1.05,1.65,1.25,4);m.ring(1.15,2.55,4)
        m.part='Turret';m.block((2.1,.7,1.6),(0,2.98,0),0,.2)
        m.block((1.2,.35,1.25),(0,3.5,-.1),1,.15)
        for x in [-.6,.6]:
            m.block((.3,.3,2.7),(x,3.03,1.5),1,.05);m.block((.4,.4,.45),(x,3.03,2.65),3,.06);m.block((.23,.23,.03),(x,3.03,2.9),4,.02)
        m.block((.7,.18,.08),(0,3.4,.6),4,.02)
    elif t==9:
        m.drum(1.55,.4,(0,.78,0),3);m.drum(.6,1.35,(0,1.6,0),2);m.drum(.4,1.2,(0,1.9,0),4)
        for i in range(4):
            a=i*TAU/4+math.pi/4;x,z=math.sin(a)*1.65,math.cos(a)*1.65
            m.block((.7,2.15,.7),(x,1.5,z),0,.14,a)
            m.strut((x,2.6,z),(x*.5,3.15,z*.5),.28,1)
            m.block((.24,.7,.16),(x*1.2,1.9,z*1.2),4,.025,a)
        m.part='Rotor';m.ring(1.25,2.85,4,.12)
    elif t==10:
        # Gold refinery: smelter, intake conveyor, exhaust stacks and gold vault.
        m.block((2.4,2.4,2.8),(-.9,1.7,-.3),1,.22)
        m.block((2.7,.35,3.1),(-.9,3,-.3),0,.12)
        for x in [-1.6,-.4]:
            m.drum(.3,1.7,(x,3.4,-1.1),3)
            m.ring(.32,4.2,5,pos=(x,0,-1.1))
        m.block((1.6,.8,2.1),(1.6,.95,.3),0,.14)
        m.block((1.1,.12,3.1),(1.3,.65,1.5),2,.03)
        for z in range(6):
            m.block((1.2,.09,.18),(1.3,.76,.3+z*.45),3,.02)
        for z in range(3):
            m.block((.6,.25,.34),(1.3,.95,.6+z*.6),5,.06)
        m.block((1.6,.65,.08),(-.9,1.8,1.15),4,.04)
        vents(m,-.9,3.22,-.3)
        m.part='Rotor';m.ring(.65,3.25,4,pos=(-.9,0,-.3))
    elif t==11:
        m.drum(1.65,.8,(0,1,0),1,8);fins(m,1.2,1.5,1.25,4)
        m.drum(1.1,.6,(0,2,0),3,12)
        m.part='Turret'
        m.block((2.9,.7,2.1),(0,2.5,0),0,.2)
        for x in [-.9,0,.9]:
            m.block((.7,.8,2.7),(x,3,.15),1,.12)
            m.block((.45,.45,.1),(x,3,1.55),2,.04)
            m.block((.23,.23,.11),(x,3,1.61),4,.02)
        m.strut((0,2.8,-1),(0,4.2,-1),.08,3)
        m.block((.8,.3,.15),(0,4.2,-1),4,.03)
    elif t==12:
        # Two deep vehicle assembly bays, overhead crane and industrial exhausts.
        for x in [-2.35,0,2.35]:
            m.block((.45,2.6,4.4),(x,1.85,0),1,.1)
        m.block((4.9,.45,4.6),(0,3.35,0),0,.18)
        m.block((4.8,2.5,.35),(0,1.8,-2.1),1,.1)
        for x in [-1.2,1.2]:
            m.block((1.8,.08,3.8),(x,.6,1.25),2,.06)
            m.block((1.7,.12,.15),(x,2.95,2.25),5,.02)
            for z in range(4):m.block((1.6,.03,.08),(x,.66,.3+z*.7),5,.01)
        for x in [-1.8,1.8]:
            m.drum(.22,1.2,(x,3.8,-1.5),3)
            vents(m,x,3.62,0,6)
        m.strut((-2.4,4.2,0),(2.4,4.2,0),.2,5)
        m.strut((0,4.2,0),(0,3.6,0),.1,3)
    elif t==13:
        # Armored troop quarters with parade apron and communication mast.
        m.block((4.4,2.1,3.2),(0,1.6,-.5),1,.25)
        m.block((4.7,.4,3.5),(0,2.85,-.5),0,.18)
        for x in [-1.6,-.8,.8,1.6]:
            m.block((.45,.55,.08),(x,2,1.14),4,.04)
        m.block((.8,1.55,.12),(0,1.35,1.17),2,.08)
        m.block((1,.16,.15),(0,2.2,1.22),5,.03)
        m.block((4,.08,1.6),(0,.57,2),0,.12)
        for x in [-1.4,0,1.4]:m.block((.5,.03,.65),(x,.63,2),5,.03)
        m.strut((2,.6,-1.5),(2,4.8,-1.5),.08,3)
        m.block((.9,.6,.06),(1.6,4.35,-1.5),4,.02)
        vents(m,-1.1,3.1,-.5,6)
    return m

def mining_vehicle():
    m=Model('ffd065')
    m.block((1.8,.6,2.9),(0,.7,0),1,.14)
    for x in [-1,1]:
        m.block((.55,.65,3.1),(x,.4,0),2,.13)
        for z in [-1,-.5,0,.5,1]:
            m.block((.6,.14,.19),(x,.76,z),3,.02)
    m.block((1.3,.9,1.1),(0,1.35,-.65),0,.14)
    m.block((1,.45,.08),(0,1.42,-.06),6,.03)
    m.block((1.3,.3,1.1),(0,1.1,.5),5,.06)
    m.strut((-.6,.9,1),(-.6,1.3,2),.15,3)
    m.strut((.6,.9,1),(.6,1.3,2),.15,3)
    m.part='Drill'
    for x in [-.6,-.3,0,.3,.6]:
        m.block((.19,.4,.5),(x,.9,2),3,.03)
    return m

def construction_drone():
    m=Model('67ffe1')
    m.block((.9,.35,.7),(0,0,0),0,.12)
    m.block((.5,.14,.08),(0,0,.4),4,.02)
    for x in [-1,1]:
        for z in [-1,1]:
            m.strut((x*.25,0,z*.2),(x*.7,0,z*.6),.09,3)
            m.drum(.27,.1,(x*.7,0,z*.6),1,12)
            m.ring(.22,.06,4,pos=(x*.7,0,z*.6),width=.04)
    return m

def fighter():
    m=Model();m.profile([(-.2,-1.7),(.2,-1.7),(.55,-.45),(.48,1.25),(.2,1.7),(-.2,1.7),(-.48,1.25),(-.55,-.45)],[(.12,.9),(.3,1),(.58,.55)],0)
    for sign in [-1,1]:
        p=[(.3*sign,-.55),(2*sign,.65),(1.9*sign,1.4),(.4*sign,.85)]
        if sign<0:p.reverse()
        m.profile(p,[(.18,1),(.32,1)],1)
        m.block((.22,.16,1.3),(sign*1.05,.33,.78),0,.04)
        m.block((.2,.2,.35),(sign*.35,.32,1.6),4,.03)
    m.profile([(-.22,-.75),(.22,-.75),(.28,.2),(-.28,.2)],[(.4,1),(.72,.6)],6)
    return m

manifest={'authorship':'Original GALAXY 1942 procedural mesh designs, no external assets','coordinates':'Y-up, metres, front +Z, ground y=0','assets':[]}
from cartoon_models import scrap_roof, aircraft, weathered_details
for i,name in enumerate(NAMES):
    asset=building(i);scrap_roof(asset,material,i);weathered_details(asset,material,i);manifest['assets'].append(asset.export(name))
manifest['assets'].append(aircraft(Model,material).export('fighter'))
from unit_models import build_ground_assets
manifest['assets'].extend(build_ground_assets(Model,material))
manifest['assets'].append(mining_vehicle().export('mining_vehicle'))
manifest['assets'].append(construction_drone().export('construction_drone'))
manifest['assets'].append(aircraft(Model,material,True).export('attack_pigeon'))
from godot_faction_models import build_faction_assets
manifest['assets'].extend(build_faction_assets(Model,material))
from camp_models import build_camps
manifest['assets'].extend(build_camps(Model,material))
# Reusable angular geology, organic crown plants; merged into material surfaces.
for seed in range(3):
    m=Model();m.materials[0]=material('weathered_stone','697a75',.05,.95);rng=random.Random(seed+1942)
    poly=[(math.cos(i*TAU/7)*rng.uniform(.75,1.15),math.sin(i*TAU/7)*rng.uniform(.75,1.15)) for i in range(7)]
    m.profile(poly,[(0,.8),(.2,1),(1,.8),(1.7,.4),(1.85,.12)],0)
    manifest['assets'].append(m.export('rock_'+str(seed)))
m=Model();m.materials[0]=material('jade_foliage','36776b',0,.9);m.materials[1]=material('plant_stem','41615b',0,.9)
m.lathe([(0,0),(.12,0),(.11,1.4),(0,1.45)],1,n=7)
for y,r in [(1,.72),(1.4,.59),(1.78,.4)]:m.lathe([(0,y-.15),(r,y),(r*.9,y+.18),(r*.35,y+.45),(0,y+.49)],0,n=7)
manifest['assets'].append(m.export('alien_tree'))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps([(a['file'],a['triangles']) for a in manifest['assets']]))
