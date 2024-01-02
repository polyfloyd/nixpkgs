{ lib
, config
, buildPythonPackage
, fetchFromGitHub
, substituteAll
, addDriverRunpath
, cudaSupport ? config.cudaSupport
, rocmSupport ? config.rocmSupport
, cudaPackages
, setuptools
, ocl-icd
, rocmPackages
, pytestCheckHook
}:
buildPythonPackage rec {
  pname = "gpuctypes";
  version = "0.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    repo = "gpuctypes";
    owner = "tinygrad";
    rev = "refs/tags/${version}";
    hash = "sha256-xUMvMBK1UhZaMZfik0Ia6+siyZGpCkBV+LTnQvzt/rw=";
  };

  patches = [
    (substituteAll {
      src = ./0001-fix-dlopen-cuda.patch;
      inherit (addDriverRunpath) driverLink;
      libnvrtc =
        if cudaSupport
        then "${lib.getLib cudaPackages.cuda_nvrtc}/lib/libnvrtc.so"
        else "Please import nixpkgs with `config.cudaSupport = true`";
    })
  ];

  nativeBuildInputs = [
    setuptools
  ];

  postPatch = ''
    substituteInPlace gpuctypes/opencl.py \
      --replace "ctypes.util.find_library('OpenCL')" "'${ocl-icd}/lib/libOpenCL.so'"
  ''
  # hipGetDevicePropertiesR0600 is a symbol from rocm-6. We are currently at rocm-5.
  # We are not sure that this works. Remove when rocm gets updated to version 6.
  + lib.optionalString rocmSupport ''
    substituteInPlace gpuctypes/hip.py \
      --replace "/opt/rocm/lib/libamdhip64.so" "${rocmPackages.clr}/lib/libamdhip64.so" \
      --replace "/opt/rocm/lib/libhiprtc.so" "${rocmPackages.clr}/lib/libhiprtc.so" \
      --replace "hipGetDevicePropertiesR0600" "hipGetDeviceProperties"

    substituteInPlace gpuctypes/comgr.py \
      --replace "/opt/rocm/lib/libamd_comgr.so" "${rocmPackages.rocm-comgr}/lib/libamd_comgr.so"
  '';

  pythonImportsCheck = [ "gpuctypes" ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  disabledTestPaths = [
    "test/test_opencl.py"
  ] ++ lib.optionals (!rocmSupport) [
    "test/test_hip.py"
  ] ++ lib.optionals (!cudaSupport) [
    "test/test_cuda.py"
  ];

  # Require GPU access to run (not available in the sandbox)
  pytestFlagsArray = [
    "-k" "'not TestCUDADevice'"
    "-k" "'not TestHIPDevice'"
  ];

  preCheck = lib.optionalString cudaSupport ''
    addToSearchPath LD_LIBRARY_PATH ${lib.getLib cudaPackages.cuda_cudart}/lib/stubs
  '';

  # If neither rocmSupport or cudaSupport is enabled, no tests are selected
  dontUsePytestCheck = !(rocmSupport || cudaSupport);

  meta = with lib; {
    description = "Ctypes wrappers for HIP, CUDA, and OpenCL";
    homepage = "https://github.com/tinygrad/gpuctypes";
    license = licenses.mit;
    maintainers = with maintainers; [ GaetanLepage matthewcroughan wozeparrot ];
  };
}
