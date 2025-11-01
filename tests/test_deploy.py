"""Tests for deployment module."""

import sys
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / "scripts"))
from deploy import run_playbook, main


def test_run_playbook_success():
    """Test successful playbook execution."""
    with patch('subprocess.run') as mock_run:
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="Playbook executed successfully",
            stderr=""
        )
        
        result = run_playbook("test-playbook.yml", "localhost")
        
        assert result == 0
        mock_run.assert_called_once()


def test_run_playbook_with_extra_vars():
    """Test playbook execution with extra variables."""
    with patch('subprocess.run') as mock_run:
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="Success",
            stderr=""
        )
        
        extra_vars = {"namespace": "test", "replicas": "3"}
        result = run_playbook(
            "test-playbook.yml",
            "localhost",
            extra_vars=extra_vars
        )
        
        assert result == 0
        call_args = mock_run.call_args[0][0]
        assert "-e" in call_args
        assert "namespace=test" in call_args


def test_run_playbook_failure():
    """Test playbook execution failure."""
    with patch('subprocess.run') as mock_run:
        from subprocess import CalledProcessError
        mock_run.side_effect = CalledProcessError(
            returncode=1,
            cmd=["ansible-playbook"],
            stderr="Playbook failed"
        )
        
        result = run_playbook("test-playbook.yml", "localhost")
        
        assert result == 1


def test_main_playbook_not_found():
    """Test main function when playbook doesn't exist."""
    with patch('pathlib.Path.exists', return_value=False):
        result = main()
        assert result == 1
