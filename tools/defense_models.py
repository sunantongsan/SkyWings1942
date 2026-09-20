"""Original defense GLBs: animated turrets and five material-specific wall ranks."""
def build_defenses(Model, material):
    out=[]
    for name,color in [('flak_battery','68e8cf'),('siege_mortar','ffb94f'),('sky_sentinel','63bcff')]:
        m=Model(color)
        m.materials[0]=material('worn_teal_armor','397d7c',.55,.66)
        m.materials.append(material('rust','a65d32',.3,.85))
        m.block((4.4,.45,4.1),(0,.23,0),1,.22)
        for x in [-1.9,1.9]:
            for z in [-1.7,1.7]:
                m.block((.6,.85,.6),(x,.62,z),3,.1)
                m.block((.45,.1,.45),(x,1.08,z),4,.04)
        m.drum(1.6,.8,(0,.85,0),0)
        m.ring(1.4,1.3,4)
        m.part='Turret'
        m.pivots['Turret']=(0,1.45,0)
        m.block((2.4,.8,1.6),(0,1.7,0),0,.18)
        if name=='flak_battery':
            # Four long, oversized barrels and side ammunition drums.
            for x in [-.55,.55]:
                for y in [1.8,2.18]:
                    m.strut((x,y,.4),(x,y,3.0),.22,3)
                    m.block((.3,.3,.3),(x,y,3.0),2,.05)
                m.drum(.4,.7,(x*2.2,1.85,0),5)
            m.block((.4,.5,.45),(0,2.3,-.35),6,.08)
        elif name=='siege_mortar':
            # Heavy open cannon muzzle, inclined toward its impact point.
            m.strut((0,1.65,.1),(0,3.25,2.2),.85,3)
            m.strut((0,3.18,2.1),(0,3.4,2.4),1.05,1)
            m.strut((0,3.37,2.36),(0,3.43,2.44),.72,2)
            for x in [-1.1,1.1]:m.block((.4,1.0,1.7),(x,1.7,.3),5,.12)
        else:
            for x in [-.85,.85]:
                m.block((1.1,1.5,2.2),(x,2.1,.4),0,.13)
                for y in [1.65,2.1,2.55]:
                    m.block((.7,.32,.1),(x,y,1.55),2,.03)
                    m.block((.2,.2,.18),(x,y,1.64),4,.04)
            m.strut((0,1.9,-.5),(0,3.6,-.5),.14,3)
            m.block((1.3,.5,.16),(0,3.6,-.5),6,.05)
        m.part='Hull'
        for x,z in [(-1.7,-1.2),(1.8,.5),(-.5,-1.8)]:m.block((.45,.06,.32),(x,.49,z),7,.015)
        out.append(m.export(name))
    for level,(name,color) in enumerate([('wall_bamboo','859a38'),('wall_earth','a8794e'),('wall_concrete','b3b8b4'),('wall_steel','52788a'),('wall_fire','ff722d')],1):
        m=Model(color)
        m.materials[0]=material('wall_material',color,.65 if level>=4 else 0,.52 if level>=4 else .96)
        m.materials.append(material('bamboo_joints','c5b877',0,.9))
        m.block((6,.3,1.4),(0,.15,0),1,.12)
        if level==1:
            for i in range(15):
                x=-2.8+i*.4
                m.drum(.19,2.6,(x,1.5,0),0,8)
                for y in [.65,1.35,2.05]:m.drum(.21,.09,(x,y,0),7,8)
            for y in [.7,1.9]:m.block((5.9,.13,.17),(0,y,.24),7,.015)
        elif level==2:
            m.block((6,2.25,1.25),(0,1.3,0),0,.32)
            for x in [-2.5,-1.3,0,1.3,2.5]:m.block((.8,.3,1.28),(x,2.55,0),0,.12)
        elif level==3:
            for x in [-2.2,0,2.2]:m.block((1.95,2.5,1),(x,1.55,0),0,.08)
            for x in [-2.9,2.9]:m.block((.28,2.9,1.2),(x,1.7,0),3,.04)
        else:
            m.block((6,2.6,1.2),(0,1.6,0),0,.12)
            for x in [-2.7,-1.35,0,1.35,2.7]:
                m.block((.18,2.8,1.35),(x,1.6,0),3,.04)
                for y in [.6,2.6]:m.block((.3,.25,.08),(x,y,.72),5,.03)
            if level==5:
                for x in [-2.1,2.1]:m.block((1.1,.22,1.0),(x,3.0,0),4,.04)
                m.part='Turret';m.pivots['Turret']=(0,3.0,0)
                m.block((1,.5,.8),(0,3.25,0),1,.09)
                for x in [-.23,.23]:m.strut((x,3.35,.3),(x,3.35,1.6),.14,3)
        out.append(m.export(name))
    m=Model('45c9bc')
    for x in [-2.8,2.8]:
        m.block((.8,3.8,1.4),(x,1.9,0),0,.12)
        m.block((.5,.25,.7),(x,3.95,0),4,.05)
    m.block((6.4,.4,1.2),(0,3.7,0),3,.08)
    for side,name in [(-1,'GateLeft'),(1,'GateRight')]:
        m.part=name
        m.block((2.3,3.1,.65),(side*1.15,1.6,0),0,.1)
        for y in [.6,1.6,2.6]:m.block((2.1,.18,.75),(side*1.15,y,0),5,.03)
    out.append(m.export('base_gate'))
    m=Model('cb80ff')
    m.materials[0]=material('prospector_violet','704c9e',.35,.6)
    m.block((2.1,.7,3.1),(0,.85,0),0,.15)
    for x in [-1.1,1.1]:
        m.block((.55,.8,3.1),(x,.45,0),2,.15)
        for z in [-1,0,1]:m.block((.6,.4,.5),(x,.45,z),3,.07)
    m.block((1.6,1.1,1.0),(0,1.55,.7),0,.13)
    m.block((1.3,.6,.08),(0,1.65,1.24),6,.04)
    m.block((1.7,.7,1.2),(0,1.4,-.8),5,.12)
    for x in [-.45,0,.45]:m.drum(.22,.2,(x,1.85,-.8),5)
    m.part='Drill';m.pivots['Drill']=(0,.9,2)
    m.drum(.65,.8,(0,.9,2),3)
    for x in [-.35,.35]:m.strut((x,.9,1.6),(x,.9,2.6),.2,5)
    out.append(m.export('coin_prospector'))
    return out
