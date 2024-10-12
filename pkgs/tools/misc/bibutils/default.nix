{ lib
, stdenv
, fetchurl
, static ? stdenv.hostPlatform.isStatic
}:

stdenv.mkDerivation rec {
  pname = "bibutils";
  version = "7.2";

  src = fetchurl {
    url = "mirror://sourceforge/bibutils/bibutils_${version}_src.tgz";
    sha256 = "sha256-bgKK7x6Kaz5azvCYWEp7tocI81z+dAEbNBwR/qXktcM=";
  };

  preConfigure = lib.optionalString stdenv.hostPlatform.isDarwin ''
    substituteInPlace lib/Makefile.dynamic \
      --replace '-Wl,-soname,$(SONAME)' ""
  '';

  # the configure script is not generated by autoconf
  # and do not recognize --build/--host cross compilation flags
  configurePlatforms = [ ];

  configureFlags = [
    (if static then "--static" else "--dynamic")
    "--install-dir" "$(out)/bin"
    "--install-lib" "$(out)/lib"
  ];

  dontAddPrefix = true;

  makeFlags = [
    "CC:=$(CC)"
  ];

  doCheck = true;
  checkTarget = "test";
  preCheck = lib.optionalString stdenv.hostPlatform.isDarwin ''
    export DYLD_LIBRARY_PATH=`pwd`/lib
  '';

  meta = with lib; {
    description = "Bibliography format interconversion";
    longDescription = "The bibutils program set interconverts between various bibliography formats using a common MODS-format XML intermediate. For example, one can convert RIS-format files to Bibtex by doing two transformations: RIS->MODS->Bibtex. By using a common intermediate for N formats, only 2N programs are required and not N²-N. These programs operate on the command line and are styled after standard UNIX-like filters.";
    homepage = "https://sourceforge.net/p/bibutils/home/Bibutils/";
    license = licenses.gpl2Only;
    maintainers = [ maintainers.garrison ];
    platforms = platforms.unix;
  };
}
