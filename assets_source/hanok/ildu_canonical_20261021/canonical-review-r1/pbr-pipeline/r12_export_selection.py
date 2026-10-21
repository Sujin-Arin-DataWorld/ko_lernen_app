"""Pure, fail-closed R12 owner/curriculum selection and deterministic chunking.

The file-binding adapter performs read-only I/O. No function imports Blender,
changes geometry, or grants runtime/learning approval.
"""
import hashlib
import json
import re
from pathlib import Path


class SelectionError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise SelectionError(message)


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def unique(rows, key, label):
    result = {}
    for row in rows:
        value = row[key]
        require(isinstance(value, str) and value, f"Invalid {label}")
        require(value not in result, f"Duplicate {label}: {value}")
        result[value] = row
    return result


def chunk_selection(groups, objects, limit):
    require(type(limit) is int and limit >= 0, "Chunk face limit must be a nonnegative integer")
    result, oversized, seen = {}, [], set()
    for key, names in sorted(groups.items()):
        require(re.fullmatch(r"[A-Za-z0-9_.-]+", key) is not None, "Unsafe output group ID")
        require(len(names) == len(set(names)), "Duplicate member before chunking")
        require(not seen.intersection(names), "Member appears in multiple chunk groups")
        seen.update(names)
        batch, faces, index = [], 0, 0
        for name in sorted(names):
            require(name in objects, "Selected member missing from geometry contract: " + name)
            count = objects[name]['domainCounts']['FACE']
            require(type(count) is int and count >= 0, "Invalid raw face count: " + name)
            if limit and batch and faces + count > limit:
                result[f'{key}__atlas{index:03d}'] = batch
                index += 1
                batch, faces = [], 0
            batch.append(name)
            faces += count
            if limit and count > limit:
                oversized.append({'sourceObject': name, 'rawFaces': count, 'limit': limit,
                                  'policy': 'atomic native mesh retained without splitting'})
        if batch:
            result[f'{key}__atlas{index:03d}' if limit else key] = batch
    require(sum(map(len, result.values())) == sum(map(len, groups.values())), "Chunking lost members")
    return result, oversized


