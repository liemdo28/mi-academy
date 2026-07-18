import pathlib

GEN = {}


def reg(name, code):
    GEN[name] = code


def emit():
    for n, c in GEN.items():
        pathlib.Path(n).write_text(c, encoding="utf-8")


print("gen setup")
