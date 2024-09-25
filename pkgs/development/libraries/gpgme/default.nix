{
  lib,
  stdenv,
  fetchurl,
  autoreconfHook,
  libgpg-error,
  gnupg,
  pkg-config,
  glib,
  pth,
  libassuan,
  which,
  ncurses,
  texinfo,
  buildPackages,
  qtbase ? null,
  pythonSupport ? false,
  swig ? null,
  # only for passthru.tests
  libsForQt5,
  qt6Packages,
  python3,
}:

stdenv.mkDerivation rec {
  pname = "gpgme";
  version = "1.23.2";
  pyproject = true;

  outputs = [
    "out"
    "dev"
    "info"
  ];

  outputBin = "dev"; # gpgme-config; not so sure about gpgme-tool

  src = fetchurl {
    url = "mirror://gnupg/gpgme/gpgme-${version}.tar.bz2";
    hash = "sha256-lJnosfM8zLaBVSehvBYEnTWmGYpsX64BhfK9VhvOUiQ=";
  };

  patches = [
    # Support Python 3.10-3.12, remove distutils, https://dev.gnupg.org/D545
    ./python-310-312-remove-distutils.patch
    # Fix a test after disallowing compressed signatures in gpg (PR #180336)
    ./test_t-verify_double-plaintext.patch
    # Don't use deprecated LFS64 APIs (removed in musl 1.2.4)
    # https://dev.gnupg.org/D600
    ./LFS64.patch
  ];

  postPatch = ''
    # autoconf's beta detection requires a git repo to work
    # and otherwise appends -unknown to the version number used in the python package which pip stumbles upon
    substituteInPlace autogen.sh \
      --replace-fail 'tmp="-unknown"' 'tmp=""'
  '';

  nativeBuildInputs =
    [
      autoreconfHook
      gnupg
      pkg-config
      texinfo
    ]
    ++ lib.optionals pythonSupport [
      python3.pythonOnBuildForHost
      python3.pkgs.pip
      python3.pkgs.setuptools
      python3.pkgs.wheel
      ncurses
      swig
      which
    ];

  buildInputs = lib.optionals pythonSupport [ python3 ];

  propagatedBuildInputs = [
    glib
    libassuan
    libgpg-error
    pth
  ] ++ lib.optionals (qtbase != null) [ qtbase ];

  nativeCheckInputs = [ which ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  dontWrapQtApps = true;

  configureFlags =
    [
      "--enable-fixed-path=${gnupg}/bin"
      "--with-libgpg-error-prefix=${libgpg-error.dev}"
      "--with-libassuan-prefix=${libassuan.dev}"
    ]
    ++ lib.optional pythonSupport "--enable-languages=python"
    # Tests will try to communicate with gpg-agent instance via a UNIX socket
    # which has a path length limit. Nix on darwin is using a build directory
    # that already has quite a long path and the resulting socket path doesn't
    # fit in the limit. https://github.com/NixOS/nix/pull/1085
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ "--disable-gpg-test" ];

  env.NIX_CFLAGS_COMPILE = toString (
    # qgpgme uses Q_ASSERT which retains build inputs at runtime unless
    # debugging is disabled
    lib.optional (qtbase != null) "-DQT_NO_DEBUG"
    # https://www.gnupg.org/documentation/manuals/gpgme/Largefile-Support-_0028LFS_0029.html
    ++ lib.optional stdenv.hostPlatform.is32bit "-D_FILE_OFFSET_BITS=64"
  );

  enableParallelBuilding = true;

  # prevent tests from being run during the buildPhase
  makeFlags = [ "tests=" ];

  doCheck = true;

  checkFlags = [
    "-C"
    "tests"
  ];

  passthru.tests = {
    python = python3.pkgs.gpgme;
    qt5 = libsForQt5.qgpgme;
    qt6 = qt6Packages.qgpgme;
  };

  meta = with lib; {
    homepage = "https://gnupg.org/software/gpgme/index.html";
    changelog = "https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gpgme.git;f=NEWS;hb=gpgme-${version}";
    description = "Library for making GnuPG easier to use";
    longDescription = ''
      GnuPG Made Easy (GPGME) is a library designed to make access to GnuPG
      easier for applications. It provides a High-Level Crypto API for
      encryption, decryption, signing, signature verification and key
      management.
    '';
    license = with licenses; [
      lgpl21Plus
      gpl3Plus
    ];
    platforms = platforms.unix;
    maintainers = with maintainers; [ dotlambda ];
  };
}
