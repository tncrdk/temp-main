# Based on response in sec2 Nix-v2-workflow.md
{
  description = "Main Numerical Simulation with scattered local dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    # --- Local Project Inputs ---
    # Define an input for each scattered local project.
    # Provide a *relative* path as a default or a sensible fallback.
    # The user will override this in their local setup.

    # Example for 'numerical-helpers'
    library_a = {
        url = "git+file:///home/thorb/Code/Sandkasse/lib1";
    };

    # Example for 'sim_utils'
    library_b = {
        url = "git+file:///home/thorb/Code/Sandkasse/lib2";
    };
  };

  outputs = { self, nixpkgs, flake-utils, library_a, library_b, ... }@inputs:

    flake-utils.lib.eachDefaultSystem (system:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Your main numerical simulation project itself
      myExperiment = pkgs.stdenv.mkDerivation rec {
        name = "myExperiment";
        version = "git";
        src = self; # The current directory (your main project's Git repo)

        buildInputs = with pkgs; [
          cmake
          gcc
          # buildLibrary_a
          # buildLibrary_b
          # library_a.packages.${system}
          # library_b.defaultPackage.${system}
          library_b.packages.${system}.default
          library_a.packages.${system}.default
          # Other common libraries from Nixpkgs
        ];
        configurePhase = ''
          cmake -S ${src} -B $out/build -DCMAKE_PREFIX_PATH="library_a.url;library_b.url"
        '';
        buildPhase = ''
          cmake --build $out/build
        '';
        installPhase = ''
          mkdir $out/install && cmake --install $out/build --prefix=$out/install \
          && echo "Out: $out" && echo "lib_b: ${library_b.packages.${system}.default}" && \
          ln -s ${library_b.packages.${system}.default} $out/lib_b_install && \
          ln -s ${library_b} $out/lib_b
        '';
      };

    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git cmake gcc gdb valgrind
        ];
        buildInputs = [
          # buildLibrary_a
          # buildLibrary_b
          myExperiment # If you want to use the built sim executable directly
          library_a.defaultPackage.${system}.default
          library_b.defaultPackage.${system}.default
        ];
        shellHook = ''
          echo "Welcome to the Nix numerical simulation development environment!"
          echo "All your local dependencies are built and available."
        '';
      };
      packages.default = myExperiment;
    });
}
