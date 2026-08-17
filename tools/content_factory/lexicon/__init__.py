"""Content-factory lexicons for review-only expansion batches.

Learner-facing default names are 현우/Hyunwoo and 레나/Lena.
Do not put 민수/Minsu, 철수, 영희, or 안나/Anna back into generated copy.
`test/learner_copy_scan_test.dart` rejects those textbook names.
"""

from .partner_family_advanced import ADVANCED_PACKS
from .partner_family_packs import PACKS
from .partner_family_rest import REST_PACKS
from .partner_family_rest2 import REST2_PACKS

FAMILY_PACKS = PACKS + REST_PACKS + REST2_PACKS + ADVANCED_PACKS
