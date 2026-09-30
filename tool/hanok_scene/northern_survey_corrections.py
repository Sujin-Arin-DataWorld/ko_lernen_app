"""Corrections established by directly rereading the drawing schedules.

This pass deliberately records unresolved source discrepancies. A numeric
geometry check is not a substitute for reconciliation with a survey drawing.
"""
import bpy, json
import numpy as np
from mathutils import Vector, Matrix
from northern_courtyard_photo_repair import g, d, tag_flush, OUT
from refine_northern_materials import apply_craft_surfaces


def apply(scene,c):
    if c.get('surveyReauditVersion'):return
    rec=next(r for r in c['buildings'] if r['id']=='arae')
    origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z')
    wood=bpy.data.materials['North arae wood'];lime=bpy.data.materials['North lime plaster'];paper=bpy.data.materials['North warm hanji']
    for ob in list(scene.objects):
        if ob.name.startswith(('North.arae.front plaster','North.arae.front WD')):
            bpy.data.objects.remove(ob,do_unlink=True)
    g.BATCHES.clear();g.set_transform(lambda p:origin+rot@Vector(p))
    axes=np.r_[-rec['bodyWidth']/2,-rec['bodyWidth']/2+np.cumsum(rec['bays'])]
    specs=[('WD02',1.980,1.340,4),('WD06',1.110,1.210,2),('WD04',1.220,1.340,2)]
    for i,(tag,width,height,count) in enumerate(specs):
        a,b=axes[i:i+2];cx=(a+b)/2;left,right=cx-width/2,cx+width/2;bottom=.66;top=bottom+height
        for l,r,low,high in [(a+.10,left,.55,2.46),(right,b-.10,.55,2.46),(left,right,.55,bottom),(left,right,top,2.46)]:
            g.box('North.arae.survey front infill',((l+r)/2,-.82,(low+high)/2),(r-l,.09,high-low),lime)
        d.lattice('North.arae.survey '+tag,left,right,-.88,bottom,top,wood,paper,leaves=count)
    tag_flush('arae');g.set_transform(lambda p:p)
    rec['frontOpeningSchedule']=[{'tag':tag,'width':w,'height':h,'leaves':leaves} for tag,w,h,leaves in specs]
    rec['sourceDimensionConflict']={'printedOverall':7.500,'printedBays':[2.430,2.370,2.670],
        'sumPrintedBays':7.470,'candidateBays':rec['bays'],
        'status':'Unresolved 30 mm inconsistency in sheets 026 and 027. Candidate equal +10 mm adjustment is provisional, not a survey value.'}
    c['openings']=[r for r in c['openings'] if not(r['building']=='arae' and r['tag'].startswith('front WD'))]
    c['openings'] += [{'building':'arae','tag':tag,'center':[(axes[i]+axes[i+1])/2,-.88,.66+h/2],
                      'width':w,'height':h,'leaves':count,'authority':'2007 sheets 027 and 028, printed schedule and opening locations'}
                     for i,(tag,w,h,count) in enumerate(specs)]
    c['illustratedTimber']+=apply_craft_surfaces(scene)
    c['surveyReauditVersion']=1
    c['fullSurveyAccuracyClaimed']=False
    c['surveyAuthorityFile']='survey-authority.json'
    c['surveyReauditOutstanding']=[
        'Arae: 7500 overall versus 7470 sum of printed bays; vertical section unavailable in current drawing set.',
        'Anchae: right end room WD5 / WW5..8 locations must be reconciled with plan and side elevation; no sealed room declared complete.',
        'Sadang: current elevation height is line tracing, not a printed section height. Do not mix 1996 vertical dimensions with 2007 plan without reconciliation.',
        'Site 002: legend numbers 6/7 conflict with individual Jung/Angotgan plans. Existing accepted Jung is retained, no duplicate.',
    ]
    bpy.context.view_layer.update()
