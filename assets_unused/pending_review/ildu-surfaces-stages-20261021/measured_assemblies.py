"""Separate 2007 drawing assemblies. Millimetre dimensions are converted to metres.

080–083: 중문. 089–093: 안사랑채 협문. Printed dimensions are distinguished
from section-profile tracing in DRAWING_EVIDENCE.md. No old Blender geometry.
"""
import math
from mathutils import Vector


def tag(ob, sheet, measurement):
    ob['drawingSheet']=sheet
    ob['drawingMeasurement']=measurement
    return ob


def foundation(g,c):
    ax=c['axis']/2
    if g.KEY=='left':
        # 080/081: low perimeter, no invented approach stair flight.
        g.box('foundation.earthen court',(0,0,.015),(2.80,2.37,.03),g.M['earth'],.008)
        # 081/083 show the local earth crown reaching the underside of the sill.
        vs=[(-1.04,-.88,.03),(1.04,-.88,.03),(-1.04,-.13,.228),(1.04,-.13,.228),(-1.04,.13,.228),(1.04,.13,.228),(-1.04,.88,.03),(1.04,.88,.03)]
        g.mesh('foundation.local earth crown',vs,[(0,1,3,2),(2,3,5,4),(4,5,7,6),(0,2,4,6),(1,7,5,3)],g.M['earth'],.004)
        for sy in (-1,1):
            for j in range(6):
                g.fieldstone('foundation.perimeter fieldstone',(-1.4+(j+.5)*2.8/6,sy*1.04,.065),(2.8/6-.008,.29,.08),110+j+10*(sy+1))
        for sx in (-1,1):
            for j in range(3):
                g.fieldstone('foundation.shinbangseok',(sx*ax,(j-1)*.51,.115),(.30,.52,.17),200+j+10*(sx+1))
            tag(g.horizontal_timber('timber.shinbangmok',(sx*ax,-.825,.2775),(sx*ax,.825,.2775),.215,.155,g.M['wood']),'080/081','215x155; length traced')
    else:
        # 092 longitudinal section. Five different rises and treads, not a uniform stair.
        rises=[.20,.15,.15,.13,.12];treads=[.33,.36,.38,.18,.60]
        y=-2.45;top=0
        for i,(rise,run) in enumerate(zip(rises,treads)):
            top+=rise
            n=[4,4,5,3,4][i]
            for j in range(n):
                ob=g.fieldstone('foundation.step %d block %d'%(i+1,j+1),(-1.05+(j+.5)*2.1/n,y+run/2,top-rise/2),(2.1/n-.008,run-.006,rise),400+i*10+j)
                tag(ob,'089/092','rise %.0f / tread %.0f'%(rise*1000,run*1000))
            # Closed earth backing under exposed walking stones.
            if top>rise:g.box('foundation.step backing',(0,y+run/2,(top-rise)/2),(2.02,run,top-rise),g.M['earth'],.004)
            y+=run
        g.box('foundation.upper ground',(0,.08,.375),(2.18,1.36,.75),g.M['earth'],.012)
        for sx in (-1,1):
            g.fieldstone('foundation.foot bedding',(sx*ax,0,.77),(.34,1.55,.04),600+(sx+1))
            tag(g.stone('foundation.shinbangseok',(sx*ax,0,.81),(.30,1.52,.04)),'092','300x40x1520')
            tag(g.horizontal_timber('timber.shinbangmok',(sx*ax,-.7,.935),(sx*ax,.7,.935),.210,.210,g.M['wood']),'089/092','210x210x1400')


def rafter_z(c,y):
    # Shallow bent lower roof profile traced from section, distinct from the clay silhouette.
    t=min(1,abs(y)/c['rafterEnd'])
    return c['rafterTop']-c['rafterFall']*t

def rafter_bottom(g,c,y):
    height=.120-.020*(abs(y)/c['rafterEnd'])**5 if g.KEY=='left' else .100
    return rafter_z(c,y)-height


