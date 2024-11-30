{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    elixir_make = buildMix rec {
      name = "elixir_make";
      version = "0.9.0";

      src = fetchHex {
        pkg = "elixir_make";
        version = "${version}";
        sha256 = "db23d4fd8b757462ad02f8aa73431a426fe6671c80b200d9710caf3d1dd0ffdb";
      };

      beamDeps = [];
    };

    muontrap = buildMix rec {
      name = "muontrap";
      version = "1.5.0";

      src = fetchHex {
        pkg = "muontrap";
        version = "${version}";
        sha256 = "daf605e877f60b5be9215e3420d7971fc468677b29921e40915b15fd928273d4";
      };

      beamDeps = [ elixir_make ];
    };
  };
in self

