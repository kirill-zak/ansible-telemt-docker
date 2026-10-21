# Molecule test scenario
MOLECULE_SCENARIO ?= default

# Molecule binary from the venv (see infra.mk for VENV_DIR)
MOLECULE ?= $(VENV_DIR)/bin/molecule

# Run the full molecule test (create, converge, verify, destroy) for a scenario.
# The venv bin dir must be on PATH so molecule finds ansible-config/ansible.
# CURDIR is used so the path stays absolute when molecule spawns subprocesses.
test-molecule:
	export PATH="$(CURDIR)/$(VENV_DIR)/bin:$$PATH"; \
	$(MOLECULE) test --scenario-name $(MOLECULE_SCENARIO)

.PHONY: test-molecule