def pitched_rafter(g,c,x,index):
    end=c['rafterEnd'];ys=[-end+i*2*end/48 for i in range(49)]
    roundwood=g.KEY=='left';n=32 if roundwood else 4;verts=[]
    for y in ys:
        top=rafter_z(c,y)
        if roundwood:
            # 082 explicitly gives the 120 body / 100 tip diameters.
            radius=.060-.010*(abs(y)/end)**5
            verts.extend((x+radius*math.cos(2*math.pi*k/n),y,top-radius+radius*math.sin(2*math.pi*k/n)) for k in range(n))
        else:
            verts.extend((x+dx,y,top+dz) for dx,dz in [(-.04,0),(.04,0),(.04,-.10),(-.04,-.10)])
    faces=[tuple(range(n-1,-1,-1)),tuple(range(len(verts)-n,len(verts)))]
    for i in range(len(ys)-1):
        faces.extend((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j) for j in range(n))
    ob=g.mesh('roof.'+('round' if roundwood else 'square')+' rafter %02d'%index,verts,faces,g.M['wood'],.0008,roundwood)
    ob.data.polygons[0].use_smooth=False;ob.data.polygons[1].use_smooth=False
    g.longitudinal_grain(ob,(0,1,0))
    tag(ob,'081/082' if roundwood else '092/093','diameter 120; tip100' if roundwood else '80x100')


def timber(g,c):
    wood=g.M['wood'];ax=c['axis']/2;left=g.KEY=='left'
    for sx in (-1,1):
        tag(g.beam('timber.main post',(sx*ax,0,c['floor']),(sx*ax,0,c['head']),c['post'],c['post'],wood,.003),'080/082' if left else '089/092','155x155' if left else '180x180')
        if left:
            # The octagonal props lean OUT along Y; the old outside diagonal sticks were wrong.
            side_top=rafter_bottom(g,c,.925)-.12
            for sy in (-1,1):
                ob=g.cylinder('timber.octagonal inclined prop',(sx*ax,sy*.650,c['floor']),(sx*ax,sy*.925,side_top),.105/2,wood,8)
                tag(ob,'080/081/082','octagonal105; base +/-650; upper +/-925')
            for sy in (-1,1):
                ob=g.beam('timber.side X brace',(sx*(ax-.020),sy*.61,c['floor']+.02),(sx*(ax-.020),-sy*.88,side_top-.025),.060,.060,wood,.002)
                tag(ob,'080/081/083','60x60 side X bracing')
            tag(g.horizontal_timber('timber.side cross bearing',(sx*ax,-1.11,side_top-.065),(sx*ax,1.11,side_top-.065),.115,.130,wood),'082','115x130')
        else:
            side_top=rafter_z(c,.6)-.1-.1
            for sy in (-1,1):
                tag(g.beam('timber.fore aft support',(sx*ax,sy*.6,c['floor']),(sx*ax,sy*.6,side_top),.100,.100,wood),'089/093','100x100; +/-600')
            tag(g.horizontal_timber('timber.side cross bearing',(sx*ax,-.735,side_top-.05),(sx*ax,.735,side_top-.05),.090,.100,wood),'092','90x100; continuous side bearing')
            # Broad fore-aft boards shown on the outside of the main posts.
            z0=c['floor']
            for sy in (-1,1):
                outline=[(sy*.001,z0),(sy*.20,z0),(sy*.20,2.43),(sy*.001,2.54)]
                xx=sx*(ax+.100)
                ob=g.profile_solid('timber.wingjipan plank',outline,xx-.02,xx+.02,wood)
                g.longitudinal_grain(ob,(0,0,1))
                tag(ob,'092','THK40; overall W400 with narrow board joint')
    half=c['boardingHalf']
    if left:
        tag(g.horizontal_timber('timber.central dori',(-half,0,2.760),(half,0,2.760),.150,.150,wood),'081/082','150x150; lower datum2685')
        tag(g.horizontal_timber('timber.ridge bearing',(-half,0,2.895),(half,0,2.895),.120,.120,wood),'081','120x120 above central dori')
        for yy in (-.925,.925):
            zz=rafter_bottom(g,c,yy)-.060
            tag(g.horizontal_timber('timber.side dori',(-half,yy,zz),(half,yy,zz),.120,.120,wood),'081/082','120x120; +/-925')
        xs=[-1.33,-1.04,-.742857,-.445714,-.148571,.148571,.445714,.742857,1.04,1.33]
    else:
        tag(g.horizontal_timber('timber.central dori',(-half,0,2.910),(half,0,2.910),.180,.230,wood),'092/093','180x230; bottom2795')
        for yy in (-.6,.6):
            zz=rafter_z(c,yy)-.1-.05
            tag(g.horizontal_timber('timber.side dori',(-half,yy,zz),(half,yy,zz),.080,.100,wood),'092/093','80x100; +/-600')
        xs=[-1.14,-.73,-.365,0,.365,.73,1.14]
    for i,x in enumerate(xs):pitched_rafter(g,c,x,i)
    # Timber boarding follows the lower roof pitch. Planks are independent, joints visible.
    n=math.ceil(2*c['rafterEnd']/.165);bw=2*c['rafterEnd']/n
    for j in range(n):
        yy=-c['rafterEnd']+(j+.5)*bw
        a=yy-bw/2+.0007;b=yy+bw/2-.0007
        ys=[a,0,b] if a<0<b else [a,b]
        grid=[[(x,y,rafter_z(c,y)+.025) for x in (-half,0,half)] for y in ys]
        ob=g.shell('roof.pitched boarding %02d'%j,grid,wood,.025,.0006);g.longitudinal_grain(ob,(1,0,0))
        tag(ob,'081/092','separate boarding; 25mm interpreted where sheet calls sanja')
    doors(g,c)


