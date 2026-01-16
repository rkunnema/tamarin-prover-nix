
{
  description = "Flake packaging for Tamarin Prover using callCabal2nix (modular, license copy via overrideAttrs)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    tamarin-frontend = {
      url = "path:./frontend";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, tamarin-frontend, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        system = system;
        config = { allowBroken = true; };
      };

      # packageVersion = "1.10.1"; # ignored, taken from cabal file..
      # tamarinRev = "d71fbc469f8f06310213a6f1d7b97f81c4a9f546";
      # tamarinRev = "b93c7a33fed67a713a90039fce0c4d94def23bd0"; some commit in dev
      tamarinRev = "becd485526d50424ce6ce75d12b70f6558cf8e4b"; # https://github.com/tamarin-prover/tamarin-prover/pull/805#pullrequestreview-3660147475

      rawSrc = pkgs.fetchFromGitHub {
        owner = "tamarin-prover";
        repo = "tamarin-prover";
        rev = tamarinRev;
        hash = "sha256-IDQ3jLvWq+ZY4ee7FmukOuRvdASLhhZ3lBmmFkysglQ";
      };

      frontendPkg = # we use front-end flake to build the front-end stuff
        tamarin-frontend.packages.${system}.frontend;

      # specify files from front-end we want to copy into tamarin's src
      # directory before the haskell build
      # .. if this fails checkout if theres updates to the Makefile
      frontendOverlay = pkgs.linkFarm "tamarin-frontend-overlay" [
          {
            name = "data/js/intdot-graph.es.js";
            path = "${frontendPkg}/js/intdot-graph.es.js";
          }
          {
            name = "data/js/intdot-staticgraph.es.js";
            path = "${frontendPkg}/js/intdot-staticgraph.es.js";
          }
          {
            name = "data/js/intdot-dynamicgraph.es.js";
            path = "${frontendPkg}/js/intdot-dynamicgraph.es.js";
          }
          {
            name = "data/css/intdot-style.css";
            path = "${frontendPkg}/css/intdot-style.css";
          }
        ];

      srcWithFrontend = pkgs.symlinkJoin {
        name = "tamarin-src-with-frontend";
        paths = [ rawSrc frontendOverlay ];
      };

      src = srcWithFrontend;

      hsPkgs = pkgs.haskell.packages.ghc96;

      # Define myHsPkgs first (overrides refer to vars defined later; Nix is lazy)
      myHsPkgs = hsPkgs.override {
        overrides = self: super: {
          tamarin-prover-utils = tamarinProverUtils;
          tamarin-prover-term = tamarinProverTerm;
          tamarin-prover-theory = tamarinProverTheory;
          tamarin-prover-sapic = tamarinProverSapic;
          tamarin-prover-accountability = tamarinProverAccountability;
          tamarin-prover-export = tamarinProverExport;
        };
      };

      # Helper: append a postPatch via overrideAttrs so it actually runs
      copyLicense = drv: drv.overrideAttrs (old: rec {
        postPatch = (old.postPatch or "") + ''
          # ensure LICENSE is present for install phase
          cp --remove-destination ${src}/LICENSE .
        '';
      });

      # Internal libraries, all built with myHsPkgs.callCabal2nix and with LICENSE copied
      tamarinProverUtils = copyLicense (myHsPkgs.callCabal2nix "tamarin-prover-utils" (src + "/lib/utils") {});
      tamarinProverTerm = copyLicense (myHsPkgs.callCabal2nix "tamarin-prover-term" (src + "/lib/term") {});
      tamarinProverTheory = copyLicense (myHsPkgs.callCabal2nix "tamarin-prover-theory" (src + "/lib/theory") {});
      tamarinProverSapic = copyLicense (myHsPkgs.callCabal2nix "tamarin-prover-sapic" (src + "/lib/sapic") {
        tamarin-prover-term = tamarinProverTerm;
        tamarin-prover-theory = tamarinProverTheory;
      });
      tamarinProverAccountability = copyLicense (myHsPkgs.callCabal2nix "tamarin-prover-accountability" (src + "/lib/accountability") {
        tamarin-prover-term = tamarinProverTerm;
        tamarin-prover-theory = tamarinProverTheory;
      });
      tamarinProverExport = copyLicense (myHsPkgs.callCabal2nix "tamarin-prover-export" (src + "/lib/export") {
        tamarin-prover-sapic = tamarinProverSapic;
        tamarin-prover-term = tamarinProverTerm;
        tamarin-prover-theory = tamarinProverTheory;
      });

      # Main executable, with all internal libraries passed as arguments, and LICENSE copied
      tamarinProver = copyLicense (myHsPkgs.callCabal2nix "tamarin-prover" src {
        tamarin-prover-utils = tamarinProverUtils;
        tamarin-prover-term = tamarinProverTerm;
        tamarin-prover-theory = tamarinProverTheory;
        tamarin-prover-sapic = tamarinProverSapic;
        tamarin-prover-accountability = tamarinProverAccountability;
        tamarin-prover-export = tamarinProverExport;
      });

    in {
      packages = {
        tamarin-prover                = tamarinProver;
        tamarin-prover-utils          = tamarinProverUtils;
        tamarin-prover-term           = tamarinProverTerm;
        tamarin-prover-theory         = tamarinProverTheory;
        tamarin-prover-sapic          = tamarinProverSapic;
        tamarin-prover-accountability = tamarinProverAccountability;
        tamarin-prover-export         = tamarinProverExport;
      };

      defaultPackage = tamarinProver;

      apps.default = flake-utils.lib.mkApp {
        drv = tamarinProver;
      };

      devShells.default = pkgs.mkShell {
        buildInputs = [
          myHsPkgs.cabal-install
          myHsPkgs.ghcid
        ];
      };
    }
  );
}
