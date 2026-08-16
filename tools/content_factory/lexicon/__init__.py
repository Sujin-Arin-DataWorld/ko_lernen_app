"""Content-factory lexicons for review-only expansion batches."""

from .partner_family_advanced import ADVANCED_PACKS
from .partner_family_packs import PACKS
from .partner_family_rest import REST_PACKS
from .partner_family_rest2 import REST2_PACKS

FAMILY_PACKS = PACKS + REST_PACKS + REST2_PACKS + ADVANCED_PACKS
