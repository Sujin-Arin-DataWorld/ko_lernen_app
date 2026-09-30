"""Craft geometry supported by IlDu photographs and the unchanged canonicals.

Surveyed bay axes and roof envelopes belong to build_northern_court. These
details live inside those envelopes; photographs do not provide metric sizes.
"""
import math

def add_photo_details(c):
    ident=c['ID']
    if ident not in ('anchae','sadang','sadangmun'):return
    g,d=c['g'],c['d']; nm=c['NM']; box=c['box']; wood=c['wood']; beam=c['beam']
    green,red,yellow,lime=c['green'],c['red'],c['yellow'],c['lime']
    stone,post,black=c['stone'],c['post'],c['black']; xs=c['xs']
    def rod(tag,a,b,r,mat,n=12):g.rod(nm+'.photo '+tag,a,b,r,mat,n)
    def stroke(tag,points,y,mat,r=.004):
        for a,b in zip(points,points[1:]):rod(tag,(a[0],y,a[1]),(b[0],y,b[1]),r,mat,6)
    def ring(tag,x,y,z,r,mat,width=.004):
        stroke(tag,[(x+r*math.cos(i*math.tau/32),z+r*math.sin(i*math.tau/32)) for i in range(33)],y,mat,width)
    def flower(tag,x,y,z,r):
        rod(tag+' ground',(x,y+.003,z),(x,y,z),r,lime,32)
        for k in range(8):
            a=k*math.tau/8;xx=x+math.cos(a)*r*.55;zz=z+math.sin(a)*r*.55
            pts=[]
            for j in range(16):
                q=j*math.tau/16
                pts.append((xx+math.cos(q)*r*.22*math.cos(a)-math.sin(q)*r*.14*math.sin(a),y-.002,zz+math.cos(q)*r*.22*math.sin(a)+math.sin(q)*r*.14*math.cos(a)))
            g.face(nm+'.photo '+tag+' petal',pts,red)
        ring(tag+' green outline',x,y-.004,z,r*.86,green,.004)
        rod(tag+' ochre eye',(x,y-.002,z),(x,y-.006,z),r*.17,yellow,16)
    if ident=='anchae':
        # Two suspended poles and cross supports visible above the left rooms.
        a,b=xs[2]-.10,xs[4]+.03
        for yy,zz in ((-2.35,2.75),(-1.86,2.78)):
            steps=20
            for j in range(steps):
                xx=a+(b-a)*j/steps;nx=a+(b-a)*(j+1)/steps
                rod('sireong shelf rail',(xx,yy,zz+.025*math.sin(j*.7)),(nx,yy,zz+.025*math.sin((j+1)*.7)),.030,wood)
        for x in (xs[2]+.10,xs[3],xs[4]-.10):
            rod('sireong hanging support',(x,-2.38,3.35),(x,-2.37,2.73),.021,wood)
            rod('sireong cross support',(x,-2.45,2.73),(x,-1.80,2.77),.024,wood)
        # Low safety rail at the end of the raised daechong, visible in photo 6.
        a,b=xs[6]+.14,xs[7]-.13
        for z in (.73,1.02):box('photo low maru handrail',((a+b)/2,-2.23,z),(b-a,.065,.07),wood)
        for x in [a+(b-a)*i/6 for i in range(7)]:box('photo low maru upright',(x,-2.23,.875),(.048,.048,.31),wood)
        # Free-standing foot stones, not a continuous geometric staircase.
        import random
        for i in (2,3,4,5,6):
            x=(xs[i]+xs[i+1])/2
            g.rock(nm+'.photo detached stepping stone',(x,-2.88,.22),(.77 if i in (4,5) else .55,.43,.22),stone,random.Random(i+900))
        # Wide transverse beams across the open hall; their underside has a
        # slight natural camber, as in the photographed timber construction.
        for x in (xs[4],xs[5],xs[6]):
            poly=[(-1.07,3.03),(-.70,3.08),(.40,3.18),(1.6,3.12),(2.25,3.03),(2.25,3.27),(1.5,3.36),(.40,3.43),(-.65,3.31),(-1.07,3.26)]
            old=g.TRANSFORM;g.set_transform(lambda p,x=x:old((x+p[1],p[0],p[2])))
            d.extruded_profile(nm+'.photo curved daechong beam',poly,-.14,.14,beam);g.set_transform(old)
        return
    if ident=='sadangmun':
        # Photographs show a stone approach and weathered vermilion lower
        # frame, with green beams and exposed painted rafters above it.
        box('photo granite sill',(0,-.15,.255),(1.32,.54,.16),stone)
        box('photo granite entry step',(0,-.66,.115),(1.57,.49,.22),stone)
        for side in (-1,1):
            for x in [(-1.18+i*.205) for i in range(12)]:
                z=2.01+.18*(abs(x)/1.285)**8
                rod('gate painted rafter end',(x,side*.944,z),(x,side*.964,z),.055,green,16)
        return
    # Shrine: low earthen apron with six TRUE cylindrical ventilation bores.
    holes=[-2.82,-1.76,-.60,.65,1.95,2.82];lo,hi=.205,.485;zc=.338;r=.069
    bounds=[-3.36]+[(a+b)/2 for a,b in zip(holes,holes[1:])]+[3.36]
    for i,x in enumerate(holes):
        a,b=bounds[i],bounds[i+1];y0,y1=-2.153,-1.82
        # Radial sectors terminate on the rectangular cell. Both faces and
        # bore walls are modeled; nothing fills the central circle.
        angles=sorted(set([k*math.tau/48 for k in range(48)]+[math.atan2(zz-zc,xx-x)%math.tau for xx in (a,b) for zz in (lo,hi)]))
        angles.append(math.tau)
        for angle0,angle1 in zip(angles,angles[1:]):
            corners=[]
            for angle in (angle0,angle1):
                dx,dz=math.cos(angle),math.sin(angle)
                scale=min((b-x)/dx if dx>1e-9 else (a-x)/dx if dx<-1e-9 else 1e9,(hi-zc)/dz if dz>1e-9 else (lo-zc)/dz if dz<-1e-9 else 1e9)
                corners.append(((x+dx*r,zc+dz*r),(x+dx*scale,zc+dz*scale)))
            (p0,q0),(p1,q1)=corners
            for y in (y0,y1):g.face(nm+'.photo ventilated earth apron',[(p0[0],y,p0[1]),(p1[0],y,p1[1]),(q1[0],y,q1[1]),(q0[0],y,q0[1])],lime)
            g.face(nm+'.photo ventilation bore',[(p0[0],y0,p0[1]),(p1[0],y0,p1[1]),(p1[0],y1,p1[1]),(p0[0],y1,p0[1])],c['clay'])
    # Flower-end rafters, alternating fine lines, and shaped bracket members
    # occupy the two measured eave levels instead of adding another roof.
    roof=c['shrine_roof']
    for side in (-1,1):
        for j in range(40):
            x=-4.05+j*.205;y=side*2.90;z=roof(x,y)-.37
            flower('rafter rosette',x,side*3.015,z,.062)
            for k,mat in enumerate((lime,yellow,red,green)):
                yy=side*(2.70+k*.055);zz=roof(x,yy)-.285
                rod('painted rafter collar',(x,yy,zz),(x,yy+side*.017,zz+.007),.079,mat,16)
        for x in xs:
            # Two pairs of curling wing profiles, not a block capital.
            for level in (0,1):
                z=3.14+level*.24;half=.32+level*.12
                poly=[(-half,z+.12),(-half+.04,z+.20),(-half+.13,z+.17),(-.14,z+.08),(.14,z+.08),(half-.13,z+.17),(half-.04,z+.20),(half,z+.12),(half-.06,z-.02),(.18,z-.10),(.11,z-.18),(-.11,z-.18),(-.18,z-.10),(-half+.06,z-.02)]
                d.extruded_profile(nm+'.photo carved wing bracket',[(x+xx,zz) for xx,zz in poly],side*2.10-.16,side*2.10+.16,green)
                for sign in (-1,1):
                    points=[(x+sign*half*.92,z+.105),(x+sign*half*.72,z+.04),(x+sign*.17,z+.006),(x+sign*.10,z-.08)]
                    stroke('bracket ochre contour',points,side*2.10+side*.164,yellow,.006)
            flower('column lotus',x,side*2.225,3.02,.085)
            for z,mat in ((2.90,lime),(2.924,green),(2.947,yellow),(2.967,red)):
                rod('column painted collar',(x,side*2.10,z),(x,side*2.10,z+.018),.123,mat,24)
        for y,z,h in ((side*2.238,3.25,.16),(side*2.245,3.48,.13)):
            for a,b in zip(xs,xs[1:]):
                # Apply the canonical floral band horizontally on actual beam.
                box('photo canonical dancheong frieze',((a+b)/2,y,z),(b-a-.30,.012,h),c['pigment']('decoration'))
                for zz in (z-h*.44,z+h*.44):stroke('beam fine painted border',[(a+.16,zz),(b-.16,zz)],y+side*.011,lime,.0035)
    # Two-tier side framing retains natural red timber beneath the gable.
    for x in (-3.38,3.38):
        for z in (2.96,3.22):box('photo side red beam',(x,.63,z),(.15,2.94,.12),post)
