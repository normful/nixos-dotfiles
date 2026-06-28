{
  lib,
  fetchFromGitHub,
  python313Packages,
}:

python313Packages.buildPythonApplication rec {
  pname = "voxterm";
  version = "0.3.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "dmarzzz";
    repo = "VoxTerm";
    rev = "v${version}";
    hash = "sha256-yOmqc0EnK4UkIWfYZlae5yGnDH/xlj6nwPOR0oC/SCU=";
  };

  nativeBuildInputs = with python313Packages; [
    hatchling
  ];

  propagatedBuildInputs = with python313Packages; [
    cryptography
    numpy
    scipy
    sounddevice
    zeroconf
    textual
    rumps
    mlx-lm
    faster-whisper
    pysilero-vad
  ];

  # onnxruntime in nixpkgs is 1.24.x; VoxTerm caps at <1.24 due to a
  # heap-leak regression in 1.24.0. Using the nixpkgs version may cause
  # memory growth over long diarization sessions.
  # mlx-whisper, mlx-qwen3-asr, parakeet-mlx are not in nixpkgs and
  # omitted — Apple Silicon MLX transcription backends will be unavailable.
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "Local real-time voice transcription TUI with speaker diarization";
    longDescription = ''
      VoxTerm is a local-first, private-by-default voice transcription TUI
      with speaker diarization. Everything runs on your machine, nothing
      leaves. Uses MLX (Apple Silicon) or faster-whisper (other platforms)
      for transcription, silero-vad for voice activity detection, and
      textual for the terminal UI.

      Note: Apple Silicon MLX backends (mlx-whisper, mlx-qwen3-asr,
      parakeet-mlx) are not yet in nixpkgs — transcription falls back to
      faster-whisper. The onnxruntime package in nixpkgs is 1.24.x which
      may exhibit heap growth over long sessions.
    '';
    homepage = "https://github.com/dmarzzz/VoxTerm";
    license = licenses.mit;
    mainProgram = "voxterm";
    platforms = [ "aarch64-darwin" ];
  };
}
