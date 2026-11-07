#!/usr/bin/env python3
import ast
import math
import operator
import os
import re
import select
import shutil
import sys

try:
    import termios
    import tty
except ImportError:
    termios = None
    tty = None

try:
    import readline
except ImportError:
    readline = None

BOLD = "\033[1m"
DIM = "\033[2m"
RED = "\033[31m"
GREEN = "\033[32m"
WHITE = "\033[97m"
CYAN = "\033[36m"
RESET = "\033[0m"

if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
    BOLD = DIM = RED = GREEN = WHITE = CYAN = RESET = ""

def _read_lang():
    code = ""
    if "--lang" in sys.argv[1:]:
        i = sys.argv.index("--lang")
        if i + 1 < len(sys.argv):
            code = sys.argv[i + 1]
            del sys.argv[i:i + 2]
    code = code or os.environ.get("LK_LANG") or os.environ.get("LANG") or "en"
    code = code.split(".")[0].split("_")[0].lower()
    return code if code in ("fr", "es") else "en"


LANG = _read_lang()


TRANSLATIONS = {
    "fr": {
    'exponent too large': 'exposant trop grand',
    'result too large': 'résultat trop grand',
    'division by zero': 'division par zéro',
    'factorial needs a non-negative integer': 'la factorielle demande un entier positif ou nul',
    'factorial too large': 'factorielle trop grande',
    'log of a non-positive number': "logarithme d'un nombre négatif ou nul",
    'invalid log base': 'base de logarithme invalide',
    'square root of a negative number': "racine carrée d'un nombre négatif",
    'unsupported value': 'valeur non prise en charge',
    'unsupported operator': 'opérateur non pris en charge',
    "unknown name '{}'": "nom inconnu '{}'",
    'unsupported call': 'appel non pris en charge',
    "unknown function '{}'": "fonction inconnue '{}'",
    'unsupported expression': 'expression non prise en charge',
    'invalid variable name': 'nom de variable invalide',
    'syntax error': 'erreur de syntaxe',
    'error: ': 'erreur : ',
    'angle mode: degrees': "mode d'angle : degrés",
    'angle mode: radians': "mode d'angle : radians",
    'cleared': 'tout effacé',
    'no variables': 'aucune variable',
    "no help for '{}'": "pas d'aide pour '{}'",
    'calculator, help lists the options, q quits': 'calculatrice, help pour avoir les options, q pour quitter',
    'Operators': 'Opérateurs',
    'Constants': 'Constantes',
    'Angles': 'Angles',
    'Powers and logs': 'Puissances et logarithmes',
    'Rounding and numbers': 'Arrondis et nombres',
    'Variables': 'Variables',
    'Other': 'Autres',
    'basic arithmetic: 2+3*4': 'opérations de base : 2+3*4',
    'integer division: 7//2 = 3': 'division entière : 7//2 = 3',
    'remainder: 7%3 = 1': 'reste de la division : 7%3 = 1',
    'power: 2^10 = 1024': 'puissance : 2^10 = 1024',
    'factorial: 5! = 120': 'factorielle : 5! = 120',
    'grouping: (1+2)*3': 'regroupement : (1+2)*3',
    '3.14159...': '3,14159...',
    "Euler's number 2.71828...": "nombre d'Euler 2,71828...",
    '2*pi': '2*pi',
    'golden ratio 1.61803...': "nombre d'or 1,61803...",
    'infinity': 'infini',
    'result of the previous line': 'résultat de la ligne précédente',
    'trigonometry, uses the current angle mode': "trigonométrie, suit le mode d'angle actuel",
    'inverse trigonometry, answer in the current angle mode': "trigonométrie inverse, réponse dans le mode d'angle actuel",
    'hyperbolic functions': 'fonctions hyperboliques',
    'switch to degrees (command), or deg(x) converts radians to degrees': 'passe en degrés (commande), ou deg(x) convertit des radians en degrés',
    'switch to radians (command), or rad(x) converts degrees to radians': 'passe en radians (commande), ou rad(x) convertit des degrés en radians',
    'square root: sqrt(16) = 4': 'racine carrée : sqrt(16) = 4',
    'cube root: cbrt(27) = 3': 'racine cubique : cbrt(27) = 3',
    'e to the power x': 'e puissance x',
    'natural logarithm; log(x, b) uses base b': 'logarithme népérien ; log(x, b) utilise la base b',
    'base 2 and base 10 logarithms': 'logarithmes en base 2 et en base 10',
    'same as a^b': 'identique à a^b',
    'length of the hypotenuse: hypot(3,4) = 5': "longueur de l'hypoténuse : hypot(3,4) = 5",
    'absolute value': 'valeur absolue',
    'round to n decimals (n optional)': 'arrondit à n décimales (n facultatif)',
    'round down / up to an integer': "arrondit à l'entier inférieur / supérieur",
    'factorial, same as n!': 'factorielle, identique à n!',
    'greatest common divisor / least common multiple': 'plus grand diviseur commun / plus petit multiple commun',
    'same as a%b': 'identique à a%b',
    'smallest value: min(4, 2, 9) = 2': 'plus petite valeur : min(4, 2, 9) = 2',
    'largest value: max(4, 2, 9) = 9': 'plus grande valeur : max(4, 2, 9) = 9',
    'total of the values: sum(1, 2, 3) = 6': 'somme des valeurs : sum(1, 2, 3) = 6',
    'store a result under a name, then use x anywhere': 'range un résultat sous un nom, puis utilise x partout',
    'list your variables': 'liste tes variables',
    'forget all variables and ans': 'oublie toutes les variables et ans',
    'this list; help sqrt explains one entry': 'cette liste ; help sqrt explique une seule entrée',
    'complete the word under the cursor': 'complète le mot sous le curseur',
    'leave': 'quitter',
},
    "es": {
    'exponent too large': 'exponente demasiado grande',
    'result too large': 'resultado demasiado grande',
    'division by zero': 'división por cero',
    'factorial needs a non-negative integer': 'el factorial necesita un entero no negativo',
    'factorial too large': 'factorial demasiado grande',
    'log of a non-positive number': 'logaritmo de un número no positivo',
    'invalid log base': 'base de logaritmo no válida',
    'square root of a negative number': 'raíz cuadrada de un número negativo',
    'unsupported value': 'valor no admitido',
    'unsupported operator': 'operador no admitido',
    "unknown name '{}'": "nombre desconocido '{}'",
    'unsupported call': 'llamada no admitida',
    "unknown function '{}'": "función desconocida '{}'",
    'unsupported expression': 'expresión no admitida',
    'invalid variable name': 'nombre de variable no válido',
    'syntax error': 'error de sintaxis',
    'error: ': 'error: ',
    'angle mode: degrees': 'modo de ángulo: grados',
    'angle mode: radians': 'modo de ángulo: radianes',
    'cleared': 'todo borrado',
    'no variables': 'sin variables',
    "no help for '{}'": "sin ayuda para '{}'",
    'calculator, help lists the options, q quits': 'calculadora, help muestra las opciones, q para salir',
    'Operators': 'Operadores',
    'Constants': 'Constantes',
    'Angles': 'Ángulos',
    'Powers and logs': 'Potencias y logaritmos',
    'Rounding and numbers': 'Redondeo y números',
    'Variables': 'Variables',
    'Other': 'Otros',
    'basic arithmetic: 2+3*4': 'operaciones básicas: 2+3*4',
    'integer division: 7//2 = 3': 'división entera: 7//2 = 3',
    'remainder: 7%3 = 1': 'resto de la división: 7%3 = 1',
    'power: 2^10 = 1024': 'potencia: 2^10 = 1024',
    'factorial: 5! = 120': 'factorial: 5! = 120',
    'grouping: (1+2)*3': 'agrupación: (1+2)*3',
    '3.14159...': '3,14159...',
    "Euler's number 2.71828...": 'número de Euler 2,71828...',
    '2*pi': '2*pi',
    'golden ratio 1.61803...': 'proporción áurea 1,61803...',
    'infinity': 'infinito',
    'result of the previous line': 'resultado de la línea anterior',
    'trigonometry, uses the current angle mode': 'trigonometría, usa el modo de ángulo actual',
    'inverse trigonometry, answer in the current angle mode': 'trigonometría inversa, respuesta en el modo de ángulo actual',
    'hyperbolic functions': 'funciones hiperbólicas',
    'switch to degrees (command), or deg(x) converts radians to degrees': 'cambia a grados (comando), o deg(x) convierte radianes a grados',
    'switch to radians (command), or rad(x) converts degrees to radians': 'cambia a radianes (comando), o rad(x) convierte grados a radianes',
    'square root: sqrt(16) = 4': 'raíz cuadrada: sqrt(16) = 4',
    'cube root: cbrt(27) = 3': 'raíz cúbica: cbrt(27) = 3',
    'e to the power x': 'e elevado a x',
    'natural logarithm; log(x, b) uses base b': 'logaritmo natural; log(x, b) usa la base b',
    'base 2 and base 10 logarithms': 'logaritmos en base 2 y base 10',
    'same as a^b': 'igual que a^b',
    'length of the hypotenuse: hypot(3,4) = 5': 'longitud de la hipotenusa: hypot(3,4) = 5',
    'absolute value': 'valor absoluto',
    'round to n decimals (n optional)': 'redondea a n decimales (n opcional)',
    'round down / up to an integer': 'redondea al entero inferior / superior',
    'factorial, same as n!': 'factorial, igual que n!',
    'greatest common divisor / least common multiple': 'máximo común divisor / mínimo común múltiplo',
    'same as a%b': 'igual que a%b',
    'smallest value: min(4, 2, 9) = 2': 'valor más pequeño: min(4, 2, 9) = 2',
    'largest value: max(4, 2, 9) = 9': 'valor más grande: max(4, 2, 9) = 9',
    'total of the values: sum(1, 2, 3) = 6': 'suma de los valores: sum(1, 2, 3) = 6',
    'store a result under a name, then use x anywhere': 'guarda un resultado con un nombre y úsalo después en cualquier parte',
    'list your variables': 'lista tus variables',
    'forget all variables and ans': 'olvida todas las variables y ans',
    'this list; help sqrt explains one entry': 'esta lista; help sqrt explica una sola entrada',
    'complete the word under the cursor': 'completa la palabra bajo el cursor',
    'leave': 'salir',
},
}


