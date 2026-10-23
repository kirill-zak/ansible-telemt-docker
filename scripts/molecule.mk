# Molecule test scenario
MOLECULE_SCENARIO ?= default

# Molecule binary from the venv (see infra.mk for VENV_DIR)
MOLECULE ?= $(VENV_DIR)/bin/molecule

# The podman driver runs `podman` with `become` unless the platform is
# rootless; local hosts usually lack passwordless sudo, so default local
# runs to rootless. CI invokes `molecule test` directly (rootful engine,
# passwordless sudo) and is not affected by this Makefile default.
MOLECULE_PODMAN_ROOTLESS ?= true

# Run the full molecule test (create, converge, verify, destroy) for a scenario.
# The venv bin dir must be on PATH so molecule finds ansible-config/ansible.
# CURDIR is used so the path stays absolute when molecule spawns subprocesses.
test-molecule:
	export PATH="$(CURDIR)/$(VENV_DIR)/bin:$$PATH"; \
	export MOLECULE_PODMAN_ROOTLESS="$(MOLECULE_PODMAN_ROOTLESS)"; \
	$(MOLECULE) test --scenario-name $(MOLECULE_SCENARIO)

.PHONY: test-molecule