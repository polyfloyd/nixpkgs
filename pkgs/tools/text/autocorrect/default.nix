{ lib, stdenv, rustPlatform, fetchFromGitHub, Security, SystemConfiguration }:

rustPlatform.buildRustPackage rec {
  pname = "autocorrect";
  version = "2.11.1";

  src = fetchFromGitHub {
    owner = "huacnlee";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-iBwF8rMm4MbHwJSDmENDgGJKCl05psStxsi6BIliZP0=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ Security SystemConfiguration ];

  cargoBuildFlags = [ "-p" "autocorrect-cli" ];
  cargoTestFlags = [ "-p" "autocorrect-cli" ];

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Linter and formatter for help you improve copywriting, to correct spaces, punctuations between CJK (Chinese, Japanese, Korean)";
    mainProgram = "autocorrect";
    homepage = "https://huacnlee.github.io/autocorrect";
    changelog = "https://github.com/huacnlee/autocorrect/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = [ ];
  };
}
