{
  description = "Dev env (Verilator, SiliconCompiler, Surfer)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs:
        let
          python = pkgs.python313;
          runtimeLibs = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
          ];
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              verilator
              surfer
              gnumake
              git
              python
              uv
            ];

            buildInputs = with pkgs; [
              lz4
              zlib
            ];

            shellHook = ''
              export LD_LIBRARY_PATH="${runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

              repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
              venv_dir="$repo_root/.venv"

              if [ ! -x "$venv_dir/bin/python3" ] || ! "$venv_dir/bin/python3" -c "import siliconcompiler" >/dev/null 2>&1; then
                echo "Setting up Python virtual environment with siliconcompiler..."
                uv venv --python "${python}/bin/python3" "$venv_dir"
                uv pip install --python "$venv_dir/bin/python3" siliconcompiler
              fi

              export VIRTUAL_ENV="$venv_dir"
              export PATH="$VIRTUAL_ENV/bin:$PATH"

              mkdir -p "$HOME/verilator_builds" 2>/dev/null || true
            '';
          };
        });
    };
}
