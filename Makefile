NPROCS = $(shell nproc)

format:
	find . -name '*.nix' -not -path './.git/*' | xargs nixpkgs-fmt
system:
	nh os switch . --hostname nixos-vmware --ask --max-jobs $(NPROCS) --no-update-lock-file
	sudo -u tung env TRUST_STORES=nss CAROOT=/var/lib/mkcert mkcert -install
home:
	nh home switch . --configuration tung@nixos-vmware --ask --max-jobs $(NPROCS) --no-update-lock-file
update:
	nix flake update
clean:
	nh clean all --ask
