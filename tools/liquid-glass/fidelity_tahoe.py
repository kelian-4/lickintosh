import re
import sys

SOURCE_FILES = ["sdf.glsl", "blur.glsl", "distort.glsl", "highlight.glsl", "glass_core.glsl"]

FUNCTIONS = [
    "lgCornerLength",
    "lgRoundedRectDistance",
    "lgRoundedRectCoverage",
    "lgRoundedRectNormal",
    "lgGaussianBlur",
    "lgDockLensUV",
    "lgApplyRgbDrift",
    "lgRimAngularWeight",
    "lgApplyHighlight",
    "main",
]

SUBSTITUTIONS = [
    ("LG_SAMPLE(", "texture("),
    ("vec2textureNormal=vec2(direction.x,-direction.y);", "vec2textureNormal=direction;"),
    (",booldockSurface)", ")"),
    (
        "floatrim=dockSurface?1.6*exp(-inside*(2.0/band)):exp(-inside*(3.0/band))*smoothstep(0.0,2.0,inside);",
        "floatrim=1.6*exp(-inside*(2.0/band));",
    ),
    (
        "vec2pos=vertex-box.xy;",
        "vec2pos=(v_TexCoord-0.5)*blurSize;vec2uv=(screenOrigin+v_TexCoord*blurSize)/backgroundSize;",
    ),
    ("floatrefrBand=max(refractionWidth*(dockSurface?1.25:1.0),1.0);", "floatrefrBand=max(refractionWidth*1.25,1.0);"),
    ("floatedgeQ=edgeT*edgeT*(dockSurface?1.0:edgeT);", "floatedgeQ=edgeT*edgeT;"),
    (
        "lensUV=dockSurface?lgDockLensUV(uv,outNorm,pos,blurSize,backgroundSize,magnifyGlassStrength,edgeQ):lgLensUV(uv,magnifyGlassStrength,edgeQ);",
        "lensUV=lgDockLensUV(uv,outNorm,pos,blurSize,backgroundSize,magnifyGlassStrength,edgeQ);",
    ),
    (
        "vec3col;if(offset>0.0){col=lgGaussianBlur(texUnit,texel,lensUV);}else{vec2snapped=(floor(lensUV/texel)+0.5)*texel;col=texture(texUnit,clamp(snapped,0.0,1.0)).rgb;}",
        "vec3col=lgGaussianBlur(texUnit,texel,lensUV);",
    ),
    (
        "lgApplyRgbDrift(texUnit,col,lensUV,outNorm,blurSize,rgbDriftStrength,edgeQ)",
        "lgApplyRgbDrift(texUnit,col,lensUV,outNorm,backgroundSize,rgbDriftStrength,edgeQ)",
    ),
    (
        "lgApplyHighlight(col,inside,outNorm,highlightWidth,highlightStrength,dockSurface)",
        "lgApplyHighlight(col,inside,outNorm,highlightWidth,highlightStrength)",
    ),
    ("floatcoverage=materialOpacity*(dockSurface?mix(centerOpacity,1.0,edgeQ):1.0);", "floatcoverage=materialOpacity*mix(centerOpacity,1.0,edgeQ);"),
    ("LG_OUT=surface*(mask*opacity*coverage);", "fragColor=surface*(mask*qt_Opacity*coverage);"),
]

DEAD_BLOCKS = [r"if\(darkGradientOverlay\)\{.*?\}"]

DEFAULTS = {
    "DockCornerRadius": ("qml", "cornerRadius"),
    "RefractionWidth": ("theme", "refractionWidth"),
    "MagnifyGlassStrength": ("theme", "magnifyGlassStrength"),
    "RgbDriftStrength": ("theme", "rgbDriftStrength"),
    "HighlightWidth": ("theme", "highlightWidth"),
    "HighlightStrength": ("theme", "highlightStrength"),
    "Saturation": ("theme", "saturation"),
    "MaterialOpacity": ("theme", "materialOpacity"),
}


def normalize(text):
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"\s+", "", text)


def function_body(text, name):
    match = re.search(r"(?:float|vec2|vec3|vec4|void)\s+" + name + r"\s*\([^)]*\)\s*\{", text)
    if not match:
        return None
    index = match.end()
    depth = 1
    while depth:
        char = text[index]
        depth += (char == "{") - (char == "}")
        index += 1
    return normalize(text[match.start():index])


def adapt(body):
    for original, replacement in SUBSTITUTIONS:
        body = body.replace(original, replacement)
    for pattern in DEAD_BLOCKS:
        body = re.sub(pattern, "", body, flags=re.S)
    return body


def check_shader(source_dir, port_path):
    reference = "\n".join(open(source_dir + "/shaders/" + name).read() for name in SOURCE_FILES)
    port = open(port_path).read()
    ok = True
    for name in FUNCTIONS:
        expected = function_body(reference, name)
        actual = function_body(port, name)
        if expected is None or actual is None:
            print(name, "INTROUVABLE")
            ok = False
            continue
        same = adapt(expected) == actual
        ok = ok and same
        print(name, "IDENTIQUE aux adaptations documentees pres" if same else "DIFFERENT")
    return ok


def theme_defaults(theme_path):
    text = open(theme_path).read()
    start = text.index("elementSpecs")
    block = text[start:text.index("]", start)]
    found = {}
    for key, value in re.findall(r'key:\s*"(\w+)"[^}]*?def:\s*(-?[0-9.]+)', block):
        found[key] = float(value)
    return found


def check_defaults(source_dir, qml_path, theme_path):
    kcfg = open(source_dir + "/glass.kcfg").read()
    effect = open(source_dir + "/effect.cpp").read()
    qml = open(qml_path).read()
    theme = theme_defaults(theme_path)
    ok = True
    for entry, (where, prop) in DEFAULTS.items():
        sent = re.search(r'name="' + entry + r'"[^>]*>\s*<default>\s*(-?[0-9.]+)\s*</default>', kcfg)
        if where == "qml":
            declared = re.search(r"property\s+real\s+" + prop + r":\s*(-?[0-9.]+)", qml)
            value = float(declared.group(1)) if declared else None
        else:
            value = theme.get(prop)
        if not sent or value is None:
            print(entry, "INTROUVABLE")
            ok = False
            continue
        same = float(sent.group(1)) == value
        ok = ok and same
        print(entry, sent.group(1), value, "OK" if same else "DIFFERENT")
    center = re.search(r"centerOpacity\s*=\s*dockSurface\s*\?\s*([0-9.]+)f", effect)
    value = theme.get("centerOpacity")
    same = bool(center and value is not None and float(center.group(1)) == value)
    ok = ok and same
    print("centerOpacity", center.group(1) if center else "?", value, "OK" if same else "DIFFERENT")
    return ok


def main():
    if len(sys.argv) != 5:
        print("usage: fidelity_tahoe.py ACRYLIC_GLASS_SRC_DIR TahoeGlass.frag TahoeGlass.qml Theme.qml")
        return 2
    shader_ok = check_shader(sys.argv[1], sys.argv[2])
    defaults_ok = check_defaults(sys.argv[1], sys.argv[3], sys.argv[4])
    return 0 if shader_ok and defaults_ok else 1


if __name__ == "__main__":
    sys.exit(main())
