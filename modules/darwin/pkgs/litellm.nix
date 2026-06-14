# Build a litellm proxy environment with all dependencies needed for
# `litellm --config ...` (the proxy server mode / litellm[proxy] extras).
# The base nixpkgs litellm package omits these; we add them via withPackages.
# a2a-sdk has flaky sandbox tests; override to skip them.
{ pkgs }:
let
  python = pkgs.python3.override {
    packageOverrides = _: pyPrev: {
      a2a-sdk = pyPrev.a2a-sdk.overrideAttrs (_: { doCheck = false; });
    };
  };

  env = python.withPackages (ps: [
    ps.litellm
    # litellm[proxy] extras
    ps.backoff
    ps.fastapi
    ps.uvicorn
    ps.pyyaml
    ps.python-dotenv
    ps.httpx
    ps.anyio
  ]);
in
  # Expose a derivation with a bin/litellm entry point from the env.
  pkgs.runCommand "litellm-proxy" {} ''
    mkdir -p $out/bin
    ln -s ${env}/bin/litellm $out/bin/litellm
  ''
