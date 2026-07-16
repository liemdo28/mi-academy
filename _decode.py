import base64, sys
from pathlib import Path
p = Path(sys.argv[1])
print(p.parent.exists())
