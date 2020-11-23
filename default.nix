{ system ? builtins.currentSystem
  # Additional sources.json overrides.
, sources ? { }
  # Additional nixpkgs.config overrides.
, config ? { }
  # Additional nixpkgs.overlays.
, overlays ? [ ] }:

let

  finalSources = import ./nix/sources.nix { inherit pkgs; } // sources;

  haskellNix = import finalSources."haskell.nix" {
    sourcesOverride = { hackage = finalSources."hackage.nix"; };
  };

  pkgs = import finalSources.nixpkgs {
    inherit system;

    config = haskellNix.config // config;
    overlays = haskellNix.overlays ++ overlays;
  };

  cabalProject = pkgs.haskell-nix.cabalProject {
    compiler-nix-name = "ghc8102";

    src = pkgs.haskell-nix.cleanSourceHaskell {
      name = "text-manipulate";
      src = ./.;
    };
  };

in {
  inherit (cabalProject.text-manipulate.components) library exes tests benchmarks;
  inherit (cabalProject.text-manipulate) checks;

  shell = cabalProject.shellFor {
    exactDeps = true;

    packages = ps: with ps; [ text-manipulate ];

    tools = {
      cabal = "3.2.0.0";
      ormolu = "0.1.3.0";
    };

    buildInputs = [ pkgs.nixfmt (import finalSources.niv { }).niv ];

    shellHook = ''
      export PATH=./scripts:$PATH
    '';
  };
}
