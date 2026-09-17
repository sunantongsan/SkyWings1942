"""Three original buildable army camps: 13 x 10 m, batched GLBs, no atlas."""
def build_camps(Model, material):
    results=[]
    for kind,name,color in [(0,'vehicle_camp','f4b747'),(1,'air_camp','54c9eb'),(2,'infantry_camp','69dca2')]:
        m=Model(color)
        m.block((13,.24,10),(0,.12,0),1,.12)
        for x in [-6.2,6.2]: m.block((.14,.08,9.5),(x,.27,0),5,.01)
        for z in [-4.7,4.7]: m.block((12.5,.08,.14),(0,.27,z),5,.01)
        for x in [-4,0,4]:m.block((.1,.025,8),(x,.26,0),0,.005)
        for z in [-3.9,0,3.9]:m.block((12,.025,.1),(0,.26,z),0,.005)
        for x in [-6.0,6.0]:
            for z in [-4.4,4.4]:
                m.block((.35,.7,.35),(x,.55,z),3,.03);m.block((.26,.15,.26),(x,.96,z),4,.02)
        # Small check-in booth and faction pennant leave the main apron open.
        m.block((2.2,1.6,1.3),(-4.6,1.05,-3.7),1,.12)
        m.block((2.5,.15,1.6),(-4.6,1.93,-3.7),3,.04)
        m.block((1.4,.6,.04),(-4.6,1.4,-3.02),6,.015)
        m.strut((5.7,.3,-4.3),(5.7,3.2,-4.3),.1,3)
        m.block((1.2,.6,.04),(5.15,2.8,-4.3),4,.01)
        if kind==1:
            for x in [-.8,.8]:m.block((.2,.04,2),(x,.29,0),4,.005)
            m.block((1.8,.04,.2),(0,.29,0),4,.005)
        elif kind==0:
            for x in [-.9,.9]:m.block((.3,.04,2.1),(x,.29,0),5,.005)
            m.block((1.2,.04,1.5),(0,.29,0),5,.005)
        else:
            for x,z in [(0,-.9),(-.9,.5),(.9,.5)]:m.drum(.25,.04,(x,.3,z),4,12)
        results.append(m.export(name))
    return results
