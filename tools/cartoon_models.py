"""Original scrappy space-cartoon designs, with actual mesh corrugation and pivots."""
import math,random
TAU=math.tau

def oval(m,pos,radii,mat=0,n=16):
    poly=[(math.cos(i*TAU/n)*radii[0],math.sin(i*TAU/n)*radii[2]) for i in range(n)]
    levels=[(-math.cos(j*math.pi/10)*radii[1],math.sin(j*math.pi/10)) for j in range(11)]
    m.profile(poly,levels,mat,pos)

def infantry(Model,material,kind):
    m=Model('ffd77a' if kind==19 else '64ded2')
    m.materials[0]=material('cobalt_armor','286bb4',.12,.73)
    m.materials[1]=material('navy_fabric','18374e',0,.95)
    m.materials.extend([material('warm_skin','d6a077',0,.85),material('eye_white','fff3d8',0,.6)])
    # Torso dwarfs the short legs; wide jaw and oversized helmet read from RTS height.
    for side,part in [(-1,'LeftLeg'),(1,'RightLeg')]:
        m.part=part;m.pivots[part]=(side*.29,.52,0)
        m.block((.24,.3,.3),(side*.29,.35,0),1,.06)
        m.block((.4,.22,.65),(side*.29,.12,.15),2,.08)
    m.part='Body'
    oval(m,(0,1.14,0),(.88,.78,.57),0)
    m.block((1.25,.19,.95),(0,.69,0),1,.08)
    m.block((.27,.24,.1),(0,.7,.5),5,.04)
    for x in [-.45,.45]:m.block((.29,.38,.13),(x,1.06,.53),1,.06)
    m.block((.32,.11,.08),(0,1.57,.57),4,.02)
    oval(m,(0,2.04,.06),(.51,.47,.42),7)
    oval(m,(0,1.87,.23),(.48,.23,.38),7)
    oval(m,(0,2.31,0),(.64,.37,.53),0)
    m.block((1.18,.12,.94),(0,2.2,.09),0,.15)
    m.block((.18,.07,.7),(0,2.66,.02),5,.02)
    for x in [-.21,.21]:
        oval(m,(x,2.1,.46),(.14,.12,.07),8,10)
        oval(m,(x,2.08,.52),(.06,.07,.025),2,8)
    oval(m,(0,1.99,.5),(.16,.13,.17),7,10)
    m.block((.39,.045,.05),(0,1.82,.59),2,.02)
    for side,part in [(-1,'LeftArm'),(1,'RightArm')]:
        m.part=part;m.pivots[part]=(side*.84,1.56,0)
        oval(m,(side*.87,1.53,0),(.35,.37,.39),0)
        oval(m,(side*.94,1.14,.12),(.26,.37,.27),1)
        oval(m,(side*.83,.92,.38),(.23,.22,.24),7)
    m.part='Weapon';m.pivots['Weapon']=(.55,1.02,.53)
    m.block((.38,.39,.75),(.55,1.03,.77),1,.1)
    m.block((.24,.24,.9 if kind==15 else .45),(.55,1.08,1.3),3,.05)
    m.block((.37,.37,.34),(.55,1.08,1.83 if kind==15 else 1.55),2,.07)
    m.block((.15,.15,.04),(.55,1.08,2.02 if kind==15 else 1.74),4,.02)
    if kind==15:m.block((.2,.2,.55),(.55,1.32,1.02),6,.04)
    if kind==19:
        m.part='Body';m.block((.32,.17,.08),(0,2.52,.39),5,.03)
        for x in [-.13,0,.13]:m.block((.06,.18,.035),(x,1.37,.6),5,.01)
        m.block((.75,1.05,.1),(0,1.17,-.61),1,.04)
    if kind==14:
        # Mech retains the same comic proportions, but armored face and bigger shoulders.
        m.materials[7]=material('mech_face_plate','718887',.5,.6)
        for part,mats in m.parts.items():
            for mat,vertices in mats.items():m.parts[part][mat]=[(tuple(v*1.28 for v in p),normal) for p,normal in vertices]
        m.pivots={k:tuple(v*1.28 for v in p) for k,p in m.pivots.items()}
    return m

