"""Keep word-web routing aligned when its source vocabulary moves level."""

from typing import Any, Mapping


def sync_word_relation_levels(
    payload: dict[str, Any],
    vocab_by_id: Mapping[str, Mapping[str, str]],
    moved_ids: set[str],
) -> list[str]:
    """Change only the level of clusters rooted in the explicitly moved IDs.

    Call on a transaction's staged payload. Authored links, examples, identity,
    ordering, and unrelated clusters remain unchanged; validation follows.
    """
    clusters = payload.get("clusters")
    if not isinstance(clusters, list):
        raise ValueError("word_relations.json must contain a clusters array")
    changed = []
    for cluster in clusters:
        if not isinstance(cluster, dict):
            raise ValueError("word_relations.json cluster must be an object")
        source_id = cluster.get("sourceVocabId")
        if not isinstance(source_id, str):
            raise ValueError("word_relations.json sourceVocabId must be a string")
        if source_id not in moved_ids:
            continue
        source = vocab_by_id[source_id]
        level = source["level"].strip().upper()
        if cluster.get("level") != level:
            cluster["level"] = level
            changed.append(cluster["id"])
    return changed
