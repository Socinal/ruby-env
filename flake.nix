{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    ruby-nix = {
      url = "github:hss-mateus/ruby-nix/git-src";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bundix = {
      url = "github:hss-mateus/bundix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rubyVersionFile = {
      url = "https://httpbingo.org/status/200";
      flake = false;
    };

    gemset = {
      url = "https://httpbingo.org/status/200";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    rec {
      lib.buildEnv =
        pkgs: args: pkgs.lib.makeOverridable (pkgs.callPackage ./.) ({ inherit inputs; } // args);

      packages =
        let
          systems = nixpkgs.lib.systems.flakeExposed;
          eachSystem = nixpkgs.lib.genAttrs systems;
        in
        eachSystem (
          system:
          lib.buildEnv nixpkgs.legacyPackages.${system} {
            rubyVersionFile = inputs.rubyVersionFile;
            gemset = inputs.gemset;
          }
        );
    };
}
