{
  inputs,
  rubyEnv,
  gemset,

  buildEnv,
  coreutils-full,
  dockerTools,
  fakeNss,
  gnugrep,
  lib,
  runCommand,
  stdenv,
}:

let
  inherit (rubyEnv) envMinimal ruby;

  system = stdenv.hostPlatform.system;
  nix2container = inputs.nix2container.packages.${system}.nix2container;

  workdir = runCommand "workdir" { } ''
    mkdir -p $out/ruby
  '';

  tempdir = runCommand "tempdir" { } ''
    mkdir -p $out/tmp
  '';

  baseEnv = buildEnv {
    name = "base-env";
    paths = [
      dockerTools.usrBinEnv
      dockerTools.binSh
      dockerTools.caCertificates
      coreutils-full
      gnugrep
      (fakeNss.override {
        extraPasswdLines = [ "ruby:x:1000:1000::/var/empty:/bin/sh" ];
        extraGroupLines = [ "ruby:x:1000:ruby" ];
      })
    ];

    pathsToLink = [
      "/bin"
      "/etc"
      "/usr/bin"
    ];
  };

  baseLayer = nix2container.buildLayer {
    copyToRoot = [
      workdir
      tempdir
      baseEnv
    ];

    perms = [
      {
        path = workdir;
        mode = "0744";
        uid = 1000;
        gid = 1000;
        uname = "ruby";
        gname = "ruby";
      }
      {
        path = tempdir;
        mode = "0777";
        regex = ".*";
      }
    ];
  };
in
nix2container.buildImage {
  name = "docker.io/hssmateus/ruby-env";
  tag = "${builtins.hashFile "md5" gemset}-${ruby.meta.name}";

  config = {
    User = "ruby";
    WorkingDir = "/ruby";
    Env = [
      "MALLOC_CONF=dirty_decay_ms:1000,narenas:2,background_thread:true"
      "RUBY_YJIT_ENABLE=1"
      "BUNDLE_WITHOUT=development:test"
      "RAILS_ENV=production"
    ];
  };

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        envMinimal
        (lib.lowPrio ruby)
      ];
      pathsToLink = [ "/bin" ];
    })
  ];

  layers = [ baseLayer ];
}
