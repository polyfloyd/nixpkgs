{
  buildPythonPackage,
  fetchPypi,
  lib,
  unittestCheckHook,
  setuptools,
  beancount,
  beangulp,
  python-dateutil,
}:

buildPythonPackage rec {
  pname = "beancount-periodic";
  version = "0.2";
  pyproject = true;
  build-system = [ setuptools ];

  src = fetchPypi {
    pname = "beancount_periodic";
    inherit version;
    hash = "sha256-TsCRuRgJGv5M7FapNLT2+MXLI2fQNOP8kGtTpTCw7FI=";
  };

  propagatedBuildInputs = [
    beancount
    beangulp
    python-dateutil
  ];

  # Remove when https://github.com/dallaslu/beancount-periodic/pull/13 is merged
  postPatch = ''
    patch -p0 <<END_PATCH
      +++ requirements.txt
      @@ -1,3 +1,3 @@
       beancount>=2.3.4
       beangulp>=0.1.1
      -python-dateutil~=2.8.2
      +python-dateutil~=2.9.0
    END_PATCH
  '';

  nativeCheckInputs = [ unittestCheckHook ];
  unittestFlags = [ "-v" "tests" ];

  pythonImportsCheck = [ "beancount_periodic" ];

  meta = with lib; {
    description = "Beancount plugin to generate periodic transactions";
    homepage = "https://github.com/dallaslu/beancount-periodic";
    # Update when upstream has picekd a license: https://github.com/dallaslu/beancount-periodic/issues/15
    license = with licenses; [ unfree ];
    maintainers = with maintainers; [ polyfloyd ];
  };
}
