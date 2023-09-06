{
  description = "A very basic flake";

  inputs = {
    poetry2nix.url = "github:K900/poetry2nix/new-bootstrap-fixes";
  };

  outputs = { self, nixpkgs, poetry2nix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      inherit (poetry2nix.legacyPackages.${system}) mkPoetryApplication;
    in {
      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = with self.packages.${system}; [
          cpp-project
          python-project
        ];

        buildInputs = with pkgs; [
          rustc
          cargo
        ];
      };

      packages.${system} = {
        cpp-project = pkgs.stdenv.mkDerivation {
          name = "cpp-project";

          src = ./cpp-project;

          nativeBuildInputs = with pkgs; [
            cmake
          ];

          buildInputs = with pkgs; [
            boost
            poco
          ];
        };

        python-project = mkPoetryApplication {
          projectDir = ./python-project;
        };

        rust-project = pkgs.rustPlatform.buildRustPackage {
          name = "rust-project";
          src = ./rust-project;
          cargoLock = {
            lockFile = ./rust-project/Cargo.lock;
          };
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
        };
      };

      checks.${system} = {
        inherit (self.packages.${system})
          cpp-project
          python-project
          rust-project
          ;
      };
    };
}
