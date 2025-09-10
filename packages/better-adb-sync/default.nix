{
  lib,
  python3Packages,
  fetchPypi,
  android-tools,
}:
python3Packages.buildPythonApplication rec {
  pname = "better-adb-sync";
  version = "1.4.0";
  format = "pyproject";

  src = fetchPypi {
    inherit version;
    pname = "BetterADBSync";
    sha256 = "sha256-z6E8gayItFEpT9GIi7LAZ5xIptNyUH/IBj6mJffmzoI=";
  };

  nativeBuildInputs = [
    python3Packages.setuptools
  ];

  propagatedBuildInputs = [
    python3Packages.adb-shell
    android-tools
  ];

  meta = with lib; {
    homepage = "https://github.com/jb2170/better-adb-sync";
    platforms = platforms.all;
    mainProgram = "better-adb-sync";
  };
}
