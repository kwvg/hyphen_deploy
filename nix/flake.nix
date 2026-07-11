{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      disko,
      ...
    }:
    let
      unstable = import nixpkgs-unstable { system = "x86_64-linux"; };

      overlayModule = {
        nixpkgs.overlays = [
          (_final: _prev: {
            cloudflared = unstable.cloudflared;
            postgresql_18 = unstable.postgresql_18;
          })
        ];
      };

      commonModules = [
        ./modules/options.nix
        ./modules/configuration.nix
        disko.nixosModules.disko
        overlayModule
      ];

      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules ++ [ hostModule ];
        };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;

      nixosConfigurations.salmon = mkHost ./hosts/salmon.nix;
      nixosConfigurations.keplar = mkHost ./hosts/keplar.nix;
    };
}
