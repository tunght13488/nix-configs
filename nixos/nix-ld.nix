# This is just an example, you should generate yours with nixos-generate-config and put it in here.
{ pkgs
, ...
}:
{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    SDL
    SDL2
    SDL2_image
    SDL2_mixer
    SDL2_ttf
    SDL_image
    SDL_mixer
    SDL_ttf
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    bzip2
    cairo
    cups
    curlWithGnuTls
    dbus
    dbus-glib
    desktop-file-utils
    e2fsprogs
    expat
    flac
    fontconfig
    freeglut
    freetype
    fribidi
    fuse
    fuse3
    gdk-pixbuf
    glew_1_10 # glew110
    glib
    gmp
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-ugly
    gst_all_1.gstreamer
    gtk2
    harfbuzz
    icu
    keyutils.lib
    libGL
    libGLU
    libappindicator-gtk2
    libcaca
    libcanberra
    libcap
    libclang.lib
    libdbusmenu
    libdrm
    libgcrypt
    libgpg-error
    libidn
    libjack2
    libjpeg
    libmikmod
    libogg
    libpng12
    libpulseaudio
    librsvg
    libsamplerate
    libsecret
    libthai
    libtheora
    libtiff
    libudev0-shim
    libusb1
    libuuid
    libvdpau
    libvorbis
    libvpx
    libxcrypt-legacy
    libxkbcommon
    libxml2
    mesa
    nspr
    nss
    openssl
    p11-kit
    pango
    pixman
    python3
    speex
    stdenv.cc.cc
    tbb
    udev
    vulkan-loader
    wayland
    libice # xorg.libICE
    libsm # xorg.libSM
    libx11 # xorg.libX11
    libxscrnsaver # xorg.libXScrnSaver
    libxcomposite # xorg.libXcomposite
    libxcursor # xorg.libXcursor
    libxdamage # xorg.libXdamage
    libxext # xorg.libXext
    libxfixes # xorg.libXfixes
    libxft # xorg.libXft
    libxi # xorg.libXi
    libxinerama # xorg.libXinerama
    libxmu # xorg.libXmu
    libxrandr # xorg.libXrandr
    libxrender # xorg.libXrender
    libxt # xorg.libXt
    libxtst # xorg.libXtst
    libxxf86vm # xorg.libXxf86vm
    libpciaccess # xorg.libpciaccess
    libxcb # xorg.libxcb
    libxcb-util # xorg.xcbutil
    libxcb-image # xorg.xcbutilimage
    libxcb-keysyms # xorg.xcbutilkeysyms
    libxcb-render-util # xorg.xcbutilrenderutil
    libxcb-wm # xorg.xcbutilwm
    xkeyboard-config # xorg.xkeyboardconfig
    xz
    zlib
  ];
}
