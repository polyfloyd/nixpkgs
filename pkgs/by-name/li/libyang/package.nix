{
  stdenv,
  lib,
  fetchFromGitHub,

  # build time
  cmake,
  pkg-config,

  # run time
  pcre2,

  # update script
  gitUpdater,
}:

stdenv.mkDerivation rec {
  pname = "libyang";
  version = "3.4.2";

  src = fetchFromGitHub {
    owner = "CESNET";
    repo = "libyang";
    rev = "v${version}";
    hash = "sha256-pki4T6faY42UcnzOT6697FJWyPRNKNbUFEFZkkeWUx8=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    pcre2
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ];

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "YANG data modelling language parser and toolkit";
    longDescription = ''
      libyang is a YANG data modelling language parser and toolkit written (and
      providing API) in C. The library is used e.g. in libnetconf2, Netopeer2,
      sysrepo or FRRouting projects.
    '';
    homepage = "https://github.com/CESNET/libyang";
    license = with licenses; [ bsd3 ];
    platforms = platforms.unix;
    maintainers = with maintainers; [ woffs ];
  };
}
