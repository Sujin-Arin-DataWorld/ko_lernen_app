"""Building-specific classification; never infer wood from the 'Selected timber' wrapper."""
def category(info, object_name=''):
    name=info['name'].lower().replace('selected timber v2','source')
    images=' '.join((x.get('image') or '') for x in info['images']).lower()
    text=name+' '+images
    if any(x in name+' '+object_name.lower() for x in ['original plaque','현판','inscription','calligraphy','recess shadow','ash soot']):return 'preserve'
    if any(x in text for x in ['metal','iron','쇠','forged']):return 'metal'
    if any(x in text for x in ['hs painted','dancheong','painted-green','painted-red','vermilion','blue green','disk paint','fresh | red','fresh | green','fresh | blue','finial pigment','original pigment']):return 'paint'
    if any(x in text for x in ['straw','weave','woven','mat binding']):return 'fibre'
    if 'candles' in text:return 'wax'
    if any(x in name for x in ['endgrain','end grain','wood_end']):
        # Many timber materials contain an endgrain image for cut faces as well.
        if not any(x in name for x in ['boards','frame tone','post axis','beam axis','floor axis','joinery axis','wood_frame','wood_floor','wood_joinery']):return 'endgrain'
    if any(x in text for x in ['stone','granite','masonry','fieldstone','mineral','석재']):return 'stone'
    if any(x in text for x in ['plaster','limewash','lime-wash','limewash','회벽']):return 'plaster'
    if any(x in text for x in ['paper','hanji','창호지']):return 'paper'
    if any(x in text for x in ['tile','ceramic','charcoal clay','illustrated clay','fresh | clay']):return 'tile'
    if any(x in text for x in ['earth','ochre infill','earthen skirt','eave bedding','roof bedding','mortar','soil','clay infill']):return 'earth'
    if any(x in text for x in ['pine','wood','timber','beam','post','lattice','joinery','board','gate floor pigment']):
        return 'lattice' if any(x in name+' '+object_name.lower() for x in ['joinery','lattice','창살']) else 'wood'
    # The source has anonymized main-gate plaque/image materials. Preserve their
    # complete colour mapping, and list this exception explicitly in receipts.
    if name.startswith('hs gate '):return 'preserve'
    return 'unclassified'
