"""Test configuration and fixtures."""

import pytest
from pathlib import Path


@pytest.fixture
def project_root():
    """Return the project root directory."""
    return Path(__file__).parent.parent


@pytest.fixture
def kubernetes_manifests_path(project_root):
    """Return the path to kubernetes manifests."""
    return project_root / "kubernetes" / "base"


@pytest.fixture
def ansible_playbooks_path(project_root):
    """Return the path to ansible playbooks."""
    return project_root / "ansible" / "playbooks"
