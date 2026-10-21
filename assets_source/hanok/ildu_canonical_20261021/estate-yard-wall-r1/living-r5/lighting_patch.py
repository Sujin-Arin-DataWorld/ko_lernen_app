"""Repair the floor-intersecting low fill without changing building receivers."""
import hashlib,json
import bpy

SOURCE_LIGHT='Warm estate | P16 low broad courtyard reflection.005'
FIXED_LIGHT='Living R5 | continuous courtyard fill above soil'


def apply_lighting_patch(scene, yard_names, saved_data=None):
    source=bpy.data.objects[SOURCE_LIGHT]
    assert source.type=='LIGHT' and source.data.type=='AREA'
    assert abs(source.location.z-2.545)<.001 and abs(source.data.size-8)<.001
    assert source.light_linking.receiver_collection is None, 'Unexpected prior light linking'
    existing=list(scene.objects)
    yard={bpy.data.objects[n] for n in yard_names}
    other_receivers=bpy.data.collections.new('Living R5 | retained building and garden low fill')
    for obj in existing:
        if obj not in yard:other_receivers.objects.link(obj)
    source.light_linking.receiver_collection=other_receivers
    data=saved_data if saved_data is not None else source.data.copy()
    if saved_data is None:data.name='Living R5 | horizontal courtyard fill 200W'
    fixed=bpy.data.objects.new(FIXED_LIGHT,data);scene.collection.objects.link(fixed)
    fixed.location=(source.location.x,source.location.y,6.545)
    fixed.rotation_euler=(0,0,0)
    soil_receivers=bpy.data.collections.new('Living R5 | both completed yard surfaces')
    for obj in yard:soil_receivers.objects.link(obj)
    fixed.light_linking.receiver_collection=soil_receivers
    assert set(soil_receivers.objects)==yard
    assert set(other_receivers.objects)==set(existing)-yard
    record=dict(source_light=SOURCE_LIGHT,source_transform_preserved=True,
        original_pose=dict(location=list(source.location),rotation=list(source.rotation_euler)),
        original_disk_size=source.data.size,original_disk_bottom_approx=-1.455,
        source_receivers='all original scene objects except the two yard surfaces',
        source_receiver_count=len(other_receivers.objects),
        source_receiver_names_sha256=hashlib.sha256(json.dumps(sorted(o.name for o in other_receivers.objects)).encode()).hexdigest(),
        fixed_light=FIXED_LIGHT,fixed_pose=dict(location=list(fixed.location),rotation=list(fixed.rotation_euler)),
        fixed_energy=data.energy,fixed_size=data.size,fixed_shape=data.shape,
        fixed_receivers=sorted(yard_names),yard_max_height=1.5,minimum_fill_height_above_yard=5.045,
        architecture_and_garden_materials_preserved=True,
        existing_architecture_and_garden_direct_fill_preserved=True,
        note='Indirect light may change slightly because corrected yard reflectance is physically coupled.')
    return fixed,record
