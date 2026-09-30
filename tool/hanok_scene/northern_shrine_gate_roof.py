"""Shrine gate roof from sheets 086-088, not the generic estate tile grid.

Sheet 088 shows six central sukiwa runs, flanked by raised three-course
descending ridges. Sheet 087 gives square 75x90 rafters and THK30 boarding.
The tile profiles and curvature are fitted to photographs, not new survey data.
"""
from pathlib import Path
import bpy,math,sys
from mathutils import Vector,Matrix
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923')
sys.path.insert(0,str(OLD/'tool/hanok_scene'))
import reconstruction_geometry as g

def refine_shrine_gate_roof(scene,records):
    if any(o.get('shrineGateRoofVersion') for o in scene.objects):return []
    rec=next(r for r in records if r['id']=='sadangmun');origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z')
    transform=lambda p:origin+rot@Vector(p)
    green=bpy.data.materials['North aged blue green'];red=bpy.data.materials['North weathered vermilion']
    lime=bpy.data.materials['North lime plaster'];earth=bpy.data.materials['North earthen plaster'];end=bpy.data.materials['North lime tile ends']
    tiles=[bpy.data.materials[f'Ansarang retained V33 main_gate source ceramic {i}'] for i in range(6)]
    removed=[]
    for ob in list(scene.objects):
        if ob.type=='MESH' and ob.get('construction_building')=='sadangmun' and (ob.name.startswith('North.sadangmun.roof') or 'photo gate painted rafter end' in ob.name or 'green lintel' in ob.name):
            removed.append(ob.name);bpy.data.objects.remove(ob,do_unlink=True)
    # The drawing's 1800 mm post/head dimension starts at the 200 mm footing.
    for ob in scene.objects:
        if ob.type!='MESH' or ob.get('construction_building')!='sadangmun' or 'round vermilion gatepost' not in ob.name:continue
        inv=ob.matrix_world.inverted()
        for v in ob.data.vertices:
            p=rot.transposed()@(ob.matrix_world@v.co-origin);p.z=.20+(p.z-.20)*(1.80/1.95);v.co=inv@(origin+rot@p)
        ob['gatePostHeadMeters']=2.0
    g.BATCHES.clear();g.set_transform(transform);nm='North.sadangmun.roof'
    def face(tag,points,mat):g.face(nm+tag,points,mat)
    def box(tag,center,size,mat):g.box(nm+tag,center,size,mat)
    def prism_y(tag,profile,y0,y1,mat):
        face(tag,[(x,y0,z) for x,z in reversed(profile)],mat);face(tag,[(x,y1,z) for x,z in profile],mat)
        for a,b in zip(profile,profile[1:]+profile[:1]):face(tag,[(a[0],y0,a[1]),(b[0],y0,b[1]),(b[0],y1,b[1]),(a[0],y1,a[1])],mat)
    def height(x,y):
        t=abs(y)/.97
        return 2.20+.58*(1-t)**1.45+.13*(abs(x)/1.285)**6*t*t+.035*(abs(x)/1.285)**8*(1-t)
    # A real continuous 30 mm board ceiling over seven square rafters.
    rafter_x=(-1.11,-.675,-.3375,0,.3375,.675,1.11)
    for x in rafter_x:box('.measured square rafter',(x,0,2.045),(.075,1.88,.090),green)
    box('.measured dori',(0,0,1.925),(1.53,.082,.150),green)
    for i in range(14):box('.thirty millimetre boarding',(-1.285+(i+.5)*2.57/14,0,2.105),(2.57/14-.001,1.94,.030),lime)
    for y in (-.955,.955):box('.red fascia',(0,y,2.125),(2.57,.030,.110),red)
    # Earth bedding has a closed volume above the boards; no floating roof skin.
    nx,ny=16,12
    for i in range(nx):
        for j in range(ny):
            x0=-1.25+i*2.50/nx;x1=x0+2.50/nx;y0=-.925+j*1.85/ny;y1=y0+1.85/ny
            upper=[(x,y,height(x,y)-.035) for x,y in ((x0,y0),(x1,y0),(x1,y1),(x0,y1))];lower=[(x,y,2.12) for x,y,z in upper]
            face('.solid earthen bedding',upper,earth);face('.solid earthen bedding',list(reversed(lower)),earth)
            for k,boundary in enumerate((j==0,i==nx-1,j==ny-1,i==0)):
                if boundary:q=(k+1)%4;face('.solid earthen bedding',[lower[k],lower[q],upper[q],upper[k]],earth)
    # Six ordinary cover runs between the raised side ridges; a return on each wing.
    centerlines=(-.675,-.405,-.135,.135,.405,.675)
    spans=[(-.81+i*.27,-.81+(i+1)*.27,centerlines[i]) for i in range(6)]
    spans=[(-1.285,-.81,-1.085)]+spans+[(.81,1.285,1.085)]
    for side in (-1,1):
        for col,(left,right,cx) in enumerate(spans):
            for row in range(7):
                y0=side*.97*row/7;y1=side*.97*min(1,(row+1.055)/7)
                for k in range(8):
                    a=k/8;b=(k+1)/8;xa=left+(right-left)*a;xb=left+(right-left)*b
                    za=-.027*abs(math.cos(a*math.pi));zb=-.027*abs(math.cos(b*math.pi))
                    face('.concave amkiwa',[(xa,y0,height(xa,y0)+za),(xb,y0,height(xb,y0)+zb),(xb,y1,height(xb,y1)+zb+.015),(xa,y1,height(xa,y1)+za+.015)],tiles[(col+row)%6])
                for k in range(12):
                    a=k*math.pi/12;b=(k+1)*math.pi/12;points=[]
                    for y,t,overlap in ((y0,a,0),(y0,b,0),(y1,b,.015),(y1,a,.015)):
                        x=cx+.067*math.cos(t);points.append((x,y,height(x,y)+.025+.060*math.sin(t)+overlap))
                    face('.six central sukiwa' if abs(cx)<.8 else '.wing return sukiwa',points,tiles[(col*3+row)%6])
            z=height(cx,side*.97)+.045
            g.rod(nm+'.round tile ends',(cx,side*.951,z),(cx,side*.984,z),.068,end,16)
        # Raised descending ridges, each with three flat tile courses and a rounded cap.
        for x in (-.82,.82):
            for row in range(7):
                a=row/7;b=min(1,(row+1.025)/7);ya=side*.92*a;yb=side*.92*b
                for level in range(3):
                    half=.123-level*.009
                    pts=[(x+dx,y,height(x+dx,y)+.06+level*.027+.085*t**4) for dx,y,t in ((-half,ya,a),(half,ya,a),(half,yb,b),(-half,yb,b))]
                    face('.three course descending ridge',pts,tiles[(row+level)%6])
                for k in range(12):
                    aa=k*math.pi/12;bb=(k+1)*math.pi/12;pts=[]
                    for y,t,q,overlap in ((ya,a,aa,0),(ya,a,bb,0),(yb,b,bb,.012),(yb,b,aa,.012)):
                        xx=x+.092*math.cos(q);pts.append((xx,y,height(xx,y)+.130+.085*t**4+.088*math.sin(q)+overlap))
                    face('.descending ridge curved cover',pts,tiles[row%6])
            # Open dark half-arch nose enclosing the lime bedding, visible in photo.
            y=side*.928;z=height(x,y)+.119+.085
            outer=[(x+.119*math.cos(k*math.pi/16),z+.161*math.sin(k*math.pi/16)) for k in range(17)]
            inner=[(x+.086*math.cos(k*math.pi/16),z+.117*math.sin(k*math.pi/16)) for k in reversed(range(17))]
            prism_y('.hollow barge terminal',outer+inner,y-.018,y+.018,tiles[0])
            fill=[(x+.083*math.cos(k*math.pi/16),z-.010+.050*math.sin(k*math.pi/16)) for k in range(17)]
            prism_y('.barge lime bed',fill,y-.022,y+.010,end)
    # A packed ridge core closes the spaces between the top amkiwa and ridge.
    lower=[];upper=[]
    for i in range(33):
        x=-.98+1.96*i/32;curve=.085*(abs(x)/.98)**8
        lower.append((x,2.750+.015*(abs(x)/.98)**8));upper.append((x,2.895+curve))
    prism_y('.packed ridge bedding',lower+list(reversed(upper)),-.060,.060,tiles[0])
    # Ridge center top is 200 + 2875 mm (sheet 087); curved tips rise above it.
    for level in range(3):
        for i in range(32):
            a=-.98+1.96*i/32;b=-.98+1.96*(i+1)/32
            za=2.890+level*.065+.085*(abs(a)/.98)**8;zb=2.890+level*.065+.085*(abs(b)/.98)**8
            g.rod(nm+'.three course main ridge',(a,0,za),(b,0,zb),.055,tiles[level],16)
    # Individually thick red gable boarding instead of a textured triangle plane.
    for x in (-1.27,1.27):
        for i in range(14):
            y0=-.97+i*1.94/14+.001;y1=y0+1.94/14-.002
            points=[(y0,2.08),(y1,2.08),(y1,height(x,y1)-.043),(y0,height(x,y0)-.043)]
            face('.solid gable boarding',[(x-.015,y,z) for y,z in reversed(points)],red);face('.solid gable boarding',[(x+.015,y,z) for y,z in points],red)
            for a,b in zip(points,points[1:]+points[:1]):face('.solid gable boarding',[(x-.015,a[0],a[1]),(x-.015,b[0],b[1]),(x+.015,b[0],b[1]),(x+.015,a[0],a[1])],red)
    obs=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
    for ob in obs:
        ob['construction_building']='sadangmun';ob['construction_first']=1;ob['construction_last']=99;ob['source_object_name']=ob.name;ob['northExtension']=True;ob['shrineGateRoofVersion']=1
        for mod in ob.modifiers:
            if mod.type=='BEVEL':mod.width=.002;mod.segments=2
        if any(s in ob.name for s in ('measured square rafter','boarding','fascia','earthen bedding')):
            for p in ob.data.polygons:p.use_smooth=False
    return [{'building':'sadangmun','replacedMeshes':len(removed),'newMeshes':len(obs),'centralCoverRuns':6,'wingReturnRuns':2,'raisedDescendingRidges':2,'ridgeCourses':3,'rafterSectionMeters':[.075,.090],'ceilingBoardThicknessMeters':.030,'postHeadAboveFootingMeters':1.800,'centralRidgeAboveFootingMeters':2.875,'evidence':'2007 sheets 086, 087 and 088 plus supplied actual gate photograph','profileCurvatureIsPhotographicFit':True}]
