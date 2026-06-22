import os
import pytest

# Repo root is four levels up from this test file's worktree location.
REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..")
)
FORMS_DIR_PATH = os.path.join(REPO_ROOT, "forms", "espen mda")


@pytest.fixture
def forms_dir():
    assert os.path.isdir(FORMS_DIR_PATH), f"missing {FORMS_DIR_PATH}"
    return FORMS_DIR_PATH
