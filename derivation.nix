{
  lib,
  pkgs,
  stdenv,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  ffmpeg,
  gtk3,
  lttng-ust_2_12,
  openssl,
  gnome,
  ...
}:

stdenv.mkDerivation rec {
  pname = "xdm";
  version = "8.0.29";

  system = "x86_64-linux";

  # Do not forget to update the hash on version change
  # nix-fettch-url https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk_8.0.29_amd64.deb
  src = pkgs.fetchurl {
    url = "https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk_8.0.29_amd64.deb";
    sha256 = "04cydd5i94qbnsi2535mswapng6hbwc567jhzbq8s715n0nvnn9n";
  };

  # Required for compilation
  nativeBuildInputs = [
    autoPatchelfHook # Automatically setup the loader, and do the magic
    dpkg # Extract the deb package
    makeWrapper # Create a wrapper around the binary
  ];

  # Required at runtime
  buildInputs = [
    ffmpeg
    gtk3
    lttng-ust_2_12
    openssl # Provide libssl for runtime
    gnome.adwaita-icon-theme # Provide common cursor theme from gnome
  ];

  unpackPhase = "true";

  # cp -a = copy preserving all attributes, recursively, not following symlinks
  installPhase = ''
    # Extract the deb package into a temporary directory
    dpkg-deb --extract $src $TMPDIR

    # Create the output directories
    mkdir -p $out/bin
    mkdir -p $out/share/applications/
    mkdir -p $out/share/icons/hicolor/scalable/apps/

    # Move the binary to $out/bin/
    cp -av $TMPDIR/usr/bin/xdman $out/bin/

    # Move the desktop file to $out/share/applications/
    cp -av $TMPDIR/usr/share/applications/xdm-app.desktop $out/share/applications/

    # Move the icon to $out/share/icons/
    cp -av $TMPDIR/opt/xdman/xdm-logo.svg $out/share/icons/hicolor/scalable/apps/

    # Move the extracted files to the output directory
    cp -av $TMPDIR/opt/xdman/* $out/

    # Remove unnecessary directories
    rm -rf $TMPDIR/*

    # Update the script to point to the correct path in the Nix store
    sed -i "s|/opt/xdman/xdm-app|$out/xdm-app|g" $out/bin/xdman

    # Update paths in the .desktop file
    sed -i "s|/opt/xdman/xdm-app|$out/bin/xdman|g" $out/share/applications/xdm-app.desktop
    sed -i "s|/opt/xdman/xdm-logo.svg|$out/share/icons/hicolor/scalable/apps/xdm-logo.svg|g" $out/share/applications/xdm-app.desktop

    # Set correct permissions (ownership is managed by Nix)
    find $out -type d -exec chmod 755 {} +  # Directories
    find $out -type f -exec chmod 644 {} +  # Regular files

    # Ensure binaries are executable
    chmod +x $out/bin/xdman
    chmod +x $out/xdm-app
    chmod +x $out/share/applications/xdm-app.desktop

    # Wrap the binary to ensure the GTK libraries and libssl are found
    wrapProgram $out/bin/xdman \
      --prefix LD_LIBRARY_PATH : "${gtk3.out}/lib:${openssl.out}/lib"
  '';

  meta = with lib; {
    description = "Powerful download accelerator and video downloader";
    homepage = "https://github.com/subhra74/xdm";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ];
    mainProgram = "xdman";
    platforms = platforms.all;
  };
}
