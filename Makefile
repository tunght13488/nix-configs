NPROCS = $(shell nproc)

format:
	find . -name '*.nix' -not -path './.git/*' | xargs nixpkgs-fmt
os-build:
	nixos-rebuild build --flake ".#nixos-vmware"
os-test:
	nixos-rebuild test --flake ".#nixos-vmware"
os:
	nh os switch . --hostname nixos-vmware --ask --max-jobs $(NPROCS) --no-update-lock-file
	sudo -u tung env TRUST_STORES=nss CAROOT=/var/lib/mkcert mkcert -install
home-build:
	nh home build . --configuration tung@nixos-vmware --max-jobs $(NPROCS) --no-update-lock-file --no-nom
home:
	nh home switch . --configuration tung@nixos-vmware --ask --max-jobs $(NPROCS) --no-update-lock-file
update:
	nix flake update
clean:
	nh clean all --ask
