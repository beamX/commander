# References
# https://github.com/jurraca/elixir-templates/blob/main/release/flake.nix
# https://github.com/ydlr/mix2nix
# https://nixos.org/manual/nixpkgs/stable/#packaging-beam-applications
# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/beam.section.md
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/beam-modules/mix-release.nix

{
  description = "Commander: service to run and manage OS processes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # build for each default system of flake-utils: ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"]
    flake-utils.lib.eachDefaultSystem (system:
      let

        # Declare pkgs for the specific target system we're building for.
        pkgs = import nixpkgs { inherit system ; };

        # Declare BEAM version we want to use.
        # NOTE: using pkgs.erlang instead of pkgs.beam.interpreters.erlang_* to
        # avoid buidling erlang
        beamPackages = pkgs.beam.packagesWith pkgs.erlang_27;

        # Declare the Elixir version you want to use. If not, defaults to the latest on this channel.
        elixir = beamPackages.elixir_1_17;

        pkgVersion = "0.1.0-rev-" + pkgs.lib.strings.removeSuffix "-dirty" (self.shortRev or self.dirtyShortRev);

        # Import a development shell we'll declare in `shell.nix`.
        devShell = import ./shell.nix { inherit pkgs elixir beamPackages; };

        commander-app = let
          lib = pkgs.lib;

          # Import the Mix deps into Nix by running, mix2nix > nix/deps.nix
          mixNixDeps = import ./deps.nix { inherit lib beamPackages; };
        in beamPackages.mixRelease {
          pname = "commander";
          # Elixir app source path
          src = ../.;

          version = pkgVersion;

          MIX_RELEASE_VSN = pkgVersion;

          inherit mixNixDeps;

          # Add other inputs to the build if you need to
          # TODO Check if we to use glibcLocales
          buildInputs = [ elixir ];
        };
      in
        {
          devShells.default = devShell;
          packages.default = commander-app;
        }
    );
}
