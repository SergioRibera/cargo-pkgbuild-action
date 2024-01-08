{
  description = "Generate PKGBUILD from cargo";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    pre-commit-hooks,
    ...
  }: let
    name = "cargo-pkgbuild-action";
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
          config = {};
        };
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            editorconfig-checker.enable = true;
            shfmt.enable = true;
            shellcheck.enable = true;
            yamllint.enable = true;
          };
          settings = {
            yamllint = {
              configPath = "./.github/linters/.yaml-lint.yml";
            };
          };
        };

        devShell = pkgs.mkShell {
          name = "devShell";
          inherit (pre-commit-check) shellHook;
          buildInputs = with pre-commit-hooks.packages.${system}; [
            alejandra
            editorconfig-checker
          ];
          packages = with pkgs; [
            docker
            nodePackages.dockerfile-language-server-nodejs
            nodePackages.bash-language-server
            nodePackages.yaml-language-server
          ];
        };
      in {
        devShells = {
          default = devShell;
        };

        checks = {
          formatting = pre-commit-check;
        };
      };
    };
}