def t(text):
    return TRANSLATIONS.get(LANG, {}).get(text, text)


MAX_EXPONENT = 10000
MAX_FACTORIAL = 2000


class CalcError(Exception):
    pass


class State:
    def __init__(self):
        self.degrees = False
        self.variables = {}
        self.ans = 0

    def angle_in(self, x):
        return math.radians(x) if self.degrees else x

    def angle_out(self, x):
        return math.degrees(x) if self.degrees else x


state = State()


def _pow(a, b):
    if isinstance(b, int) and abs(b) > MAX_EXPONENT:
        raise CalcError(t("exponent too large"))
    if isinstance(a, int) and isinstance(b, int) and b >= 0 and a != 0:
        if b * math.log2(abs(a) + 1) > 100000:
            raise CalcError(t("result too large"))
    try:
        return a ** b
    except ZeroDivisionError:
        raise CalcError(t("division by zero"))
    except OverflowError:
        raise CalcError(t("result too large"))


def _div(a, b):
    if b == 0:
        raise CalcError(t("division by zero"))
    r = a / b
    if isinstance(a, int) and isinstance(b, int) and a % b == 0:
        return a // b
    return r


def _floordiv(a, b):
    if b == 0:
        raise CalcError(t("division by zero"))
    return a // b


def _mod(a, b):
    if b == 0:
        raise CalcError(t("division by zero"))
    return a % b