def aircraft(Model,material,pigeon=False):
    m=Model('6bddd6')
    if pigeon:
        m.materials[0]=material('pigeon_feathers','8495aa',0,.9)
        m.materials[1]=material('purple_neck','66577c',.05,.7)
        m.materials[3]=material('neck_teal','4ba399',.12,.6)
        m.materials[5]=material('orange_beak','e3a148',0,.8)
        m.materials.extend([material('eye_white','fff4df',0,.7)])
        oval(m,(0,.08,.1),(.46,.5,.67),0)
        oval(m,(0,.43,-.26),(.36,.45,.36),3)
        oval(m,(0,.74,-.53),(.42,.38,.42),0)
        for x in [-.29,.29]:
            oval(m,(x,.81,-.78),(.16,.17,.095),7,10)
            oval(m,(x,.79,-.86),(.075,.09,.035),2,10)
        m.profile([(-.18,-.3),(.18,-.3),(0,-.67)],[(.59,.8),(.72,1),(.78,.2)],5,(0,0,-.5))
        m.profile([(-.32,.4),(.32,.4),(.38,1),(-.38,1)],[(.05,1),(.15,1)],1)
        for side,part in [(-1,'LeftWing'),(1,'RightWing')]:
            m.part=part;m.pivots[part]=(side*.37,.27,.05)
            poly=[(.32,-.25),(1.05,-.12),(1.48,.5),(1.28,.74),(.35,.45)]
            poly=[(x*side,z) for x,z in poly]
            if side<0:poly.reverse()
            m.profile(poly,[(.16,1),(.27,1),(.33,.93)],0)
            for k in range(4):
                m.strut((side*(.65+k*.17),.29,.17),(side*(.75+k*.18),.28,.59),.055,1)
        m.part='Hull'
        for side in [-1,1]:
            m.strut((side*.2,-.29,.2),(side*.2,-.56,.3),.07,5)
            m.strut((side*.2,-.56,.3),(side*.2,-.56,.05),.09,5)
        # Ridiculously small strapped energy cannon; the pigeon is a reusable combat unit.
        m.part='Weapon';m.pivots['Weapon']=(0,-.2,-.35)
        m.block((.32,.28,.62),(0,-.25,-.4),1,.07)
        m.block((.2,.2,.12),(0,-.25,-.77),4,.04)
    else:
        m.materials[0]=material('coral_aircraft_paint','d7563b',.25,.7)
        oval(m,(0,.25,-.7),(1.0,.75,1.12),0)
        oval(m,(0,.25,-1.5),(.83,.56,.45),5)
        oval(m,(0,.7,-.71),(.64,.51,.72),6)
        for x in [-.36,.36]:m.block((.2,.18,.08),(x,.65,-1.36),4,.04)
        # Small tapered tail and stub wings contrast with the huge forward fuselage.
        m.profile([(-.62,-.15),(.62,-.15),(.16,1.8),(-.16,1.8)],[(.1,1),(.42,.8)],1)
        for side in [-1,1]:
            poly=[(.5,-.45),(2,-.02),(1.85,.7),(.38,.5)]
            poly=[(x*side,z) for x,z in poly]
            if side<0:poly.reverse()
            m.profile(poly,[(.04,1),(.19,1)],0)
            m.block((.17,.08,.5),(side*1.45,.24,.28),5,.03)
        m.block((.12,.67,.62),(0,.61,1.45),0,.1)
        for side in [-1,1]:m.block((.64,.09,.34),(side*.35,.31,1.55),5,.05)
        m.block((.22,.22,.18),(0,.27,1.85),4,.04)
        # Crossed repair tape on the nose.
        m.strut((-.23,.25,-1.92),(.23,.43,-1.92),.055,3)
        m.strut((-.23,.43,-1.92),(.23,.25,-1.92),.055,3)
    return m

