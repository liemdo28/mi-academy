import pathlib


def W(n, c):
    pathlib.Path(n).write_text(c, encoding="utf-8")


print("gen ready")