def _fact(n):
    if isinstance(n, float) and n.is_integer():
        n = int(n)
    if not isinstance(n, int) or n < 0:
        raise CalcError(t("factorial needs a non-negative integer"))
    if n > MAX_FACTORIAL:
        raise CalcError(t("factorial too large"))
    return math.factorial(n)


def _log(x, base=None):
    if x <= 0:
        raise CalcError(t("log of a non-positive number"))
    if base is None:
        return math.log(x)
    if base <= 0 or base == 1:
        raise CalcError(t("invalid log base"))
    return math.log(x, base)


def _sqrt(x):
    if x < 0:
        raise CalcError(t("square root of a negative number"))
    return math.sqrt(x)


def _cbrt(x):
    return math.copysign(abs(x) ** (1 / 3), x)


def _round(x, n=0):
    return round(x, int(n)) if n else int(round(x))


BINARY = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: _div,
    ast.FloorDiv: _floordiv,
    ast.Mod: _mod,
    ast.Pow: _pow,
    ast.BitXor: _pow,
}

UNARY = {
    ast.UAdd: operator.pos,
    ast.USub: operator.neg,
}

CONSTANTS = {
    "pi": math.pi,
    "e": math.e,
    "tau": math.tau,
    "phi": (1 + math.sqrt(5)) / 2,
    "inf": math.inf,
}

