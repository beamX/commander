{
  pkgs,
  elixir,
  beamPackages
}: let
  # define packages to install
  basePackages = with pkgs; [
    git
    elixir
    rebar3
    mix2nix
    # iex complains about locale being set to latin1
    glibcLocales
  ];

  # Add basePackages + optional system packages per system
  buildInputs =
    with pkgs;
    basePackages
    ++ lib.optionals stdenv.isLinux [inotify-tools]
    ++ lib.optionals stdenv.isDarwin
      (with darwin.apple_sdk.frameworks; [CoreFoundation CoreServices]);

in
  pkgs.mkShell {
    inherit buildInputs;
  }
