{
  lib,
  darwin,
  fetchFromGitHub,
  nix-update-script,
  rustPlatform,
  stdenv,
}:
let
  version = "0.2.7";
in
rustPlatform.buildRustPackage {
  inherit version;
  pname = "rainfrog";

  src = fetchFromGitHub {
    owner = "achristmascarl";
    repo = "rainfrog";
    rev = "refs/tags/v${version}";
    hash = "sha256-ey9ioPDeuNYw2+UBUgtE0C1wES3wecFDWd9CMeKBq4Q=";
  };

  cargoHash = "sha256-mc7Lgaf1seefVu+LafctJm4y8xjX3c1ApadeQMi3STE=";

  buildInputs = lib.optionals stdenv.isDarwin (
    with darwin.apple_sdk.frameworks;
    [
      AppKit
      CoreGraphics
      SystemConfiguration
    ]
  );

  passthru.updateScript = nix-update-script { };

  meta = {
    changelog = "https://github.com/achristmascarl/rainfrog/releases/tag/v${version}";
    description = "A database management TUI for postgres";
    homepage = "https://github.com/achristmascarl/rainfrog";
    license = lib.licenses.mit;
    mainProgram = "rainfrog";
    maintainers = with lib.maintainers; [ patka ];
  };
}
