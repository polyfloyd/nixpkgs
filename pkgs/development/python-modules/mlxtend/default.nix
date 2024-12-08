{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  isPy27,
  setuptools,
  pytestCheckHook,
  scipy,
  numpy,
  scikit-learn,
  pandas,
  matplotlib,
  joblib,
}:

buildPythonPackage rec {
  pname = "mlxtend";
  version = "0.23.3";
  pyproject = true;

  disabled = isPy27;

  src = fetchFromGitHub {
    owner = "rasbt";
    repo = pname;
    tag = "v${version}";
    hash = "sha256-c6I0dwu4y/Td2G6m2WP/52W4noQUmQMDvpzXA9RZauo=";
  };

  build-system = [ setuptools ];

  dependencies = [
    scipy
    numpy
    scikit-learn
    pandas
    matplotlib
    joblib
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pytestFlagsArray = [ "-sv" ];

  disabledTestPaths = [
    "mlxtend/evaluate/f_test.py" # need clean
    "mlxtend/evaluate/tests/test_feature_importance.py" # urlopen error
    "mlxtend/evaluate/tests/test_bias_variance_decomp.py" # keras.api._v2
    "mlxtend/evaluate/tests/test_bootstrap_point632.py" # keras.api._v2
  ];

  meta = {
    description = "Library of Python tools and extensions for data science";
    homepage = "https://github.com/rasbt/mlxtend";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ evax ];
    platforms = lib.platforms.unix;
  };
}
