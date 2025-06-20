{
  description = "Main Numerical Simulation with scattered local dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # --- Local Project Inputs ---
    # Define an input for each scattered local project.
    # Provide a *relative* path as a default or a sensible fallback.
    # The user will override this in their local setup.

    # Example for 'numerical-helpers'
    library_a.url = "path:../lib1/"; # Placeholder
    library_a.flake = false;

    # Example for 'sim_utils'
    library_b.url = "path:../lib2/"; # Placeholder
    library_b.flake = false;
  };

  outputs = { self, nixpkgs, library_a, library_b, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Define how to build library_a
      buildLibrary_a = pkgs.stdenv.mkDerivation rec {
        pname = "numerical-helpers";
        version = "git"; # Or a specific commit/version
        src = library_a; # Source from the input
        # ... build logic for library_a (e.g., CMake, buildInputs)
        buildInputs = with pkgs; [ cmake gcc ];
        configurePhase = ''cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out'';
        buildPhase = ''cmake --build build'';
        installPhase = ''cmake --install build'';
      };

      # Define how to build library_b
      buildSimUtils = pkgs.stdenv.mkDerivation rec {
        pname = "sim-utils";
        version = "git";
        src = library_b;
        buildInputs = with pkgs; [ cmake gcc buildLibrary_a ];
        configurePhase = ''cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out -DNUMERICAL_HELPERS_DIR=${buildLibrary_a}'';
        buildPhase = ''cmake --build build'';
        installPhase = ''cmake --install build'';
      };

      # Define how to build physicsEngine (might depend on others)
      buildPhysicsEngine = pkgs.stdenv.mkDerivation rec {
        pname = "physics-engine";
        version = "git";
        src = physicsEngine;
        buildInputs = with pkgs; [ cmake gcc buildLibrary_a buildSimUtils ];
        configurePhase = ''cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out \
          -DNUMERICAL_HELPERS_DIR=${buildLibrary_a} \
          -DSIM_UTILS_DIR=${buildSimUtils}
        '';
        buildPhase = ''cmake --build build'';
        installPhase = ''cmake --install build'';
      };


      # Your main numerical simulation project itself
      myNumericalSim = pkgs.stdenv.mkDerivation rec {
        pname = "my-numerical-sim";
        version = "git";
        src = ./.; # The current directory (your main project's Git repo)

        buildInputs = with pkgs; [
          cmake
          gcc
          buildLibrary_a
          buildSimUtils
          buildPhysicsEngine
          # Other common libraries from Nixpkgs
          boost
          eigen
        ];
        configurePhase = ''
          cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out \
            -DNUMERICAL_HELPERS_DIR=${buildLibrary_a} \
            -DSIM_UTILS_DIR=${buildSimUtils} \
            -DPHYSICS_ENGINE_DIR=${buildPhysicsEngine}
        '';
        buildPhase = ''
          cmake --build build
        '';
        installPhase = ''
          cmake --install build
        '';
      };

    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git cmake gcc gdb valgrind
        ];
        nativeBuildInputs = [
          buildLibrary_a
          buildSimUtils
          buildPhysicsEngine
          myNumericalSim # If you want to use the built sim executable directly
        ];
        shellHook = ''
          echo "Welcome to the Nix numerical simulation development environment!"
          echo "All your local dependencies are built and available."
        '';
      };
      packages.${system}.default = myNumericalSim;
    };
}
