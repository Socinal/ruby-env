{
  inputs,
  rubyEnv,

  coreutils-full,
  dockerTools,
  fakeNss,
  gnugrep,
  runCommand,
  stdenv
}:

let
  workdir = runCommand "workdir" { } ''
    mkdir -p $out/ruby
  '';

  prodEnv = (rubyEnv.override { groups = [ "default" ]; }).env;

  inherit (rubyEnv) ruby gemset;

  system = stdenv.hostPlatform.system;
in
inputs.nix2container.packages.${system}.nix2container.buildImage {
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
    prodEnv
    workdir
    dockerTools.usrBinEnv
    dockerTools.binSh
    coreutils-full
    gnugrep
    (fakeNss.override {
      extraPasswdLines = [ "ruby:x:1000:1000::/var/empty:/bin/sh" ];
      extraGroupLines = [ "ruby:x:1000:ruby" ];
    })
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
  ];
}
