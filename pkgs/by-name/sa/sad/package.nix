{
  lib,
  fetchFromGitHub,
  rustPlatform,
  python3,
}:

rustPlatform.buildRustPackage rec {
  pname = "sad";
  version = "0.4.31";

  src = fetchFromGitHub {
    owner = "ms-jpq";
    repo = "sad";
    tag = "v${version}";
    hash = "sha256-frsOfv98VdetlwgNA6O0KEhcCSY9tQeEwkl2am226ko=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-ea/jimyghG7bqe9iRhYL13RQ4gwp9Ke3IjpSI8dTyr8=";

  nativeBuildInputs = [ python3 ];

  # fix for compilation on aarch64
  # see https://github.com/NixOS/nixpkgs/issues/145726
  prePatch = ''
    rm .cargo/config.toml
  '';

  meta = with lib; {
    description = "CLI tool to search and replace";
    homepage = "https://github.com/ms-jpq/sad";
    changelog = "https://github.com/ms-jpq/sad/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
    mainProgram = "sad";
  };
}
