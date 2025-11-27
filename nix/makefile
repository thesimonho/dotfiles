.PHONY: update clean

FLAKE_DIR := .

update:
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then \
	  echo "Usage: make update <flake-host>"; \
	  exit 1; \
	fi
	@host=$(word 2,$(MAKECMDGOALS)); \
	echo "==> Applying host $$host using flake at $(FLAKE_DIR)"; \
	nix run "$(FLAKE_DIR)#hm" -- switch --flake "$(FLAKE_DIR)#$$host"

%:
	@:

clean:
	nix-collect-garbage -d