def scrap_roof(m,material,kind):
    # Keep sci-fi silhouettes, add hand-repaired shelters on non-moving modules.
    roofs={0:[(-2.25,1.82,1.25,1.7,1.9),(2.25,1.82,1.25,1.7,1.9)],1:[(-1.95,1.93,0,1.35,1.8)],2:[(-1,1.92,0,2.55,3.65)],3:[(0,1.45,1.6,4,.95)],4:[(0,1.35,-2,2.6,1)],5:[(0,2.89,0,4.35,3.8)],6:[(0,3.47,-.25,5.9,4.9)],7:[(-1.65,1.92,1.2,2,1.55)],8:[(-1.7,.95,-1.45,1.25,1.5)],9:[(0,1.08,2.05,2,1)],10:[(-.9,3.38,-.3,2.85,3.25)],11:[(-1.85,1.02,-1.4,1.2,1.5)],12:[(0,3.66,0,5.2,4.9)],13:[(0,3.11,-.5,5,3.8)]}
    m.materials[0]=material('weathered_colony_enamel','697f72',.2,.77)
    indices=[]
    for name,color in [('old_zinc','87948a'),('rust','93593b'),('flaking_ochre','aa8b53'),('patch_blue','507b80')]:
        indices.append(len(m.materials));m.materials.append(material(name,color,.35 if name=='old_zinc' else .1,.9))
    m.part='CorrugatedRoof';rng=random.Random(1942+kind)
    for cx,cy,cz,w,d in roofs[kind]:
        def height(x,z):return cy+.34*(1-abs(x)/(w/2))+.045*math.cos(z*TAU/.24)
        nx=max(4,int(w/.38));nz=max(4,int(d/.12))
        for ix in range(nx):
            for iz in range(nz):
                x0=-w/2+w*ix/nx;x1=-w/2+w*(ix+1)/nx;z0=-d/2+d*iz/nz;z1=-d/2+d*(iz+1)/nz
                if ix in [0,nx-1] and iz%11==kind%11:continue
                mat=indices[1] if rng.random()<.13 else indices[0]
                p=lambda x,z:(cx+x,height(x,z),cz+z)
                m.quad(p(x0,z0),p(x0,z1),p(x1,z1),p(x1,z0),mat)
        # Overlapping repair plates, fasteners and an uneven ridge cap.
        for k in range(4):
            x=rng.uniform(-w*.3,w*.3);z=rng.uniform(-d*.3,d*.3)
            y=height(x,z)+.08
            m.block((w*.18,.055,d*.16),(cx+x,y,cz+z),indices[2+k%2],.01,yaw=rng.uniform(-.2,.2))
            for dx in [-w*.06,w*.06]:m.drum(.035,.045,(cx+x+dx,y+.04,cz+z),2,6)
        m.strut((cx,cy+.43,cz-d/2),(cx,cy+.46,cz+d/2),.12,indices[1])


def weathered_details(m,material,kind):
    rust=len(m.materials);m.materials.append(material('deep_rust_edges','8c4c2e',.08,.95))
    patch=len(m.materials);m.materials.append(material('old_painted_patch','bf9a60',.05,.94))
    m.part='ScrapRepairs'
    for side in [-1,1]:
        x=side*(2.65 if kind in [6,12,13] else 2.15)
        # Crooked plates, visible rivets, crossed supports and a bent external pipe.
        m.block((.14,.75,1.25),(x,1.0,-.5),rust,.04,yaw=side*.09)
        m.block((.16,.35,.55),(x+side*.09,1.08,-.35),patch,.02,yaw=-side*.13)
        for z in [-.85,-.25]:m.block((.06,.07,.07),(x+side*.16,1.22,z),3,.01)
        m.strut((x,.6,-1.35),(x,1.42,-.3),.07,rust)
        m.strut((x,.58,.65),(x,1.07,.82),.09,rust)
        m.strut((x,1.07,.82),(x-side*.25,1.3,.82),.09,rust)
    # Two damaged supply crates make the settlement feel lived in.
    for i in range(2):
        x=-2+i*.7;z=2.0
        m.block((.52,.45,.55),(x,.76,z),patch,.05,yaw=.13*i)
        m.strut((x-.2,.99,z-.2),(x+.2,.99,z+.2),.045,rust)
