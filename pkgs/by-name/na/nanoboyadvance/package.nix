{
  lib,
  stdenv,
  fetchFromCodeberg,
  fetchFromGitHub,
  cmake,
  python3Packages,
  SDL2,
  fmt,
  toml11,
  qt6,
  zlib,
  bzip2,
  xz,
  gtk3,
}:

let
  gladSrc = fetchFromGitHub {
    owner = "Dav1dde";
    repo = "glad";
    rev = "v2.0.5";
    hash = "sha256-Ba7nbd0DxDHfNXXu9DLfnxTQTiJIQYSES9CP5Bfq4K0=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nanoboyadvance";
  version = "1.8.3";

  src = fetchFromCodeberg {
    owner = "nba-emu";
    repo = "NanoBoyAdvance";
    rev = "v${finalAttrs.version}";
    hash = "sha256-G/STYu8vOTqoGAGfpPelYV/m0Cth4xMMD1QJ6TbqAF4=";
  };

  nativeBuildInputs = [
    cmake
    python3Packages.jinja2
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    SDL2
    fmt
    toml11
    qt6.qtsvg
    qt6.qtbase
    zlib
    bzip2
    xz
    gtk3
  ];

  preFixup = ''
    qtWrapperArgs+=(
      --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}"
      --set QT_QPA_PLATFORM xcb
      --set SDL_VIDEODRIVER x11
    )
  '';

  preConfigure = lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
    export AR="gcc-ar"
    export RANLIB="gcc-ranlib"
  '';

  cmakeFlags = [
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_GLAD" "${gladSrc}")
    (lib.cmakeBool "USE_SYSTEM_FMT" true)
    (lib.cmakeBool "USE_SYSTEM_TOML11" true)
    (lib.cmakeBool "PORTABLE_MODE" false)
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    (lib.cmakeBool "MACOS_BUILD_APP_BUNDLE" true)
    (lib.cmakeBool "MACOS_BUNDLE_QT" false)
  ];

  # Make it runnable from the terminal on Darwin
  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir "$out/bin"
    ln -s "$out/Applications/NanoBoyAdvance.app/Contents/MacOS/NanoBoyAdvance" "$out/bin/NanoBoyAdvance"
  '';

  meta = {
    description = "Cycle-accurate Nintendo Game Boy Advance emulator";
    homepage = "https://codeberg.org/nba-emu/NanoBoyAdvance";
    license = lib.licenses.gpl3Plus;
    mainProgram = "NanoBoyAdvance";
    maintainers = with lib.maintainers; [
      tomasajt
      lukas-sgx
    ];
    platforms = lib.platforms.all;
  };
})
