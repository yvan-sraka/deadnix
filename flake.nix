{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    mozillapkgs.url = "github:mozilla/nixpkgs-mozilla";
    mozillapkgs.flake = false;
  };

  outputs = { self, nixpkgs, utils, naersk, mozillapkgs }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages."${system}";
      mozilla = pkgs.callPackage (mozillapkgs + "/package-set.nix") {};
      rust = (mozilla.rustChannelOf {
        channel = "stable";
        date = "2021-12-02";  # "2021-11-01";
        sha256 = "0rqgx90k9lhfwaf63ccnm5qskzahmr4q18i18y6kdx48y26w3xz8";
      }).rust;

      # Override the version used in naersk
      naersk-lib = naersk.lib."${system}".override {
        cargo = rust;
        rustc = rust;
      };
    in rec {
      # `nix build`
      packages.deadnix = naersk-lib.buildPackage {
        pname = "deadnix";
        src = ./.;
      };
      defaultPackage = packages.deadnix;

      checks = packages;

      # `nix run`
      apps.deadnix = utils.lib.mkApp {
        drv = packages.deadnix;
      };
      defaultApp = apps.deadnix;

      # `nix develop`
      devShell = pkgs.mkShell {
        nativeBuildInputs = with defaultPackage;
          nativeBuildInputs ++ buildInputs;
      };
    }) // {
      overlay = final: prev: {
        deadnix = self.packages.${prev.system};
      };

      nixosModule = import ./nixos-module.nix { inherit self; };
    };
}