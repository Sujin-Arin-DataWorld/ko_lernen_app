"""Jangdokdae gate: printed 2007 sheet 084 dimensions, in metres.

The 30 mm WD1 schedule takes precedence over the conflicting 20 mm
section note. Roof curvature and small hardware remain interpretations.
"""
import math, random
import numpy as np


def build(g, d, world, materials):
    wood, beam, stone, iron, tiles, end = materials
    g.set_transform(world)
    nm = 'North.site.rear yard gate'
    for x in (-.510, .510):
        g.rock(nm+'.stone plinth', (x,0,.0225), (.20,1.02,.045), stone, random.Random(x))
        g.box(nm+'.ground sill 100x115', (x,0,.1025), (.100,1.02,.115), beam)
        g.box(nm+'.main post 85x85', (x,0,1.055), (.085,.085,2.020), wood)
        for y in (-.425,.425):
            g.box(nm+'.return jamb 45x40', (x,y,.895), (.045,.040,1.500), wood)
        g.box(nm+'.transverse head 85x150', (x,0,1.670), (.085,.935,.150), beam)
        for sign in (-1,1):
            a=np.array((x,-.385,.195 if sign==1 else 1.595))
            b=np.array((x,.385,1.595 if sign==1 else .195))
            axis=(b-a)/np.linalg.norm(b-a); across=np.cross(axis,(1,0,0))
            old=g.TRANSFORM
            g.set_transform(lambda p,a=a,axis=axis,across=across,old=old:old(a+np.array((1,0,0))*p[0]+across*p[1]+axis*p[2]))
            g.box(nm+'.cross brace 40x45',(0,0,float(np.linalg.norm(b-a))/2),(.040,.045,float(np.linalg.norm(b-a))),wood)
            g.set_transform(old)
    for z in (.120,1.670):
        g.box(nm+'.head sill 85x150',(0,0,z),(1.105,.085,.150),beam)
    for x in (-.450,.450):
        g.box(nm+'.main jamb 60x45',(x,0,.895),(.060,.045,1.400),wood)
    prefix=nm+'.plank door'
    for leaf in range(2):
        a=-.420+leaf*.420; b=a+.420; pre=prefix+f'.leaf{leaf+1}'
        for j in range(3):
            g.box(pre+'.WD1 plank 30mm',(a+(j+.5)*.14,0,.895),(.138,.030,1.400),wood)
        for z in (.245,1.545):
            g.box(pre+'.back rail',((a+b)/2,.035,z),(.415,.040,.060),beam)
        pivot=a if leaf==0 else b
        for z in (.245,1.545):
            g.rod(pre+'.hinge pin',(pivot,.025,z-.035),(pivot,.025,z+.035),.008,iron,12)
        g.torus(pre+'.iron ring',(b-.055 if leaf==0 else a+.055,-.033,.895),.022,.0035,iron)
    for y in (-.415,.415):
        g.box(nm+'.eave purlin 60x40',(0,y,1.735),(1.536,.060,.040),beam)
    g.box(nm+'.ridge purlin 85x90',(0,0,2.032),(1.536,.085,.090),beam)
    roof=g.roof(nm+'.roof',(-1.105,1.105,-.758,.758),1.850,2.098,wood,tiles,end,
                turn=.075,ridge_turn=.045,columns=9,ridge_courses=3,
                cover_radius=.045,cover_height=.041)
    # Generic double round rafters are inappropriate for this small gate.
    for key in list(g.BATCHES):
        if key[0].startswith(nm+'.roof') and any(s in key[0] for s in ('rafters','eave beam','gable timber')):
            del g.BATCHES[key]
    for x in np.linspace(-.720,.720,7):
        for sign in (-1,1):
            a=np.array((x,0,2.065)); b=np.array((x,sign*.620,1.795))
            axis=(b-a)/np.linalg.norm(b-a);across=np.cross(axis,(1,0,0));old=g.TRANSFORM
            g.set_transform(lambda p,a=a,axis=axis,across=across,old=old:old(a+np.array((1,0,0))*p[0]+across*p[1]+axis*p[2]))
            g.box(nm+'.square rafter 40x50',(0,0,float(np.linalg.norm(b-a))/2),(.040,.050,float(np.linalg.norm(b-a))),wood)
            g.set_transform(old)
    for x in (-.768,.768):
        old=g.TRANSFORM
        g.set_transform(lambda p,x=x,old=old:old((x+p[1],p[0],p[2])))
        d.extruded_profile(nm+'.gable board 25mm',[(-.62,1.785),(0,2.060),(.62,1.785)],-.0125,.0125,wood)
        g.set_transform(old)
    for j in range(16):
        y0=-.758+j*1.516/16; y1=y0+1.516/16
        q=[(-1.105,y0),(1.105,y0),(1.105,y1),(-1.105,y1)]
        # The roof evaluator returns a sentinel outside its exact bounds.
        # Float addition on the last strip must not turn a board into a
        # 100 m downward spike at the eave.
        top=[(x,y,roof(max(-1.105,min(1.105,x)),max(-.758,min(.758,y)))-.065) for x,y in q]
        bottom=[(x,y,z-.020) for x,y,z in top]
        g.face(nm+'.roof board 20mm',top,wood);g.face(nm+'.roof board 20mm',list(reversed(bottom)),wood)
        for i in range(4):g.face(nm+'.roof board 20mm',[top[i],bottom[i],bottom[(i+1)%4],top[(i+1)%4]],wood)
    door={'building':'north_site','prefix':prefix,
          'hinges':[list(world((-.420,0,.195))),list(world((.420,0,.195)))],
          'rotationSigns':[-1,1],'width':.840,'height':1.400,'doorBottom':.195,'state':'closed'}
    evidence={'postAxes':1.020,'returnAxes':.850,'postSection':.085,'doorBoard':.030,
              'doorLeaves':2,'leafWidth':.420,'doorHeight':1.400,'roofPlan':[2.210,1.516],
              'sectionHeight':2.400,'jambSection':[.060,.045],'headSillSection':[.085,.150],
              'authority':'2007 Jangdokdae gate sheet 084 printed dimensions; sheet 085 elevations',
              'sourceConflict':'Section calls door THK20, WD1 schedule calls THK30. Use dedicated WD1 schedule, preserve conflict.',
              'interpreted':['Roof curve between surveyed extrema','Hardware sizes','Joint clearances']}
    return door,evidence
