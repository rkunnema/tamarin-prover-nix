{
  description = "Tamarin prover frontend build (Node)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      # system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.frontend =
        pkgs.buildNpmPackage {
          pname = "tamarin-frontend";
          version = "develop";

          # Fetch the tamarin-prover repository
          src = pkgs.fetchFromGitHub {
            owner = "tamarin-prover";
            repo = "tamarin-prover";
            rev = "develop";
            # Replace this with the real hash after first build
            hash = "sha256-r512RwFT7KEmVca33+T2i42Fy4MCJoC/oNjG4LpVp0k";
          };

          # The frontend lives in a subdirectory
          sourceRoot = "source/frontend";

          # Use the lockfile
          npmDepsHash = "sha256-zROdcW0QCEvCERm6wJp+jzXbA0Hsud/U1YzKnTHxlCc=";

          # Runs: npm run build
          npmBuildScript = "build";

          # Install the build artifacts
          installPhase = ''
            runHook preInstall

            mkdir -p $out/js $out/css

            cp dist/intdot-graph.es.js        $out/js/
            cp dist/intdot-staticgraph.es.js $out/js/
            cp dist/intdot-dynamicgraph.es.js $out/js/
            cp dist/intdot-style.css         $out/css/

            runHook postInstall
          '';
        };

      # Convenience default
      defaultPackage.${system} = self.packages.${system}.frontend;
    };
}
