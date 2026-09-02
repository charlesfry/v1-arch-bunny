#!/usr/bin/env bash
# Deterministic 1500-line Python file for editor startup benchmarks (3.9/4.15 method).
set -Eeuo pipefail
{
  echo "import json"
  echo "import os"
  for i in $(seq 1 299); do
    cat <<PYEOF
def func_$i(x: int, y: str = "v$i") -> dict:
    """Docstring for function $i."""
    data = {"idx": $i, "x": x, "y": y}
    return data

PYEOF
  done
  echo 'if __name__ == "__main__":'
  echo '    print(json.dumps([func_1(1), func_299(299)]))'
} > "${1:-testfile-1500.py}"
wc -l "${1:-testfile-1500.py}" >&2
