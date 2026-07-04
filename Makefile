NPROCS = $(shell nproc)

.PHONY: regenerate-openspec-files
regenerate-openspec-files:
	./scripts/regenerate-openspec-agent-files.sh

format:
	find . -name '*.nix' -not -path './.git/*' | xargs nixpkgs-fmt
os-build:
	nixos-rebuild build --flake ".#nixos-vmware"
os-test:
	nixos-rebuild test --flake ".#nixos-vmware"
os:
	nh os switch . --hostname nixos-vmware --ask --max-jobs $(NPROCS) --no-update-lock-file
	sudo -u tung env TRUST_STORES=nss CAROOT=/var/lib/mkcert mkcert -install
home-build: regenerate-openspec-files
	nh home build . --configuration tung@nixos-vmware --max-jobs $(NPROCS) --no-update-lock-file --no-nom
home: regenerate-openspec-files
	nh home switch . --configuration tung@nixos-vmware --ask --max-jobs $(NPROCS) --no-update-lock-file
update: regenerate-openspec-files
	nix flake update
clean:
	nh clean all --ask
