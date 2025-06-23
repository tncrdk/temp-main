# Based on response in sec2 Nix-v2-workflow.md
{
  description = "Main Numerical Simulation with scattered local dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # --- Local Project Inputs ---
    # Define an input for each scattered local project.
    # Provide a *relative* path as a default or a sensible fallback.
    # The user will override this in their local setup.

    # Example for 'numerical-helpers'
    library_a = {
        flake = false;
        url = "/home/thorb/Code/Sandkasse/lib1/";
    };

    # Example for 'sim_utils'
    library_b = {
        flake = false;
        url = "/home/thorb/Code/Sandkasse/lib2/";
    };
  };

  outputs = { self, nixpkgs, library_a, library_b, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Define how to build library_a
      buildLibrary_a = pkgs.stdenv.mkDerivation rec {
        pname = "lib_1";
        # version = "git"; # Or a specific commit/version
        src = library_a; # Source from the input
        # ... build logic for library_a (e.g., CMake, buildInputs)
        buildInputs = with pkgs; [ cmake gcc ];
        configurePhase = ''cmake -S ${src} -B build -DCMAKE_INSTALL_PREFIX=$out'';
        buildPhase = ''cmake --build build'';
        installPhase = ''cmake --install build'';
      };

      # Define how to build library_b
      buildLibrary_b = pkgs.stdenv.mkDerivation rec {
        pname = "lib_2";
        # version = "git";
        src = library_b;
        buildInputs = with pkgs; [ cmake gcc ];
        configurePhase = ''cmake -S ${src} -B build -DCMAKE_INSTALL_PREFIX=$out'';
        buildPhase = ''cmake --build build'';
        installPhase = ''cmake --install build'';
      };

      # Your main numerical simulation project itself
      myExperiment = pkgs.stdenv.mkDerivation rec {
        pname = "my-numerical-sim";
        version = "git";
        src = ./.; # The current directory (your main project's Git repo)

        buildInputs = with pkgs; [
          cmake
          gcc
          buildLibrary_a
          buildLibrary_b
          # library_a.defaultPackage.${system}
          # library_b.defaultPackage.${system}
          # Other common libraries from Nixpkgs
        ];
        configurePhase = ''
          cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out \
          --prefix="library_a.url;library_b.url"
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
          # buildLibrary_a
          # buildLibrary_b
          myExperiment # If you want to use the built sim executable directly
        ];
        shellHook = ''
          echo "Welcome to the Nix numerical simulation development environment!"
          echo "All your local dependencies are built and available."
        '';
      };
      packages.${system}.default = myExperiment;
    };
}
