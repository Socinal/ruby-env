{
  inputs,
  paths ? [ ],
  gemset ? null,
  rubyVersionFile,

  lib,
  linkFarm,
  pkgs,
  runCommand,
  stdenv,
  writeText,
}:

let
  system = stdenv.hostPlatform.system;

  ruby =
    (inputs.nixpkgs-ruby.lib.packageFromRubyVersionFile {
      inherit system;
      file = rubyVersionFile;
    }).override
      { jemallocSupport = true; };

  defaultEntries = [
    {
      name = "Gemfile";
      path = writeText "empty" "";
    }
    {
      name = ".ruby-version";
      path = rubyVersionFile;
    }
  ];

  extraEntries = map (path: {
    inherit path;
    name = baseNameOf path;
  }) paths;

  gemfileDir = linkFarm "gemfile-dir" (defaultEntries ++ extraEntries);

  bundix = inputs.bundix.packages.${system}.default;

  resolvedGemset =
    if gemset == null then
      runCommand "gemset" { } ''
        cd ${gemfileDir}
        ${bundix}/bin/bundix --gemset=$out
      ''
    else
      gemset;

  gemConfig = pkgs.defaultGemConfig // {
    ruby-oci8 = _: {
      buildFlags = [
        "--with-instant-client-lib=${pkgs.oracle-instantclient.lib}/lib"
        "--with-instant-client-include=${pkgs.oracle-instantclient.dev}/include"
      ];
    };
  };

  rubyEnv = lib.makeOverridable (inputs.ruby-nix.lib pkgs) {
    inherit gemConfig ruby;
    gemset = import resolvedGemset;
  };

  image = pkgs.callPackage ./image.nix {
    inherit inputs;
    rubyEnv = rubyEnv.override { groups = [ "default" ]; };
    gemset = resolvedGemset;
  };
in
rubyEnv
// {
  inherit image;
  gemset = resolvedGemset;
}
