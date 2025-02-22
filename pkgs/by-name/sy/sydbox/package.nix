{
  lib,
  fetchFromGitLab,
  libseccomp,
  mandoc,
  nix-update-script,
  pkg-config,
  rustPlatform,
  scdoc,
  sydbox,
  testers,
}:

rustPlatform.buildRustPackage rec {
  pname = "sydbox";
  version = "3.32.3";

  outputs = [
    "out"
    "man"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.exherbo.org";
    owner = "Sydbox";
    repo = "sydbox";
    tag = "v${version}";
    hash = "sha256-h96D/IeNJ3sTiJNHGUzU5iR1XJCeI83s3EB659MS5ds=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-AwN3DIVJb3M4nJ+2GWtPTLGKA3zMcxw6Oq19s/JtFGE=";

  nativeBuildInputs = [
    mandoc
    pkg-config
    scdoc
  ];

  buildInputs = [ libseccomp ];

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  checkFlags = [
    # rm -rf tmpdir: Os { code: 2, kind: NotFound, message: "No such file or directory" }
    "--skip=fs::tests::test_relative_symlink_resolution"
    # Failed to write C source file!: Os { code: 13, kind: PermissionDenied, message: "Permission denied" }
    "--skip=proc::tests::test_proc_set_at_secure_test_32bit_dynamic"
    # Flakey. May only fail on OfBorg/Hydra
    # Failed to write C source file!: Os { code: 13, kind: PermissionDenied, message: "Permission denied" }
    "proc::tests::test_proc_set_at_secure_test_32bit_static"
    # Failed to write C source file!: Os { code: 13, kind: PermissionDenied, message: "Permission denied" }
    "--skip=proc::tests::test_proc_set_at_secure_test_32bit_static_pie"
    # /bin/false: Os { code: 2, kind: NotFound, message: "No such file or directory" }
    "--skip=syd_test"

    # Endlessly stall or use "invalid arguments". Maybe a sandbox issue?
    "--skip=caps"
    "--skip=landlock"
    "--skip=proc::proc_cmdline"
    "--skip=proc::proc_comm"
  ];

  # TODO: Have these directories be created upstream similar to the vim files
  postInstall = ''
    mkdir -p $out/share/man/man{1,2,5,7}

    make $makeFlags install-{man,vim}
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = sydbox;
      command = "syd -V";
    };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "seccomp-based application sandbox";
    homepage = "https://gitlab.exherbo.org/sydbox/sydbox";
    changelog = "https://gitlab.exherbo.org/sydbox/sydbox/-/blob/${src.tag}/ChangeLog.md";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [
      mvs
      getchoo
    ];
    mainProgram = "syd";
    platforms = lib.platforms.linux;
  };
}
