"""Tests for project structure and configuration."""

import pytest
from pathlib import Path


def test_project_structure(project_root):
    """Test that required directories exist."""
    required_dirs = [
        "src/app",
        "ansible/playbooks",
        "ansible/roles",
        "kubernetes/base",
        "kubernetes/gcp",
        "scripts",
        "docs",
        "tests",
    ]
    
    for dir_path in required_dirs:
        assert (project_root / dir_path).exists(), f"Directory {dir_path} should exist"


def test_kubernetes_manifests_exist(kubernetes_manifests_path):
    """Test that Kubernetes manifests exist."""
    required_manifests = [
        "backend.yaml",
        "frontend.yaml",
        "db.yaml",
        "kind-config.yaml",
    ]
    
    for manifest in required_manifests:
        manifest_path = kubernetes_manifests_path / manifest
        assert manifest_path.exists(), f"Manifest {manifest} should exist"


def test_ansible_playbooks_exist(ansible_playbooks_path):
    """Test that Ansible playbooks exist."""
    deploy_playbook = ansible_playbooks_path / "deploy.yml"
    assert deploy_playbook.exists(), "deploy.yml playbook should exist"


def test_scripts_are_executable(project_root):
    """Test that scripts have executable permissions."""
    scripts_dir = project_root / "scripts"
    scripts = list(scripts_dir.glob("*.sh")) + list(scripts_dir.glob("*.fish"))
    
    for script in scripts:
        # Check if file has execute permission for owner
        assert script.stat().st_mode & 0o100, f"Script {script.name} should be executable"


def test_pyproject_toml_has_uv_config(project_root):
    """Test that pyproject.toml has uv configuration."""
    pyproject_path = project_root / "pyproject.toml"
    assert pyproject_path.exists(), "pyproject.toml should exist"
    
    content = pyproject_path.read_text()
    assert "[tool.uv]" in content, "pyproject.toml should have [tool.uv] section"
    assert "ansible" in content.lower(), "pyproject.toml should include ansible dependency"
