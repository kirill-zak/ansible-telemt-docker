# Ansible venv location
VENV_DIR ?= .ansible

# Python interpreter used to create the venv
PYTHON ?= python3

# File with Python dependencies
REQUIREMENTS ?= requirements.txt

# Create the virtual environment and install dependencies
create-venv:
	$(PYTHON) -m venv $(VENV_DIR)
	$(VENV_DIR)/bin/pip install --upgrade pip
	$(VENV_DIR)/bin/pip install -r $(REQUIREMENTS)

# Update installed packages to the latest versions within the venv
update-venv:
	$(VENV_DIR)/bin/pip install --upgrade pip
	$(VENV_DIR)/bin/pip install --upgrade -r $(REQUIREMENTS)

.PHONY: create-venv update-venv