def doors(g,c):
    wood=g.M['wood'];left=g.KEY=='left';ax=c['axis']/2
    base=c['doorBase'];top=base+c['doorH'];width=c['door'];bw=width/c['boards']
    jambW,jambD=(.090,.105) if left else (.085,.120)
    for sx in (-1,1):
        tag(g.beam('timber.side door jamb',(sx*(width/2+jambW/2),0,base),(sx*(width/2+jambW/2),0,top+.015),jambW,jambD,wood),'080' if left else '089','90x105' if left else '85x120')
    tag(g.horizontal_timber('timber.upper door jamb',(-ax,0,top+.065),(ax,0,top+.065),.075 if left else .085,.130 if left else .120,wood),'081' if left else '092','75x130' if left else '85x120')
    g.horizontal_timber('timber.sill',(-ax,0,base-.06),(ax,0,base-.06),.075 if left else .085,.10 if left else .130,wood)
    for j in range(c['boards']):
        x0=-width/2+j*bw+.00065;x1=x0+bw-.0013
        if j==c['boards']//2:x0+=.002
        # 083 lower edge: curved worn central dip, not a straight new door slab.
        def bottom(x):return base+(.085*(min(1,abs(x)/.43)**2) if left else 0)
        xs=[x0+(x1-x0)*k/6 for k in range(7)]
        outline=[(x,bottom(x)) for x in xs]+[(x1,top),(x0,top)]
        vs=[(x,y,z) for y in (-c['doorT']/2,c['doorT']/2) for x,z in outline];n=len(outline)
        fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        ob=g.mesh('door.board %02d'%(j+1),vs,fs,wood,.00065)
        # Rebase at board centre so each board gets a different physical timber grain.
        centre=Vector(((x0+x1)/2,0,(base+top)/2))
        for v in ob.data.vertices:v.co-=centre
        ob.location=centre;tag(ob,'080' if left else '089','THK25' if left else 'THK30')
    rows=[.14,.37,.64,.90] if left else [.08,.48,.92]
    railH,railD=(.060,.045) if left else (.065,.035)
    for sx in (-1,1):
        for f in rows:
            z=base+c['doorH']*f
            ob=g.horizontal_timber('door.rear rail',(sx*width/4-width/4,c['doorT']/2+railD/2,z),(sx*width/4+width/4,c['doorT']/2+railD/2,z),railD,railH,wood,.0015)
            tag(ob,'080' if left else '089','60x45x895' if left else '65x35x570')
        for z in (base-.015,top+.015):
            g.cylinder('door.wood pivot',(sx*(width/2-.04),0,z-.035),(sx*(width/2-.04),0,z+.035),.019,wood)
        tag(g.box('door.lower pivot housing',(sx*(width/2-.125),.045,base+.055),(.250,.080,.060),wood,.002),'080' if left else '089','L250')
    upperL=2.20 if left else 1.25
    tag(g.horizontal_timber('door.upper dunte',(-upperL/2,.055,top+.020),(upperL/2,.055,top+.020),.045,.110 if left else .065,wood,.001),'080' if left else '089','45x110x2200' if left else '45x65x1250')
    boltL=.280 if left else .740;boltH=.060;boltD=.030 if left else .060
    z=base+c['doorH']*.43
    tag(g.horizontal_timber('door.sliding wooden bolt',(-boltL/2,.11,z),(boltL/2,.11,z),boltD,boltH,wood,.002),'080' if left else '089','60x30x280' if left else '80x60x740; 092 lists smaller section')
    for sx in (-1,1):
        tag(g.box('door.bolt keeper',(sx*(.15 if left else .21),.105,z),(.06,.05 if left else .08,.530 if left else .330),wood,.002),'080' if left else '089','60x50x530' if left else '60x80x330')
    if not left:
        # Reuse the independently modelled hardware, keeping exact 24 nail count.
        g.hardware(c)
        for sx in (-1,1):
            for zz in (base+.075,top-.075):
                g.box('iron.corner strap',(sx*(width/2-.105),-c['doorT']/2-.003,zz),(.20,.006,.020),g.M['iron'],.003)
    else:
        # 080 specifies 32 nails; 083 does not depict the older 1992 front ring handles.
        for j in range(8):
            for f in rows:g.nail('iron.board nail',-width/2+(j+.5)*bw,-c['doorT']/2-.002,base+c['doorH']*f,.007)


