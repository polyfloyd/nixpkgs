{ lib, stdenv, fetchurl
, updateAutotoolsGnuConfigScriptsHook
, coreutils
}:

# Note: this package is used for bootstrapping fetchurl, and thus
# cannot use fetchpatch! All mutable patches (generated by GitHub or
# cgit) that are needed here should be included directly in Nixpkgs as
# files.

stdenv.mkDerivation rec {
  pname = "findutils";
  version = "4.10.0";

  src = fetchurl {
    url = "mirror://gnu/findutils/findutils-${version}.tar.xz";
    sha256 = "sha256-E4fgtn/yR9Kr3pmPkN+/cMFJE5Glnd/suK5ph4nwpPU=";
  };

  postPatch = ''
    substituteInPlace xargs/xargs.c --replace 'char default_cmd[] = "echo";' 'char default_cmd[] = "${coreutils}/bin/echo";'
  '';

  patches = [ ./no-install-statedir.patch ];

  nativeBuildInputs = [ updateAutotoolsGnuConfigScriptsHook ];
  buildInputs = [ coreutils ]; # bin/updatedb script needs to call sort

  # Since glibc-2.25 the i686 tests hang reliably right after test-sleep.
  doCheck
    =  !stdenv.hostPlatform.isDarwin
    && !stdenv.hostPlatform.isFreeBSD
    && !(stdenv.hostPlatform.libc == "glibc" && stdenv.hostPlatform.isi686)
    && (stdenv.hostPlatform.libc != "musl")
    && stdenv.hostPlatform == stdenv.buildPlatform;

  outputs = [ "out" "info" "locate"];

  configureFlags = [
    # "sort" need not be on the PATH as a run-time dep, so we need to tell
    # configure where it is. Covers the cross and native case alike.
    "SORT=${coreutils}/bin/sort"
    "--localstatedir=/var/cache"
  ];

  CFLAGS = lib.optionals stdenv.hostPlatform.isDarwin [
    # TODO: Revisit upstream issue https://savannah.gnu.org/bugs/?59972
    # https://github.com/Homebrew/homebrew-core/pull/69761#issuecomment-770268478
    "-D__nonnull\\(params\\)="
  ];

  postInstall = ''
    moveToOutput bin/locate $locate
    moveToOutput bin/updatedb $locate
  '';

  # can't move man pages in postInstall because the multi-output hook will move them back to $out
  postFixup = ''
    moveToOutput share/man/man5 $locate
    moveToOutput share/man/man1/locate.1.gz $locate
    moveToOutput share/man/man1/updatedb.1.gz $locate
  '';

  enableParallelBuilding = true;

  # bionic libc is super weird and has issues with fortify outside of its own libc, check this comment:
  # https://github.com/NixOS/nixpkgs/pull/192630#discussion_r978985593
  # or you can check libc/include/sys/cdefs.h in bionic source code
  hardeningDisable = lib.optional (stdenv.hostPlatform.libc == "bionic") "fortify";

  meta = {
    homepage = "https://www.gnu.org/software/findutils/";
    description = "GNU Find Utilities, the basic directory searching utilities of the GNU operating system";

    longDescription = ''
      The GNU Find Utilities are the basic directory searching
      utilities of the GNU operating system.  These programs are
      typically used in conjunction with other programs to provide
      modular and powerful directory search and file locating
      capabilities to other commands.

      The tools supplied with this package are:

          * find - search for files in a directory hierarchy;
          * xargs - build and execute command lines from standard input.

      The following are available in the locate output:

          * locate - list files in databases that match a pattern;
          * updatedb - update a file name database;
    '';

    platforms = lib.platforms.all;

    license = lib.licenses.gpl3Plus;

    mainProgram = "find";
  };
}
