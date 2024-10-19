{
  stdenv,
  lib,
  fetchFromGitLab,
  runtimeShell,
  buildPackages,
  gettext,
  pkg-config,
  python3,
  avahi,
  libgphoto2,
  libieee1284,
  libjpeg,
  libpng,
  libtiff,
  libusb1,
  libv4l,
  net-snmp,
  curl,
  systemd,
  libxml2,
  poppler,
  gawk,
  sane-drivers,
  nixosTests,
  autoconf,
  automake,
  libtool,
  autoconf-archive,

# List of { src name backend } attibute sets - see installFirmware below:
  extraFirmware ? [],

# For backwards compatibility with older setups; use extraFirmware instead:
  gt68xxFirmware ? null, snapscanFirmware ? null,

# Not included by default, scan snap drivers require fetching of unfree binaries.
  scanSnapDriversUnfree ? false, scanSnapDriversPackage ? sane-drivers.epjitsu,
}:

stdenv.mkDerivation rec {
  pname = "sane-backends";
  version = "1.3.1";

  src = fetchFromGitLab {
    owner = "sane-project";
    repo = "backends";
    rev = "refs/tags/${version}";
    hash = "sha256-4mwPGeRsyzngDxBQ8/48mK+VR9LYV6082xr8lTrUZrk=";
  };

  postPatch = ''
    # Do not create lock dir in install phase
    sed -i '/^install-lockpath:/!b;n;c\       # pass' backend/Makefile.am
  '';

  preConfigure = ''
    # create version files, so that autotools macros can use them:
    # https://gitlab.com/sane-project/backends/-/issues/440
    printf "%s\n" "$version" > .tarball-version
    printf "%s\n" "$version" > .version

    autoreconf -fiv

    # Fixes for cross compilation
    # https://github.com/NixOS/nixpkgs/issues/308283

    # related to the compile-sane-desc-for-build
    substituteInPlace tools/Makefile.in \
      --replace 'cc -I' '$(CC_FOR_BUILD) -I'

    # sane-desc will be used in postInstall so compile it for build
    # https://github.com/void-linux/void-packages/blob/master/srcpkgs/sane/patches/sane-desc-cross.patch
    patch -p1 -i ${./sane-desc-cross.patch}
  '';

  outputs = [ "out" "doc" "man" ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    autoconf
    autoconf-archive
    automake
    gettext
    libtool
    pkg-config
    python3
  ];

  buildInputs = [
    avahi
    libgphoto2
    libjpeg
    libpng
    libtiff
    libusb1
    curl
    libxml2
    poppler
    gawk
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    libieee1284
    libv4l
    net-snmp
    systemd
  ];

  enableParallelBuilding = true;

  configureFlags = [ "--with-lockdir=/var/lock/sane" ]
    ++ lib.optional (avahi != null)   "--with-avahi"
    ++ lib.optional (libusb1 != null) "--with-usb";

  # autoconf check for HAVE_MMAP is never set on cross compilation.
  # The pieusb backend fails compilation if HAVE_MMAP is not set.
  buildFlags = lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
    "CFLAGS=-DHAVE_MMAP=${if stdenv.hostPlatform.isLinux then "1" else "0"}"
  ];

  postInstall = let

    compatFirmware = extraFirmware
      ++ lib.optional (gt68xxFirmware != null) {
        src = gt68xxFirmware.fw;
        inherit (gt68xxFirmware) name;
        backend = "gt68xx";
      }
      ++ lib.optional (snapscanFirmware != null) {
        src = snapscanFirmware;
        name = "your-firmwarefile.bin";
        backend = "snapscan";
      };

    installFirmware = f: ''
      mkdir -p $out/share/sane/${f.backend}
      ln -sv ${f.src} $out/share/sane/${f.backend}/${f.name}
    '';

  in ''
    mkdir -p $out/etc/udev/rules.d/ $out/etc/udev/hwdb.d
    ./tools/sane-desc -m udev+hwdb -s doc/descriptions:doc/descriptions-external > $out/etc/udev/rules.d/49-libsane.rules
    ./tools/sane-desc -m udev+hwdb -s doc/descriptions:doc/descriptions-external -m hwdb > $out/etc/udev/hwdb.d/20-sane.hwdb
    # the created 49-libsane references /bin/sh
    substituteInPlace $out/etc/udev/rules.d/49-libsane.rules \
      --replace "RUN+=\"/bin/sh" "RUN+=\"${runtimeShell}"

    substituteInPlace $out/lib/libsane.la \
      --replace "-ljpeg" "-L${lib.getLib libjpeg}/lib -ljpeg"

    # net.conf conflicts with the file generated by the nixos module
    rm $out/etc/sane.d/net.conf

  ''
  + lib.optionalString scanSnapDriversUnfree ''
    # the ScanSnap drivers live under the epjitsu subdirectory, which was already created by the build but is empty.
    rmdir $out/share/sane/epjitsu
    ln -svT ${scanSnapDriversPackage} $out/share/sane/epjitsu
  ''
  + lib.concatStrings (builtins.map installFirmware compatFirmware);

  # parallel install creates a bad symlink at $out/lib/sane/libsane.so.1 which prevents finding plugins
  # https://github.com/NixOS/nixpkgs/issues/224569
  enableParallelInstalling = false;

  passthru.tests = {
    inherit (nixosTests) sane;
  };

  meta = {
    description = "SANE (Scanner Access Now Easy) backends";
    longDescription = ''
      Collection of open-source SANE backends (device drivers).
      SANE is a universal scanner interface providing standardized access to
      any raster image scanner hardware: flatbed scanners, hand-held scanners,
      video- and still-cameras, frame-grabbers, etc. For a list of supported
      scanners, see http://www.sane-project.org/sane-backends.html.
    '';
    homepage = "http://www.sane-project.org/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = [ lib.maintainers.symphorien ];
  };
}