def roof_underlay(g,c):
    W=c['w'];D=c['d'];B=c['barge'];half=c['boardingHalf'];wood=g.M['wood']
    # Compact fill closes against the PITCHED boarding. It never fills the exposed underside.
    ys=[-c['rafterEnd']+.05+i*(2*c['rafterEnd']-.10)/48 for i in range(49)]
    grid=[[(x,y,g.roof_surface(c,x,y)-.025) for x in [-B+.025+i*(2*B-.05)/36 for i in range(37)]] for y in ys]
    ob=g.shell('roof.internal compacted fill',grid,g.M['earth'],.05,.001)
    for v in ob.data.vertices[len(ob.data.vertices)//2:]:v.co.z=rafter_z(c,v.co.y)+.024
    ob['buriedLayer']=True
    # Thin wood closure follows both the tile slope and the shallow lower structure.
    # It replaces the single beige full-width sheet. Cross ribs are separate load-bearing pieces.
    for sx in (-1,1):
        xx=sx*(W/2-.018)
        for sy in (-1,1):
            yy=[g.roof_corner_y(c,xx,sy*i*D/2/32) for i in range(33)]
            top=[(y,g.roof_surface(c,xx,y)-.027) for y in yy]
            bottom=[(y,rafter_z(c,y)-.12) for y in yy]
            mid=[(a[0],a[1]*.5+b[1]*.5) for a,b in zip(top,bottom)]
            for j,(upper,lower) in enumerate(((top,mid),(mid,bottom))):
                points=[(y,z-(.0007 if j else 0)) for y,z in upper]+[(y,z+(.0007 if not j else 0)) for y,z in reversed(lower)]
                ob=g.profile_solid('roof.gable plank %s %s %s'%(sx,sy,j),points,xx-.0125,xx+.0125,wood)
                g.longitudinal_grain(ob,(0,sy,-c['rafterFall']/c['rafterEnd']))
                tag(ob,'082' if g.KEY=='left' else '093','THK25' if g.KEY=='left' else 'gable section traced; board split interpreted')
        # Wing boarding under side tile returns, no bare earth faces.
        for j in range(18):
            y=-D/2+(j+.5)*D/18
            xs=[sx*(B-.02+(W/2-B)*i/6) for i in range(7)]
            grid=[[(x,g.roof_corner_y(c,x,yy),g.roof_surface(c,x,g.roof_corner_y(c,x,yy))-.023) for x in xs] for yy in (y-D/36+.001,y+D/36-.001)]
            ob=g.shell('roof.side return boarding',grid,wood,.025,.0006);g.longitudinal_grain(ob,(1,0,0))
        for sy in (-1,0,1):
            y=sy*c['support'];x0=sx*(half-.09);x1=sx*(W/2-.03)
            z0=rafter_z(c,y)-.07;z1=g.roof_surface(c,x1,y)-.07
            g.beam('roof.side return bearing',(x0,y,z0),(x1,y,z1),.085,.095,wood,.002)
    for sy in (-1,1):
        y=sy*c['rafterEnd'];top=rafter_z(c,y)+.025
        # 081: 90x55 / 40x60; 092: 55x90 / 50x60.
        w,h=(.090,.055) if g.KEY=='left' else (.055,.090)
        ob=g.horizontal_timber('roof.pyeonggodae',(-half,y,top-h/2),(half,y,top-h/2),w,h,wood,.002)
        tag(ob,'081' if g.KEY=='left' else '092','90x55' if g.KEY=='left' else '55x90')
        ob=g.horizontal_timber('roof.yeonham',(-half,y+.025*sy,top+.025),(half,y+.025*sy,top+.025),.040 if g.KEY=='left' else .050,.060,wood,.002)
        tag(ob,'081' if g.KEY=='left' else '092','40x60' if g.KEY=='left' else '50x60')
        # Narrow clay bedding stops at the exposed ceramic mouth.
        grid=[[(x,yy,g.roof_surface(c,x,yy)+.003) for x in [-B+i*2*B/30 for i in range(31)]] for yy in (sy*(D/2-.13),sy*(D/2-.012))]
        g.shell('roof.thin tile bedding',grid,g.M['earth'],.038,0)
