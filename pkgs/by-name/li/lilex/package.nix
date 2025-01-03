{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "lilex";
  version = "2.600";

  src = fetchurl {
    url = "https://github.com/mishamyrt/Lilex/releases/download/${version}/Lilex.zip";
    hash = "sha256-G8zm35aSiXrnGgYePSwLMBzwSnd9mfCinHZSG1qBH0w=";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    runHook preUnpack
    unzip $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    find . -name '*.ttf' -exec install -m444 -Dt $out/share/fonts/truetype {} +
    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source programming font";
    homepage = "https://github.com/mishamyrt/Lilex";
    license = licenses.ofl;
    maintainers = with maintainers; [ redyf ];
    platforms = platforms.all;
  };
}