FUNCTIONS = {
    "sin": lambda x: math.sin(state.angle_in(x)),
    "cos": lambda x: math.cos(state.angle_in(x)),
    "tan": lambda x: math.tan(state.angle_in(x)),
    "asin": lambda x: state.angle_out(math.asin(x)),
    "acos": lambda x: state.angle_out(math.acos(x)),
    "atan": lambda x: state.angle_out(math.atan(x)),
    "sinh": math.sinh,
    "cosh": math.cosh,
    "tanh": math.tanh,
    "sqrt": _sqrt,
    "cbrt": _cbrt,
    "exp": math.exp,
    "ln": _log,
    "log": _log,
    "log2": lambda x: _log(x, 2),
    "log10": lambda x: _log(x, 10),
    "abs": abs,
    "round": _round,
    "floor": math.floor,
    "ceil": math.ceil,
    "fact": _fact,
    "factorial": _fact,
    "gcd": math.gcd,
    "lcm": math.lcm,
    "min": min,
    "max": max,
    "sum": lambda *a: sum(a),
    "deg": math.degrees,
    "rad": math.radians,
    "pow": _pow,
    "mod": _mod,
    "hypot": math.hypot,
}


def evaluate(node):
    if isinstance(node, ast.Expression):
        return evaluate(node.body)
    if isinstance(node, ast.Constant):
        if isinstance(node.value, (int, float)) and not isinstance(node.value, bool):
            return node.value
        raise CalcError(t("unsupported value"))
    if isinstance(node, ast.BinOp):
        op = BINARY.get(type(node.op))
        if op is None:
            raise CalcError(t("unsupported operator"))
        return op(evaluate(node.left), evaluate(node.right))
    if isinstance(node, ast.UnaryOp):
        op = UNARY.get(type(node.op))
        if op is None:
            raise CalcError(t("unsupported operator"))
        return op(evaluate(node.operand))
    if isinstance(node, ast.Name):
        if node.id in ("ans", "_"):
            return state.ans
        if node.id in state.variables:
            return state.variables[node.id]
        if node.id in CONSTANTS:
            return CONSTANTS[node.id]
        raise CalcError(t("unknown name '{}'").format(node.id))
    if isinstance(node, ast.Call):
        if not isinstance(node.func, ast.Name) or node.keywords:
            raise CalcError(t("unsupported call"))
        fn = FUNCTIONS.get(node.func.id)
        if fn is None:
            raise CalcError(t("unknown function '{}'").format(node.func.id))
        try:
            return fn(*[evaluate(a) for a in node.args])
        except CalcError:
            raise
        except (TypeError, ValueError, OverflowError, ZeroDivisionError) as exc:
            raise CalcError(str(exc))
    raise CalcError(t("unsupported expression"))


