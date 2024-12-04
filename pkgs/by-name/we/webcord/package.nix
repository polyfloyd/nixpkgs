{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  copyDesktopItems,
  python3,
  xdg-utils,
  electron,
  makeDesktopItem,
}:

buildNpmPackage rec {
  pname = "webcord";
  version = "4.10.2";

  src = fetchFromGitHub {
    owner = "SpacingBat3";
    repo = "WebCord";
    rev = "refs/tags/v${version}";
    hash = "sha256-vzTT8tHpbJSt1PosgKTg3pT4a9UfPabtJppLLD9znhU=";
  };

  npmDepsHash = "sha256-nVQv+GSnfQa8V/RitvV2juokbiRJ/vIMLWcg9QPDbP0=";

  nativeBuildInputs = [
    copyDesktopItems
    python3
  ];

  # npm install will error when electron tries to download its binary
  # we don't need it anyways since we wrap the program with our nixpkgs electron
  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  # remove husky commit hooks, errors and aren't needed for packaging
  postPatch = ''
    rm -rf .husky
  '';

  # override installPhase so we can copy the only folders that matter
  installPhase =
    let
      binPath = lib.makeBinPath [ xdg-utils ];
    in
    ''
      runHook preInstall

      # Remove dev deps that aren't necessary for running the app
      npm prune --omit=dev

      mkdir -p $out/lib/node_modules/webcord
      cp -r app node_modules sources package.json $out/lib/node_modules/webcord/

      install -Dm644 sources/assets/icons/app.png $out/share/icons/hicolor/256x256/apps/webcord.png

      # Add xdg-utils to path via suffix, per PR #181171
      makeWrapper '${lib.getExe electron}' $out/bin/webcord \
        --suffix PATH : "${binPath}" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --add-flags $out/lib/node_modules/webcord/

      runHook postInstall
    '';

  desktopItems = [
    (makeDesktopItem {
      name = "webcord";
      exec = "webcord";
      icon = "webcord";
      desktopName = "WebCord";
      comment = meta.description;
      categories = [
        "Network"
        "InstantMessaging"
      ];
    })
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "A Discord and SpaceBar electron-based client implemented without Discord API";
    homepage = "https://github.com/SpacingBat3/WebCord";
    downloadPage = "https://github.com/SpacingBat3/WebCord/releases";
    changelog = "https://github.com/SpacingBat3/WebCord/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "webcord";
    maintainers = with lib.maintainers; [
      huantian
    ];
    platforms = lib.platforms.linux;
  };
}
