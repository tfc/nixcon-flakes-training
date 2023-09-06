{
  description = "A very basic flake";

  inputs = {
    advisory-db.flake = false;
    advisory-db.url = "github:rustsec/advisory-db";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "github:ipetkov/crane";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs";
    poetry2nix.url = "github:K900/poetry2nix/new-bootstrap-fixes";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    perSystem = { config, pkgs, system, ... }:
      let
        craneLib = inputs.crane.lib.${system};
        src = craneLib.cleanCargoSource (craneLib.path ./rust-project);
        commonCargoArgs = {
          inherit src;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
        };
        cargoArtifacts = craneLib.buildDepsOnly commonCargoArgs;
        commonCargoArgsComplete = commonCargoArgs // { inherit cargoArtifacts; };
        inherit (inputs.poetry2nix.legacyPackages.${system}) mkPoetryApplication;
      in
      {
        devShells.default = pkgs.mkShell {
          inputsFrom = with config.packages; [
            cpp-project
            python-project
            rust-project
          ];
          nativeBuildInputs = [ pkgs.clippy ];
          inherit (config.checks.pre-commit-check) shellHook;
        };

        packages = {
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

          rust-project = craneLib.buildPackage commonCargoArgsComplete;
        };

        checks = {
          inherit (config.packages)
            cpp-project
            python-project
            rust-project
            ;

          rust-doc = craneLib.cargoDoc commonCargoArgsComplete;

          rust-audit = craneLib.cargoAudit {
            inherit (inputs) advisory-db;
            inherit src;
          };

          rust-clippy = craneLib.cargoClippy (commonCargoArgsComplete // {
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # Rust
              rustfmt.enable = true;

              # Nix
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;

              # Shell
              shellcheck.enable = true;
              shfmt.enable = true;
            };
            settings.rust.cargoManifestPath = "./rust-project/Cargo.toml";
          };
        };
      };
  };
}