def prepare(text):
    text = text.replace("^", "**").replace("×", "*").replace("÷", "/").replace("−", "-").replace("π", "pi")
    text = text.replace(",", ".") if "(" not in text and text.count(",") == 1 else text
    out = []
    i = 0
    while i < len(text):
        c = text[i]
        if c == "!" and (i + 1 >= len(text) or text[i + 1] != "="):
            j = len(out)
            depth = 0
            k = j - 1
            while k >= 0:
                ch = out[k]
                if ch == ")":
                    depth += 1
                elif ch == "(":
                    depth -= 1
                    if depth == 0:
                        k -= 1
                        while k >= 0 and (out[k].isalnum() or out[k] == "_"):
                            k -= 1
                        k += 1
                        break
                elif depth == 0 and not (ch.isalnum() or ch in "._"):
                    k += 1
                    break
                k -= 1
            if k < 0:
                k = 0
            operand = "".join(out[k:])
            del out[k:]
            out.extend("fact(" + operand + ")")
        else:
            out.append(c)
        i += 1
    return "".join(out)


def fmt(value):
    if isinstance(value, bool):
        return str(int(value))
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if math.isnan(value):
            return "nan"
        if math.isinf(value):
            return "inf" if value > 0 else "-inf"
        if value.is_integer() and abs(value) < 1e15:
            return str(int(value))
        return format(value, ".12g")
    return str(value)


DOCS = [
    ("Operators", [
        ("+  -  *  /", "basic arithmetic: 2+3*4"),
        ("//", "integer division: 7//2 = 3"),
        ("%", "remainder: 7%3 = 1"),
        ("^  **", "power: 2^10 = 1024"),
        ("!", "factorial: 5! = 120"),
        ("( )", "grouping: (1+2)*3"),
    ]),
    ("Constants", [
        ("pi", "3.14159..."),
        ("e", "Euler's number 2.71828..."),
        ("tau", "2*pi"),
        ("phi", "golden ratio 1.61803..."),
        ("inf", "infinity"),
        ("ans  _", "result of the previous line"),
    ]),
    ("Angles", [
        ("sin cos tan", "trigonometry, uses the current angle mode"),
        ("asin acos atan", "inverse trigonometry, answer in the current angle mode"),
        ("sinh cosh tanh", "hyperbolic functions"),
        ("deg", "switch to degrees (command), or deg(x) converts radians to degrees"),
        ("rad", "switch to radians (command), or rad(x) converts degrees to radians"),
    ]),
    ("Powers and logs", [
        ("sqrt(x)", "square root: sqrt(16) = 4"),
        ("cbrt(x)", "cube root: cbrt(27) = 3"),
        ("exp(x)", "e to the power x"),
        ("ln(x)  log(x)", "natural logarithm; log(x, b) uses base b"),
        ("log2(x)  log10(x)", "base 2 and base 10 logarithms"),
        ("pow(a, b)", "same as a^b"),
        ("hypot(a, b)", "length of the hypotenuse: hypot(3,4) = 5"),
    ]),
    ("Rounding and numbers", [
        ("abs(x)", "absolute value"),
        ("round(x, n)", "round to n decimals (n optional)"),
        ("floor(x)  ceil(x)", "round down / up to an integer"),
        ("fact(n)", "factorial, same as n!"),
        ("gcd(a, b)  lcm(a, b)", "greatest common divisor / least common multiple"),
        ("mod(a, b)", "same as a%b"),
        ("min(a, b, ...)", "smallest value: min(4, 2, 9) = 2"),
        ("max(a, b, ...)", "largest value: max(4, 2, 9) = 9"),
        ("sum(a, b, ...)", "total of the values: sum(1, 2, 3) = 6"),
    ]),
    ("Variables", [
        ("x = 5*3", "store a result under a name, then use x anywhere"),
        ("vars", "list your variables"),
        ("clear", "forget all variables and ans"),
    ]),
    ("Other", [
        ("help", "this list; help sqrt explains one entry"),
        ("Tab", "complete the word under the cursor"),
        ("q  quit", "leave"),
    ]),
]


