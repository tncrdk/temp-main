{
  description = "Main Numerical Simulation with local dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # --- Your Local Project Inputs ---
    # Reference local-dep-A
    localDepA.url = "path:../local-dep-A"; # Relative path to local-dep-A repo
    localDepA.flake = false; # Tell Nix it's not a flake itself, but a path to a source (if it doesn't have its own flake.nix)

    # Reference local-dep-B
    localDepB.url = "path:../local-dep-B";
    localDepB.flake = false; # Same here
    # --------------------------------

    # Other external inputs like before
    # dependency-C.url = "https://github.com/some-org/dependency-C/archive/v1.2.3.tar.gz";
  };

  outputs = { self, nixpkgs, localDepA, localDepB, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # 1. Define how to build local-dep-A from its source
      buildLocalDepA = pkgs.stdenv.mkDerivation rec {
        pname = "local-dep-A";
        version = "git"; # Or derive from a Git hash if you want to be fancy
        src = localDepA; # This input now provides the source code from the local path
        buildInputs = with pkgs; [ cmake gcc ];
        configurePhase = ''
          cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out
        '';
        buildPhase = ''
          cmake --build build
        '';
        installPhase = ''
          cmake --install build
        '';
      };

      # 2. Define how to build local-dep-B (possibly depending on local-dep-A)
      buildLocalDepB = pkgs.stdenv.mkDerivation rec {
        pname = "local-dep-B";
        version = "git";
        src = localDepB;
        buildInputs = with pkgs; [ cmake gcc buildLocalDepA ]; # Depends on local-dep-A
        configurePhase = ''
          cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out -DLOCAL_DEP_A_DIR=${buildLocalDepA}
        '';
        buildPhase = ''
          cmake --build build
        '';
        installPhase = ''
          cmake --install build
        '';
      };

      # 3. Your main numerical simulation
      myNumericalSim = pkgs.stdenv.mkDerivation rec {
        pname = "my-numerical-sim";
        version = "git";
        src = ./.; # Your main project's source
        buildInputs = with pkgs; [
          cmake
          gcc
          buildLocalDepA # Depends on your local projects
          buildLocalDepB
          # Other standard libs
        ];
        configurePhase = ''
          cmake -S $src -B build -DCMAKE_INSTALL_PREFIX=$out \
            -DLOCAL_DEP_A_DIR=${buildLocalDepA} \
            -DLOCAL_DEP_B_DIR=${buildLocalDepB}
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
          buildLocalDepA
          buildLocalDepB
          myNumericalSim
        ];
        shellHook = ''
          echo "Welcome to the Nix numerical simulation development environment!"
          echo "Local dependencies are available."
        '';
      };

      packages.${system}.default = myNumericalSim;
    };
}