def build_selection(mapping, contract, requested_owners, *, policy=None, catalog=None,
                    source_process_map=None, chunk_raw_faces=0, exclude_shared_context=False):
    """Validate all policy stages, then select owners; never silently intersect bad IDs."""
    owners = list(requested_owners)
    require(owners and all(isinstance(x, str) and x and x == x.strip() for x in owners), "Empty or malformed requested owner")
    require(len(owners) == len(set(owners)), "Duplicate requested owner")
    groups = unique(mapping['groups'], 'nativeOwner', 'owner group')
    require(set(owners) <= set(groups), "Unknown requested owner")
    native = unique(mapping['members'], 'sourceObject', 'native source object')
    by_id = unique(mapping['members'], 'memberId', 'native member ID')
    require(len(native) == len(by_id) == mapping['expectedMeshCount'], "Owner-map mesh count mismatch")
    require(set(native) == set(contract['objects']), "Owner-map/geometry-contract coverage mismatch")
    flattened = []
    for owner, group in groups.items():
        names = group['sourceObjects']
        require(len(names) == len(set(names)), "Duplicate source in owner group: " + owner)
        require(set(names) <= set(native), "Owner group has unknown source member")
        require(all(native[n]['nativeOwner'] == owner for n in names), "Source owner membership mismatch")
        if 'memberIds' in group:
            require(group['memberIds'] == [native[n]['memberId'] for n in names], "Owner group member ID/name mismatch")
        flattened.extend(names)
    require(len(flattened) == len(set(flattened)) == len(native) and set(flattened) == set(native), "Owner groups omit or duplicate native members")
    requested = {o: sorted(groups[o]['sourceObjects']) for o in sorted(owners)}
    names = {n for values in requested.values() for n in values}
    selection = requested
    stage_metadata, all_no_new, shared, excluded = [], [], set(), set()
    if policy is None:
        require(not exclude_shared_context, "Shared-context exclusion requires a curriculum policy")
    else:
        require(catalog is not None and source_process_map is not None, "Curriculum policy requires bound catalog and source process map")
        for key in ('sourceProcessMappingModified', 'nativeGeometryModified', 'eligibilityOrRewardIdsModified'):
            require(policy.get(key) is False, "Policy claims forbidden source/eligibility mutation")
        process = unique(catalog['processes'], 'id', 'catalog process ID')
        stages = unique(policy['stages'], 'processId', 'policy stage ID')
        require(set(stages) == set(process), "Policy stages missing or unknown relative to catalog")
        units = catalog['courseUnitOrder']
        require(len(units) == len(set(units)) and policy['courseUnitOrder'] == units, "Course-unit eligibility/order mismatch")
        rows = unique(policy['members'], 'memberId', 'policy member ID')
        source_rows = unique(source_process_map['members'], 'memberId', 'source process member ID')
        require(set(rows) == set(by_id) == set(source_rows), "Policy/source member coverage mismatch")
        policy_names = unique(policy['members'], 'sourceObject', 'policy source object')
        require(set(policy_names) == set(native), "Policy source object coverage mismatch")
        rules = unique(policy['policyRules'], 'ruleId', 'display rule ID')
        for mid, row in rows.items():
            original, source = by_id[mid], source_rows[mid]
            for key in ('sourceObject', 'nativeOwner', 'catalogBuildingId'):
                require(row[key] == original[key] == source[key], "Policy source owner/identity mismatch: " + mid)
            require(row['sourceProcessId'] == source['processId'], "Policy changed source process assignment")
            require(row['sourceAssignmentStatus'] == source['processAssignmentStatus'], "Policy changed source assignment status")
            pid = row['displayProcessId']
            if source['processAssignmentStatus'] == 'shared_context':
                shared.add(row['sourceObject'])
                require(pid is None, "Shared context has a curriculum process")
            else:
                require(pid in process, "Building member lacks a known display process")
                require(process[pid]['buildingId'] == row['catalogBuildingId'], "Cross-building display assignment")
            if pid != row['sourceProcessId']:
                rule = rules.get(row['policyRuleId'])
                require(rule is not None and rule['displayProcessId'] == pid, "Changed display assignment lacks matching rule")
                require(rule['historicalInstallationOrderClaim'] is False, "Display policy claims historical proof")
        accumulated, delta_names = {}, []
        selected_buildings = {native[n]['catalogBuildingId'] for n in names if n not in shared}
        for stage in sorted(stages.values(), key=lambda s: (s['buildingId'], s['sequence'])):
            pid, building = stage['processId'], stage['buildingId']
            record = process[pid]
            require(stage['curriculumContract'] == record, "Stage curriculum contract changed: " + pid)
            require((building, stage['sequence']) == (record['buildingId'], record['sequence']), "Stage building/sequence mismatch")
            require(stage['createsCredit'] is False and stage['autoCompleteOnNoNewGeometry'] is False,
                    "Stage creates credit or silently completes learning")
            require(stage['earnedRuntimeStageAllowed'] is False, "Policy cannot grant runtime approval")
            current = accumulated.setdefault(building, set())
            selections = {}
            for field in ('delta', 'cumulativePrior', 'cumulative'):
                value = stage[field]
                mids, object_names = value['memberIds'], value['sourceObjects']
                require(len(mids) == len(set(mids)) == len(object_names) == len(set(object_names)) == value['memberCount'], "Duplicate/count mismatch in stage " + field)
                require(set(mids) <= set(rows), "Unknown stage member ID")
                require([rows[mid]['sourceObject'] for mid in mids] == object_names, "Stage member ID/source name mismatch")
                require(all(rows[mid]['catalogBuildingId'] == building for mid in mids), "Stage contains foreign building member")
                require(not set(object_names).intersection(shared), "Stage includes unsupported shared context")
                selections[field] = set(object_names)
            delta = selections['delta']
            require(stage['noNewGeometry'] is (not delta), "noNewGeometry contradicts stage delta")
            require(selections['cumulativePrior'] == current, "Incorrect prior cumulative selection")
            require(all(policy_names[n]['displayProcessId'] == pid for n in delta), "Stage delta disagrees with member display assignment")
            require(not current.intersection(delta), "Duplicate stage introduction")
            current.update(delta)
            require(selections['cumulative'] == current, "Incorrect cumulative stage selection")
            delta_names.extend(delta)
            if stage['noNewGeometry']:
                all_no_new.append(pid)
            if building in selected_buildings:
                stage_metadata.append({k: stage[k] for k in ('processId', 'buildingId', 'sequence', 'classification', 'noNewGeometry', 'nativeCoverageStatus', 'displayLimitation')} |
                                      {'selectedDeltaSourceObjects': sorted(delta & names),
                                       'selectedPriorSourceObjects': sorted(selections['cumulativePrior'] & names),
                                       'selectedCumulativeSourceObjects': sorted(current & names),
                                       'createsCredit': False, 'autoCompleteOnNoNewGeometry': False,
                                       'earnedRuntimeStageAllowed': False})
        require(len(delta_names) == len(set(delta_names)) and set(delta_names) == set(native) - shared,
                "Policy stages omit or duplicate building members")
        excluded = names & shared
        require(not excluded or exclude_shared_context,
                f"Curriculum export does not support shared context ({len(excluded)} selected members); explicitly use --exclude-shared-context for building-only export")
        names -= excluded
        require(names, "No supported building members remain after shared-context exclusion")
        selection = {}
        for stage in stage_metadata:
            batch = stage['selectedDeltaSourceObjects']
            if batch:
                selection[stage['processId']] = batch
    atlas, oversized = chunk_selection(selection, contract['objects'], chunk_raw_faces)
    require({n for batch in atlas.values() for n in batch} == names, "Atlas selection coverage mismatch")
    return {'requestedSourceOwners': requested,
            'sourceOwners': {o: [n for n in values if n in names] for o, values in requested.items() if any(n in names for n in values)},
            'atlasGroups': atlas, 'unchunkedGroups': selection,
            'stageMetadata': stage_metadata, 'allNoNewGeometryProcessIds': all_no_new,
            'selectedMemberCount': len(names), 'globalSharedContextMemberCount': len(shared),
            'excludedSharedContextSourceObjects': sorted(excluded),
            'sharedContextExportSupported': policy is None,
            'oversizedAtomicMembers': oversized, 'runtimePromoted': False,
            'curriculumDisplayAssignmentsAreHistoricalProof': False}