def help_text(topic=None):
    if topic:
        needle = topic.lower()
        hits = []
        for _, rows in DOCS:
            for names, text in rows:
                words = re.findall(r"[A-Za-z_]+|[^\sA-Za-z_,()]+", names.lower())
                if needle in words or needle == names.lower():
                    hits.append(names + "  -  " + t(text))
        return "\n".join(hits) if hits else t("no help for '{}'").format(topic)
    width = max(len(n) for _, rows in DOCS for n, _ in rows)
    out = []
    for title, rows in DOCS:
        out.append(BOLD + t(title) + RESET)
        for names, text in rows:
            out.append("  " + CYAN + names.ljust(width) + RESET + "  " + t(text))
        out.append("")
    return "\n".join(out).rstrip("\n")


def handle(line):
    line = line.strip()
    if not line:
        return None
    low = line.lower()
    if low in ("q", "quit", "exit"):
        raise EOFError
    if low in ("help", "?"):
        return help_text()
    if low.startswith("help "):
        return help_text(line[5:].strip())
    if low == "deg":
        state.degrees = True
        return t("angle mode: degrees")
    if low == "rad":
        state.degrees = False
        return t("angle mode: radians")
    if low == "clear":
        state.variables.clear()
        state.ans = 0
        return t("cleared")
    if low == "vars":
        if not state.variables:
            return t("no variables")
        return "\n".join(k + " = " + fmt(v) for k, v in sorted(state.variables.items()))

    name, value = compute(line)
    state.ans = value
    if name is not None:
        state.variables[name] = value
        return name + " = " + fmt(value)
    return fmt(value)


def compute(line):
    name = None
    if "=" in line and "==" not in line:
        left, right = line.split("=", 1)
        left = left.strip()
        if not left.isidentifier() or left in CONSTANTS or left in FUNCTIONS or left in ("ans", "_"):
            raise CalcError(t("invalid variable name"))
        name, line = left, right

    try:
        tree = ast.parse(prepare(line.strip()), mode="eval")
    except SyntaxError:
        raise CalcError(t("syntax error"))
    return name, evaluate(tree)


COMMANDS = ["help", "deg", "rad", "vars", "clear", "quit"]
WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*$")


def candidates(word):
    pool = [f + "(" for f in FUNCTIONS] + list(CONSTANTS) + list(state.variables) + ["ans"] + COMMANDS
    found = sorted({c for c in pool if c.startswith(word) and c != word}, key=lambda c: (len(c), c))
    return found


def common_prefix(items):
    if not items:
        return ""
    return os.path.commonprefix(items)


def preview(text):
    text = text.strip()
    if not text or text.lower() in COMMANDS or text.lower() in ("q", "exit", "?"):
        return None
    try:
        name, value = compute(text)
    except (CalcError, RecursionError, MemoryError):
        return None
    shown = fmt(value)
    return (name + " = " + shown) if name else "= " + shown


ANSI = re.compile(r"\x1b\[[0-9;]*m")


def clip(text, limit):
    out = []
    seen = 0
    i = 0
    while i < len(text):
        m = ANSI.match(text, i)
        if m:
            out.append(m.group(0))
            i = m.end()
            continue
        if seen >= limit:
            out.append(RESET)
            break
        out.append(text[i])
        seen += 1
        i += 1
    return "".join(out)


