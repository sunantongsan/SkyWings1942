"""Original GALAXY 1942 ground force GLBs with independently animated parts."""
NAMES=['battle_tank','siege_tank','artillery','rocket_launcher','mech_warrior','sniper_unit','shield_drone','repair_drone','assault_soldier','elite_commander']
def tracked(Model,kind):
    m=Model('70deff' if kind==10 else 'ffbd69');length=2.5 if kind==10 else 2.9
    m.block((1.85,.65,length),(0,.75,0),1,.18);m.block((1.7,.2,length-.2),(0,1.13,0),0,.1)
    for x in [-.95,.95]:
        m.block((.6,.72,length+.2),(x,.43,0),2,.15)
        for i in range(12):
            z=-length/2+i*length/11
            m.block((.68,.14,.18),(x,.84,z),3,.02);m.block((.68,.14,.18),(x,.08,z),3,.02)
        m.block((.25,.1,.12),(x,.98,length/2),4,.02)
    for x in [-.65,.65]:
        for z in [-1.1,-.8,-.5]:m.block((.4,.07,.08),(x,1.27,z),2,.01)
    m.part='Turret';m.pivots['Turret']=(0,1.25,0)
    m.block((1.55,.8,1.45),(0,1.57,0),0,.18);m.drum(.32,.12,(.35,1.98,-.35),3,12)
    m.part='Weapon';m.pivots['Weapon']=(0,1.7,.5)
    if kind in [10,11]:
        for x in ([0] if kind==10 else [-.57,.57]):
            m.block((.48,.48,1.75),(x,1.83,1.4),3,.04);m.block((1.05,.95,.8),(x,1.83,2.25),1,.07);m.block((.73,.65,.04),(x,1.83,2.67),4,.02)
    elif kind==12:
        m.strut((0,1.7,.2),(0,2.6,3.4),.3,3);m.strut((0,2.5,3.05),(0,2.7,3.75),.5,1)
    else:
        for x in [-.65,0,.65]:
            for y in [2,2.5]:
                m.block((.56,.45,2.3),(x,y,.2),1,.08);m.block((.35,.26,.08),(x,y,1.4),2,.02);m.block((.15,.15,.09),(x,y,1.45),4,.02)
    return m

def infantry(Model,kind):
    m=Model('ffd477' if kind==19 else ('ba8aff' if kind==15 else '6bebdf'));scale=1.45 if kind==14 else 1
    def b(size,pos,mat=0,bevel=.06):m.block(tuple(v*scale for v in size),tuple(v*scale for v in pos),mat,bevel*scale)
    for sign,name in [(-1,'LeftLeg'),(1,'RightLeg')]:
        m.part=name;m.pivots[name]=(sign*.23*scale,.95*scale,0)
        b((.28,.47,.32),(sign*.23,.74,0),1);b((.34,.22,.38),(sign*.23,.52,.06),0)
        b((.26,.35,.29),(sign*.23,.28,0),3);b((.34,.17,.55),(sign*.23,.095,.13),2)
    m.part='Body';b((.63,.28,.4),(0,1,0),1);b((.8 if kind==14 else .7,.66,.5),(0,1.45,0),0,.1)
    b((.45,.24,.09),(0,1.54,.28),1);b((.3,.06,.06),(0,1.54,.34),4,.01)
    b((.6,.5,.22),(0,1.4,-.34),1)
    for x in [-.16,.16]:b((.1,.36,.1),(x,1.42,-.5),4,.02)
    b((.42,.42,.44),(0,2.02,0),0,.09);b((.34,.14,.06),(0,2.07,.25),4,.02);b((.25,.1,.06),(0,1.85,.24),2)
    if kind==19:
        b((.94,.16,.65),(0,1.83,0),5);b((.58,.9,.09),(0,1.23,-.54),1,.02);b((.06,.8,.06),(.42,2,-.22),3,.01)
    for sign,name in [(-1,'LeftArm'),(1,'RightArm')]:
        m.part=name;m.pivots[name]=(sign*.48*scale,1.72*scale,0)
        b((.33,.26,.43),(sign*.48,1.73,0),0,.08);b((.23,.37,.28),(sign*.5,1.43,.1),1)
        b((.24,.22,.43),(sign*.47,1.24,.33),0);b((.22,.2,.22),(sign*.42,1.23,.56),2)
    m.part='Weapon';m.pivots['Weapon']=(.3*scale,1.32*scale,.5*scale)
    b((.24,.26,.78),(.32,1.32,.67),1);length=1 if kind==15 else .55
    b((.1,.1,length),(.32,1.37,1.12+length*.3),3,.02);b((.14,.14,.1),(.32,1.37,1.18+length*.8),4,.01)
    if kind==15:b((.12,.12,.4),(.32,1.53,.85),6,.02)
    return m

def utility(Model,kind):
    m=Model('77aaff' if kind==16 else '6dffc4');m.drum(.65,.35,(0,0,0),0,12);m.drum(.38,.13,(0,.22,0),6,12)
    for x in [-1,1]:
        m.strut((x*.35,0,0),(x*.9,0,0),.13,3);m.block((.45,.23,.8),(x*.85,0,0),1,.08);m.block((.16,.09,.48),(x*.85,-.17,0),4,.02)
    if kind==16:
        m.ring(.76,.08,4,.08);m.part='Rotor';m.ring(.95,.18,4,.05)
    else:
        for x in [-.35,.35]:m.strut((x,-.15,.2),(x,-.48,.6),.09,3);m.block((.14,.2,.18),(x,-.48,.65),4,.02)
        m.block((.13,.03,.45),(0,.31,0),4,.01);m.block((.4,.03,.13),(0,.31,0),4,.01)
    return m

def build_ground_assets(Model,material):
    from cartoon_models import infantry as cartoon_infantry
    return [(tracked(Model,k) if k<=13 else utility(Model,k) if k in [16,17] else cartoon_infantry(Model,material,k)).export(name) for k,name in enumerate(NAMES,10)]
