{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "nomino";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "yaa110";
    repo = pname;
    rev = version;
    hash = "sha256-/5rKlPRo3+BsqPgHJ0M/JDGwA0c4rAiOd7gGClPfxMg=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-lHDMOOvdtjPPXfz/ducTqXFAO/1zCJZKwKGRdEHDhmg=";

  meta = with lib; {
    description = "Batch rename utility for developers";
    homepage = "https://github.com/yaa110/nomino";
    changelog = "https://github.com/yaa110/nomino/releases/tag/${src.rev}";
    license = with licenses; [
      mit # or
      asl20
    ];
    maintainers = with maintainers; [ figsoda ];
    mainProgram = "nomino";
  };
}