class LiveInput:
    def __init__(self, history):
        self.history = history
        self.fd = sys.stdin.fileno()
        self.prompt_width = 2

    def width(self):
        return max(20, shutil.get_terminal_size((80, 24)).columns - 1)

    def render(self, buf, pos, status, final=False):
        out = ["\r\033[J", CYAN + "> " + RESET, buf]
        word = WORD.search(buf[:pos]) if pos == len(buf) else None
        ghost = ""
        if word and not final:
            options = candidates(word.group(0))
            if options:
                ghost = options[0][len(word.group(0)):]
        if ghost:
            out.append(DIM + ghost + RESET)
        if not final:
            line = clip(status or "", self.width() - 2)
            out.append("\n" + line + "\033[A\r")
            col = self.prompt_width + len(buf[:pos])
            if col:
                out.append("\033[" + str(col) + "C")
        sys.stdout.write("".join(out))
        sys.stdout.flush()
        return ghost

    def status_for(self, buf, pos):
        word = WORD.search(buf[:pos]) if pos == len(buf) else None
        result = preview(buf)
        parts = []
        if result is not None:
            parts.append(GREEN + result + RESET)
        if word:
            options = candidates(word.group(0))
            if len(options) > 1:
                parts.append(DIM + "  " + "  ".join(options[:8]) + RESET)
        return "  ".join(parts)

    def readline(self):
        old = termios.tcgetattr(self.fd)
        buf = ""
        pos = 0
        hist_index = len(self.history)
        draft = ""
        try:
            tty.setcbreak(self.fd)
            self.render(buf, pos, self.status_for(buf, pos))
            while True:
                try:
                    data = os.read(self.fd, 64)
                except KeyboardInterrupt:
                    buf, pos = "", 0
                    self.render(buf, pos, self.status_for(buf, pos))
                    continue
                if not data:
                    raise EOFError
                text = data.decode("utf-8", "ignore")
                i = 0
                while i < len(text):
                    c = text[i]
                    i += 1
                    if c == "\x1b":
                        seq = ""
                        if i >= len(text) and select.select([self.fd], [], [], 0.02)[0]:
                            text += os.read(self.fd, 16).decode("utf-8", "ignore")
                        if i < len(text) and text[i] in "[O":
                            seq = text[i]
                            i += 1
                            while i < len(text):
                                seq += text[i]
                                i += 1
                                if text[i - 1].isalpha() or text[i - 1] == "~":
                                    break
                        if seq in ("[A", "OA"):
                            if hist_index == len(self.history):
                                draft = buf
                            if hist_index > 0:
                                hist_index -= 1
                                buf = self.history[hist_index]
                                pos = len(buf)
                        elif seq in ("[B", "OB"):
                            if hist_index < len(self.history):
                                hist_index += 1
                                buf = draft if hist_index == len(self.history) else self.history[hist_index]
                                pos = len(buf)
                        elif seq in ("[C", "OC"):
                            if pos < len(buf):
                                pos += 1
                            else:
                                buf, pos = self.accept(buf, pos)
                        elif seq in ("[D", "OD"):
                            pos = max(0, pos - 1)
                        elif seq in ("[H", "OH", "[1~", "[7~"):
                            pos = 0
                        elif seq in ("[F", "OF", "[4~", "[8~"):
                            pos = len(buf)
                        elif seq == "[3~":
                            buf = buf[:pos] + buf[pos + 1:]
                    elif c in "\r\n":
                        self.render(buf, pos, "", final=True)
                        sys.stdout.write("\n")
                        sys.stdout.flush()
                        return buf
                    elif c in "\x7f\x08":
                        if pos > 0:
                            buf = buf[: pos - 1] + buf[pos:]
                            pos -= 1
                    elif c == "\t":
                        buf, pos = self.complete(buf, pos)
                    elif c == "\x01":
                        pos = 0
                    elif c == "\x05":
                        pos = len(buf)
                    elif c == "\x15":
                        buf = buf[pos:]
                        pos = 0
                    elif c == "\x0b":
                        buf = buf[:pos]
                    elif c == "\x17":
                        head = buf[:pos].rstrip()
                        cut = max(head.rfind(" "), -1) + 1
                        buf = buf[:cut] + buf[pos:]
                        pos = cut
                    elif c == "\x0c":
                        sys.stdout.write("\033[2J\033[H")
                    elif c == "\x04":
                        if not buf:
                            self.render("", 0, "", final=True)
                            sys.stdout.write("\n")
                            raise EOFError
                    elif c == "\x03":
                        buf, pos = "", 0
                    elif c >= " " and c.isprintable():
                        buf = buf[:pos] + c + buf[pos:]
                        pos += 1
                self.render(buf, pos, self.status_for(buf, pos))
        finally:
            termios.tcsetattr(self.fd, termios.TCSADRAIN, old)

    def accept(self, buf, pos):
        word = WORD.search(buf[:pos])
        if not word:
            return buf, pos
        options = candidates(word.group(0))
        if not options:
            return buf, pos
        add = options[0][len(word.group(0)):]
        return buf + add, pos + len(add)

    def complete(self, buf, pos):
        word = WORD.search(buf[:pos])
        if not word:
            return buf, pos
        options = candidates(word.group(0))
        if not options:
            return buf, pos
        if len(options) == 1:
            add = options[0][len(word.group(0)):]
        else:
            add = common_prefix(options)[len(word.group(0)):]
            if not add:
                add = options[0][len(word.group(0)):]
        return buf[:pos] + add + buf[pos:], pos + len(add)


