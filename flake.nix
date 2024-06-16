{
  description = "libxev is a high performance, cross-platform event loop.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
    zls-master.url = "github:zigtools/zls";

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs: let
    overlays = [
      # Other overlays
      (final: prev: rec {
        zigpkgs = inputs.zig.packages.${prev.system};
        zig = zigpkgs.master;
        zls = inputs.zls-master.packages.${prev.system}.default;
      })
    ];

    # Our supported systems are the same supported systems as the Zig binaries
    systems = builtins.attrNames inputs.zig.packages;
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit overlays system;};
        # zls = import ./zls.nix {inherit (pkgs) stdenv lib fetchFromGitHub zig;};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # zigpkgs.master
            zigpkgs."0.12.0"
            zls
            # zigpkgs."0.13.0"
            # (zls = pkgs.callPackage ./zls.nix {};)

            # wayland
            # wayland-scanner.dev
            # wayland-protocols
            # wayland-utils
            # egl-wayland
            # libGL
            # wlroots
            # libxkbcommon
            # pixman
            # libevdev
            # libinput
            # pkg-config
            # gtk-layer-shell
            #
            # fcft
            zlib
            stdenv
            clang-tools
            clang
            lld
          ];

          shellHook = ''
            export PATH=/home/sweet/dev/exercises/bin:$PATH
            exec zsh
          '';
        };

        # For compatibility with older versions of the `nix` binary
        devShell = self.devShells.${system}.default;
      }
    );
}
