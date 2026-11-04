{
  description = "PipeWire Soundpad";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.rustPlatform.buildRustPackage {
      pname = "pwsp";
      version = "git";
      src = self;

      cargoLock = {
        lockFile = "${self}/Cargo.lock";
        outputHashes = {
          "rodio-0.22.2" = "sha256-VCrm0KMyBtr7L3e4fFFZjOAZnT2q9MmUIDHEpPg6Fl0=";
        };
      };

      doCheck = false;

      nativeBuildInputs = with pkgs; [
        pkg-config
        cmake
        rustPlatform.bindgenHook # sets up libclang for the pipewire crate
        makeWrapper
      ];

      buildInputs = with pkgs; [
        pipewire
        openssl
        alsa-lib
        dbus
      ];

      postInstall = ''
        install -Dm644 pwsp-gui/assets/icon.png \
          $out/share/icons/hicolor/256x256/apps/pwsp.png

        wrapProgram $out/bin/pwsp-gui \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath (with pkgs; [
          wayland
          libxkbcommon
          libGL
          vulkan-loader
          libx11
          libxcursor
          libxrandr
          libxi
          dbus
        ])}

        # launcher: daemon lives exactly as long as the GUI
        cat > $out/bin/pwsp-launch <<'EOF'
        #!/bin/sh
        ${placeholder "out"}/bin/pwsp-daemon &
        daemon=$!
        trap 'kill $daemon 2>/dev/null' EXIT
        trap 'exit' INT TERM HUP
        ${placeholder "out"}/bin/pwsp-gui "$@"
        EOF
        chmod +x $out/bin/pwsp-launch

        install -Dm644 pwsp-gui/assets/pwsp-gui.desktop $out/share/applications/pwsp.desktop
        substituteInPlace $out/share/applications/pwsp.desktop \
          --replace-fail "Exec=/usr/bin/pwsp-gui" "Exec=$out/bin/pwsp-launch"
      '';

      meta.mainProgram = "pwsp-gui";
    };
  };
}