def setup_history():
    if readline is None:
        return None
    base = os.environ.get("XDG_CACHE_HOME") or os.path.join(os.path.expanduser("~"), ".cache")
    folder = os.path.join(base, "lickintosh")
    path = os.path.join(folder, "calc_history")
    try:
        os.makedirs(folder, exist_ok=True)
        readline.read_history_file(path)
    except (OSError, FileNotFoundError):
        pass
    readline.set_history_length(500)
    return path


def read_history_lines(path):
    if path is None:
        return []
    try:
        with open(path, encoding="utf-8") as fh:
            return [ln.rstrip("\n") for ln in fh if ln.strip()][-500:]
    except OSError:
        return []


def write_history_lines(path, entries):
    if path is None:
        return
    try:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("\n".join(entries[-500:]) + "\n")
    except OSError:
        pass


def main():
    history = setup_history()
    if len(sys.argv) > 1:
        try:
            result = handle(" ".join(sys.argv[1:]))
            if result is not None:
                print(result)
        except CalcError as exc:
            print(RED + t("error: ") + str(exc) + RESET, file=sys.stderr)
            sys.exit(1)
        return

    print(WHITE + t("calculator, help lists the options, q quits") + RESET)
    live = termios is not None and sys.stdin.isatty() and sys.stdout.isatty()
    entries = []
    if live:
        entries = read_history_lines(history)
        editor = LiveInput(entries)
    prompt = CYAN + "> " + RESET
    if readline is not None:
        prompt = "\001" + CYAN + "\002> \001" + RESET + "\002"
    while True:
        try:
            if live:
                line = editor.readline()
            else:
                line = input(prompt)
        except EOFError:
            print()
            break
        except KeyboardInterrupt:
            print()
            continue
        if live and line.strip() and (not entries or entries[-1] != line):
            entries.append(line)
        try:
            result = handle(line)
        except EOFError:
            break
        except CalcError as exc:
            print(RED + t("error: ") + str(exc) + RESET)
            continue
        if result is not None:
            print(result)
    if live:
        write_history_lines(history, entries)
    elif history is not None:
        try:
            readline.write_history_file(history)
        except OSError:
            pass


if __name__ == "__main__":
    main()
