{
  lib,
  stdenv,
  fetchFromGitLab,
  rustPlatform,
  substituteAll,
  cargo,
  desktop-file-utils,
  git,
  itstool,
  meson,
  ninja,
  pkg-config,
  python3,
  rustc,
  wrapGAppsHook4,
  borgbackup,
  gtk4,
  libadwaita,
  libsecret,
}:

stdenv.mkDerivation rec {
  pname = "pika-backup";
  version = "0.7.4";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "World";
    repo = "pika-backup";
    rev = "v${version}";
    hash = "sha256-DtLGD7+Ydj2fvEHU+bDQDMC/E/9VgrlVNMCG6OlPmfg=";
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    name = "${pname}-${version}";
    hash = "sha256-8nFkc77FiLxMA1hMm8k5VB84l+pQeL0JSzYDytXrNUE=";
  };

  patches = [
    (substituteAll {
      src = ./borg-path.patch;
      borg = lib.getExe borgbackup;
    })
  ];

  postPatch = ''
    patchShebangs build-aux
  '';

  nativeBuildInputs = [
    desktop-file-utils
    git
    itstool
    meson
    ninja
    pkg-config
    python3
    wrapGAppsHook4
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  buildInputs = [
    gtk4
    libadwaita
    libsecret
  ];

  meta = with lib; {
    description = "Simple backups based on borg";
    homepage = "https://apps.gnome.org/app/org.gnome.World.PikaBackup";
    changelog = "https://gitlab.gnome.org/World/pika-backup/-/blob/v${version}/CHANGELOG.md";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ dotlambda ];
    platforms = platforms.linux;
  };
}
