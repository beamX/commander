{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    erlexec = buildRebar3 rec {
      name = "erlexec";
      version = "2.2.0";

      src = fetchHex {
        pkg = "erlexec";
        version = "${version}";
        sha256 = "19e4e1c170de5594da1c67a8a9a0defae0bc407e138a70b14fea031fe9e67347";
      };

      beamDeps = [];
    };
  };
in self