def _read(path):
    path = Path(path).resolve(strict=True)
    blob = path.read_bytes()
    return path, blob, json.loads(blob)


def _bound(binding, path=None):
    actual = Path(path if path is not None else binding['path']).resolve(strict=True)
    declared = Path(binding['path']).resolve(strict=True)
    require(actual == declared, "Binding path differs from actual input: " + str(actual))
    path, blob, data = _read(actual)
    require(digest(blob) == binding['sha256'], "Binding SHA mismatch: " + str(path))
    require(len(blob) == binding['bytes'], "Binding byte length mismatch: " + str(path))
    return path, blob, data


def load_selection(owner_map_path, contract_path, requested_owners, *, policy_path=None,
                   catalog_path=None, chunk_raw_faces=0, exclude_shared_context=False):
    """Bind actual paths and bytes before invoking the pure selector."""
    owner_path, owner_bytes, mapping = _read(owner_map_path)
    contract_actual, contract_bytes, contract = _read(contract_path)
    bindings = [b for b in mapping['sourceBindings'] if Path(b['path']).resolve() == contract_actual]
    require(len(bindings) == 1, "Owner map lacks exact contract path binding")
    _bound(bindings[0], contract_actual)
    policy, catalog, source_map, policy_sha = None, None, None, None
    if policy_path:
        _, policy_bytes, policy = _read(policy_path)
        policy_sha = digest(policy_bytes)
        inputs = policy['inputBindings']
        require(set(inputs) == {'r12-owner-map.json', 'r12-process-member-map.json', 'r12-static-export-plan.json'}, "Unexpected or missing curriculum policy input bindings")
        _bound(inputs['r12-owner-map.json'], owner_path)
        _, _, source_map = _bound(inputs['r12-process-member-map.json'])
        _bound(inputs['r12-static-export-plan.json'])
        _, _, catalog = _bound(policy['originalCatalog'], catalog_path)
        require(source_map['ownerMap'] == inputs['r12-owner-map.json'], "Source process map owner binding disagrees")
        require(source_map['originalCatalog'] == policy['originalCatalog'], "Source process map catalog binding disagrees")
        require(source_map['sourceNative'] == mapping['sourceNative'], "Source process map native binding disagrees")
        catalog_bindings = [b for b in mapping['sourceBindings'] if Path(b['path']).resolve() == Path(policy['originalCatalog']['path']).resolve()]
        require(len(catalog_bindings) == 1 and catalog_bindings[0] == policy['originalCatalog'], "Owner map and policy catalog bindings disagree")
    else:
        require(catalog_path is None, "--catalog requires --curriculum-policy")
    result = build_selection(mapping, contract, requested_owners, policy=policy, catalog=catalog,
                             source_process_map=source_map, chunk_raw_faces=chunk_raw_faces,
                             exclude_shared_context=exclude_shared_context)
    result.update(sourceOwnerMapSha256=digest(owner_bytes), contractSha256=digest(contract_bytes),
                  curriculumPolicySha256=policy_sha)
    return mapping, contract, result


def bake_owner_map(mapping, selection):
    """Retain the validator's nativeOwner/sourceObjects sidecar contract."""
    return {'sourceNative': mapping['sourceNative'],
            'sourceOwnerMapSha256': selection['sourceOwnerMapSha256'],
            'curriculumPolicySha256': selection['curriculumPolicySha256'],
            'groups': [{'nativeOwner': key, 'sourceObjects': names}
                       for key, names in selection['atlasGroups'].items()]}
