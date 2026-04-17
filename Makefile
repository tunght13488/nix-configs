format:
	find . -name '*.nix' -not -path './.git/*' | xargs nixpkgs-fmt
home:
	home-manager switch --flake ".#tung@nixos-vmware"
system:
	sudo nixos-rebuild switch --flake ".#nixos-vmware"
	sudo -u tung env TRUST_STORES=nss CAROOT=/var/lib/mkcert mkcert -install
update:
	nix flake update
clean:
	nix-collect-garbage
