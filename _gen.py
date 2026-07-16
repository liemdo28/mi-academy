# gen.py
import os
from pathlib import Path
BASE=Path(r"d:\Project\mi-academy")
def w(p,t):
  d=BASE/p;d.parent.mkdir(parents=True,exist_ok=True)
  d.write_text(t,encoding="utf-8")
  print(f"  {p} ({d.stat().st_size}b)")

