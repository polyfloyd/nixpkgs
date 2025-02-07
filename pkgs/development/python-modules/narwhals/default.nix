{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  hatchling,

  # optional-dependencies
  # cudf,
  dask,
  # modin,
  pandas,
  polars,
  pyarrow,

  # tests
  duckdb,
  hypothesis,
  pytest-env,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "narwhals";
  version = "1.25.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "narwhals-dev";
    repo = "narwhals";
    tag = "v${version}";
    hash = "sha256-cp/Ang5RXLpgTdpOHRKz9fGN9D+SgFC5KhF3ukf8G+w=";
  };

  build-system = [
    hatchling
  ];

  optional-dependencies = {
    # cudf = [ cudf ];
    dask = [
      dask
    ];
    # modin = [ modin ];
    pandas = [ pandas ];
    polars = [ polars ];
    pyarrow = [ pyarrow ];
  };

  nativeCheckInputs = [
    duckdb
    hypothesis
    pytest-env
    pytestCheckHook
  ] ++ lib.flatten (builtins.attrValues optional-dependencies);

  pythonImportsCheck = [ "narwhals" ];

  pytestFlagsArray = [
    "-W"
    "ignore::DeprecationWarning"
  ];

  meta = {
    description = "Lightweight and extensible compatibility layer between dataframe libraries";
    homepage = "https://github.com/narwhals-dev/narwhals";
    changelog = "https://github.com/narwhals-dev/narwhals/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fab ];
  };
}
