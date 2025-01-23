{
  lib,
  fetchFromGitHub,
  nix-update-script,
  rustPlatform,
  versionCheckHook,
}:

rustPlatform.buildRustPackage rec {
  pname = "jellyfin-rpc";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "Radiicall";
    repo = "jellyfin-rpc";
    tag = version;
    hash = "sha256-sr82lTOr6RUvYD0CVZMyyRAFjai1oLnRWIszuu7/jE0=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-fpd+KYKrKy6zS2YeNaUX5J+wtfzAiq7tMXRKSlZ9r7U=";

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Displays the content you're currently watching on Discord";
    homepage = "https://github.com/Radiicall/jellyfin-rpc";
    changelog = "https://github.com/Radiicall/jellyfin-rpc/releases/tag/${version}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "jellyfin-rpc";
  };
}
