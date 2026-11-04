{
  description = "PipeWire Soundpad";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pwsp-src = {
      url = "github:arabianq/pipewire-soundpad";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    pwsp-src,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.rustPlatform.buildRustPackage {
      pname = "pwsp";
      version = "git";
      src = pwsp-src;

      cargoLock.lockFile = "${pwsp-src}/Cargo.lock";

      nativeBuildInputs = with pkgs; [
        pkg-config
        cmake
        rustPlatform.bindgenHook # sets up libclang for the pipewire crate
        makeWrapper
      ];

      buildInputs = with pkgs; [
        pipewire
        alsa-lib
      ];

      postInstall = ''
        install -Dm644 assets/pwsp-gui.desktop $out/share/applications/pwsp.desktop
        install -Dm644 assets/icon.png $out/share/icons/hicolor/256x256/apps/pwsp.png

        # egui loads these at runtime via dlopen
        wrapProgram $out/bin/pwsp-gui \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath (with pkgs; [
          wayland
          libxkbcommon
          libGL
          vulkan-loader
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
        ])}
      '';

      meta.mainProgram = "pwsp-gui";
    };
  };
}
