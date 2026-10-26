import re
import sys

REFERENCE_FUNCTIONS = ["sdSuperellipse", "f", "rand", "Glow"]

DOCUMENTED_ADAPTATIONS = [
    ("texture(u_Slots[5],coord)", "texture(u_Slots5,vec2(coord.x,1.0-coord.y))"),
    ("smoothstep(u_glowEdge0,u_glowEdge1,dist)", "GlowEdge(dist)"),
]

HEADER_TO_QML = {
    "u_powerFactor": "powerFactor",
    "u_a": "a",
    "u_b": "b",
    "u_c": "c",
    "u_d": "d",
    "u_fPower": "fPower",
    "u_noise": "noise",
    "u_glowWeight": "glowWeight",
    "u_glowBias": "glowBias",
    "u_glowEdge0": "glowEdge0",
    "u_glowEdge1": "glowEdge1",
}


def normalize(text):
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"\s+", "", text)


def function_body(text, name):
    match = re.search(r"(?:float|vec4|vec2)\s+" + name + r"\s*\([^)]*\)\s*\{", text)
    if not match:
        return None
    index = match.end()
    depth = 1
    while depth:
        char = text[index]
        depth += (char == "{") - (char == "}")
        index += 1
    return normalize(text[match.start():index])


def check_shader(reference_path, port_path):
    reference = open(reference_path).read().split("#type fragment")[1]
    port = open(port_path).read()
    ok = True
    for name in REFERENCE_FUNCTIONS:
        same = function_body(reference, name) == function_body(port, name)
        ok = ok and same
        print(name, "IDENTIQUE" if same else "DIFFERENT")
    expected = function_body(reference, "LiquidGlass")
    for original, replacement in DOCUMENTED_ADAPTATIONS:
        expected = expected.replace(original, replacement)
    same = expected == function_body(port, "LiquidGlass")
    ok = ok and same
    print("LiquidGlass", "IDENTIQUE aux adaptations documentees pres" if same else "DIFFERENT")
    return ok


def check_defaults(header_path, qml_path):
    header = open(header_path).read()
    qml = open(qml_path).read()
    ok = True
    for uniform, prop in HEADER_TO_QML.items():
        sent = re.search(r"float\s+" + uniform + r"\s*=\s*(-?[0-9.]+)f?\s*;", header)
        declared = re.search(r"property\s+real\s+" + prop + r":\s*(-?[0-9.]+)", qml)
        if not sent or not declared:
            print(uniform, "INTROUVABLE")
            ok = False
            continue
        same = float(sent.group(1)) == float(declared.group(1))
        ok = ok and same
        print(uniform, sent.group(1), declared.group(1), "OK" if same else "DIFFERENT")
    return ok


def main():
    if len(sys.argv) != 5:
        print("usage: fidelity.py BatchRenderer2D.glsl LiquidGlass.frag LiquidGlass.h LiquidGlass.qml")
        return 2
    shader_ok = check_shader(sys.argv[1], sys.argv[2])
    defaults_ok = check_defaults(sys.argv[3], sys.argv[4])
    return 0 if shader_ok and defaults_ok else 1


if __name__ == "__main__":
    sys.exit(main())
