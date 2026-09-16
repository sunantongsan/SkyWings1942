"""Original Godot fantasy faction: ivory stone, gilt ribs, amethyst runes.
Standalone GLBs with authored silhouettes and animation pivots, no image atlas.
"""
import math
TAU=math.tau
BUILDINGS=['godot_citadel','astral_well','summoning_sanctum','runebolt_spire']
UNITS=['rune_guardian','crystal_golem','starweaver']
def build_faction_assets(Model,material):
    def model():
        m=Model('c887ff')
        m.materials[0]=material('moonstone_ivory','ded9c3',.1,.64)
        m.materials[1]=material('obsidian_violet','35234f',.35,.48)
        m.materials[2]=material('deep_rune_recess','171529',.05,.8)
        m.materials[3]=material('antique_gold','d7ad58',.65,.36)
        m.materials[5]=material('astral_teal','74ded4',.2,.4,True)
        m.materials[6]=material('silk_violet','78579f',.05,.8)
        return m
    def crystal(m,pos,scale=1,mat=4):
        poly=[(math.cos(a*TAU/6)*.3*scale,math.sin(a*TAU/6)*.3*scale) for a in range(6)]
        m.profile(poly,[(-.6*scale,0),(-.3*scale,1),(.35*scale,.85),(.9*scale,0)],mat,pos)
    def spire(m,x,z,height):
        m.drum(.48,.2,(x,.6,z),3,8)
        m.lathe([(.4,.7),(.28,height-.6),(.5,height-.55),(0,height+.2)],0,(x,0,z),8)
        for a in range(4):
            angle=a*TAU/4
            m.strut((x+math.cos(angle)*.29,.8,z+math.sin(angle)*.29),(x+math.cos(angle)*.2,height-.65,z+math.sin(angle)*.2),.055,3)
        crystal(m,(x,height+.2,z),.4)
    def arch(m,x,z,width,height):
        for sign in [-1,1]:
            m.strut((x+sign*width/2,.55,z),(x+sign*width/2,height*.65,z),.2,0)
            m.strut((x+sign*width/2,height*.65,z),(x,height,z),.18,0)
            m.strut((x+sign*(width/2-.12),height*.65,z+.03),(x,height-.16,z+.03),.045,3)
    def base(m):
        m.drum(2.65,.26,(0,.13,0),1,8);m.drum(2.48,.2,(0,.36,0),0,8)
        m.ring(2.38,.48,3,.07,n=32)
        for a in range(12):
            t=a*TAU/12
            m.block((.12,.04,.27),(math.sin(t)*2.15,.49,math.cos(t)*2.15),4,.01,t)
        for i in range(3):m.block((1.3,.1*(i+1),.35),(0,.05*(i+1),3-i*.31),0,.04)
    results=[]
    for kind,name in enumerate(BUILDINGS):
        m=model();base(m)
        if kind==0:
            # Cathedral keep: angled buttresses, lancet windows, four crowned spires.
            m.drum(1.75,1.7,(0,1.35,0),0,8)
            m.lathe([(1.9,2.2),(1.9,2.35),(.55,3.6),(0,3.8)],1,n=8)
            for a in range(8):
                t=a*TAU/8
                x,z=math.sin(t)*1.78,math.cos(t)*1.78
                m.block((.3,.85,.09),(x,1.55,z),2,.03,t)
                m.block((.12,.62,.1),(x,1.57,z),4,.02,t)
                m.strut((math.sin(t)*1.93,2.36,math.cos(t)*1.93),(math.sin(t)*.5,3.65,math.cos(t)*.5),.065,3)
            for x in [-1.65,1.65]:
                for z in [-1.65,1.65]:spire(m,x,z,3.7)
            arch(m,0,1.9,1.15,2.4)
            m.part='Rotor';m.ring(.78,4.15,3,.06);crystal(m,(0,4.3,0),.9)
        elif kind==1:
            # Open crescent well with concentric water and floating crystal heart.
            m.lathe([(1.65,.48),(1.7,.85),(1.5,1.12),(1.3,1.12),(1.2,.65)],0,n=24)
            m.drum(1.22,.08,(0,.72,0),5,24);m.ring(1.6,1.12,3,.08)
            for a in range(6):
                t=a*TAU/6;spire(m,math.sin(t)*2,math.cos(t)*2,2.1)
            m.part='Rotor';m.ring(.92,1.65,4,.055);crystal(m,(0,2.2,0),1.25)
            for a in range(6):
                t=a*TAU/6;crystal(m,(math.sin(t)*.98,2,math.cos(t)*.98),.23,5)
        elif kind==2:
            # Summoning gate with pointed arches, flanking chapels and rune dais.
            m.drum(1.32,.1,(0,.56,0),1,12);m.ring(1.2,.63,4,.075)
            for x in [-1.9,1.9]:
                m.block((.9,1.7,2.3),(x,1.35,0),0,.15)
                m.profile([(-.55,-1.25),(.55,-1.25),(.55,1.25),(-.55,1.25)],[(2.2,1),(3.4,.08)],1,(x,0,0))
                spire(m,x,-1.35,3.7)
            arch(m,0,-.2,2.65,4.35);arch(m,0,.25,2.65,4.35)
            for a in range(8):
                t=a*TAU/8;m.strut((math.sin(t)*.45,.66,math.cos(t)*.45),(math.sin(t)*1,.66,math.cos(t)*1),.06,3)
            m.part='Rotor';crystal(m,(0,2.3,0),1.15);m.ring(.65,1.4,5,.05)
        else:
            # Four inward-curved claw ribs surround a rotating runic bolt crown.
            m.lathe([(1.2,.48),(1.05,.75),(.62,2.4),(.9,2.55),(.9,2.75)],0,n=8)
            for a in range(4):
                t=a*TAU/4
                m.strut((math.sin(t)*1.25,.55,math.cos(t)*1.25),(math.sin(t)*.85,2.8,math.cos(t)*.85),.22,3)
                crystal(m,(math.sin(t)*1.8,.82,math.cos(t)*1.8),.4)
            m.part='Turret';m.pivots['Turret']=(0,2.7,0)
            m.ring(.87,2.84,3,.08);crystal(m,(0,3.5,0),1.15)
            for x in [-.55,.55]:
                m.strut((x,2.9,0),(x,3.3,.9),.15,3);crystal(m,(x,3.3,.9),.35,5)
        results.append(m.export(name))
    for kind,name in enumerate(UNITS):
        m=model();scale=1.4 if kind==1 else 1
        def b(size,pos,mat=0):m.block(tuple(v*scale for v in size),tuple(v*scale for v in pos),mat,.07*scale)
        for sign,part in [(-1,'LeftLeg'),(1,'RightLeg')]:
            m.part=part;m.pivots[part]=(sign*.24*scale,.94*scale,0)
            b((.34,.7,.36),(sign*.24,.49,0),1);b((.38,.18,.62),(sign*.24,.1,.12),3)
            b((.34,.22,.4),(sign*.24,.57,.05),0)
        m.part='Body'
        if kind==2:
            m.profile([(-.55,-.35),(.55,-.35),(.55,.35),(-.55,.35)],[(.32,1),(.9,.65),(1.7,.55)],6)
            m.strut((-.5,.35,.37),(-.25,1.67,.22),.05,3);m.strut((.5,.35,.37),(.25,1.67,.22),.05,3)
        else:
            b((.9,.78,.58),(0,1.4,0),0);b((.64,.14,.65),(0,1.0,0),3)
        crystal(m,(0,1.46*scale,.34*scale),.35*scale)
        b((.46,.43,.46),(0,2.03,0),0);b((.36,.09,.08),(0,2.08,.25),5)
        if kind==2:
            m.lathe([(.5,2.2),(.32,2.33),(.1,2.95),(0,3.0)],6,n=6)
            m.ring(.46,2.22,3,.05,n=12)
        else:
            for x in [-.19,.19]:m.strut((x*scale,2.18*scale,0),(x*1.8*scale,2.6*scale,-.1),.09*scale,3)
        for sign,part in [(-1,'LeftArm'),(1,'RightArm')]:
            m.part=part;m.pivots[part]=(sign*.59*scale,1.73*scale,0)
            b((.4,.3,.5),(sign*.59,1.75,0),3);b((.27,.62,.31),(sign*.6,1.3,.13),0)
            if kind==1:crystal(m,(sign*.72*scale,1.8*scale,0),.6,4)
        m.part='Weapon';m.pivots['Weapon']=(.6*scale,1.1*scale,.35)
        if kind==0:
            # Rune lance and shield; magical ranged weapon rather than a rifle.
            m.strut((.6,.9,.35),(.6,1.55,1.5),.11,3);crystal(m,(.6,1.6,1.55),.5)
            m.part='LeftArm';m.profile([(-.45,0),(.45,0),(.35,.3),(0,.5),(-.35,.3)],[(.95,1),(1.8,.75)],3,(-.6,0,.4))
        elif kind==1:
            crystal(m,(.82,1.4,1.0),.8);m.ring(.5,1.12,3,.07,pos=(.82,0,1))
        else:
            m.strut((.65,.4,.35),(.65,2.55,.35),.07,3);crystal(m,(.65,2.55,.35),.48)
            m.ring(.4,2.35,5,.05,pos=(.65,0,.35))
        results.append(m.export(name))
    return results
