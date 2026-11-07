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
CYAN = "\033[36m"
RESET = "\033[0m"

if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
    BOLD = DIM = RED = GREEN = CYAN = RESET = ""

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
        raise CalcError("exponent too large")
    if isinstance(a, int) and isinstance(b, int) and b >= 0 and a != 0:
        if b * math.log2(abs(a) + 1) > 100000:
            raise CalcError("result too large")
    try:
        return a ** b
    except ZeroDivisionError:
        raise CalcError("division by zero")
    except OverflowError:
        raise CalcError("result too large")


def _div(a, b):
    if b == 0:
        raise CalcError("division by zero")
    r = a / b
    if isinstance(a, int) and isinstance(b, int) and a % b == 0:
        return a // b
    return r


def _floordiv(a, b):
    if b == 0:
        raise CalcError("division by zero")
    return a // b


def _mod(a, b):
    if b == 0:
        raise CalcError("division by zero")
    return a % b


def _fact(n):
    if isinstance(n, float) and n.is_integer():
        n = int(n)
    if not isinstance(n, int) or n < 0:
        raise CalcError("factorial needs a non-negative integer")
    if n > MAX_FACTORIAL:
        raise CalcError("factorial too large")
    return math.factorial(n)


def _log(x, base=None):
    if x <= 0:
        raise CalcError("log of a non-positive number")
    if base is None:
        return math.log(x)
    if base <= 0 or base == 1:
        raise CalcError("invalid log base")
    return math.log(x, base)


def _sqrt(x):
    if x < 0:
        raise CalcError("square root of a negative number")
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
        raise CalcError("unsupported value")
    if isinstance(node, ast.BinOp):
        op = BINARY.get(type(node.op))
        if op is None:
            raise CalcError("unsupported operator")
        return op(evaluate(node.left), evaluate(node.right))
    if isinstance(node, ast.UnaryOp):
        op = UNARY.get(type(node.op))
        if op is None:
            raise CalcError("unsupported operator")
        return op(evaluate(node.operand))
    if isinstance(node, ast.Name):
        if node.id in ("ans", "_"):
            return state.ans
        if node.id in state.variables:
            return state.variables[node.id]
        if node.id in CONSTANTS:
            return CONSTANTS[node.id]
        raise CalcError("unknown name '" + node.id + "'")
    if isinstance(node, ast.Call):
        if not isinstance(node.func, ast.Name) or node.keywords:
            raise CalcError("unsupported call")
        fn = FUNCTIONS.get(node.func.id)
        if fn is None:
            raise CalcError("unknown function '" + node.func.id + "'")
        try:
            return fn(*[evaluate(a) for a in node.args])
        except CalcError:
            raise
        except (TypeError, ValueError, OverflowError, ZeroDivisionError) as exc:
            raise CalcError(str(exc))
    raise CalcError("unsupported expression")


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


HELP = """\
Operators   + - * / // % ** ^ !   (parentheses allowed)
Constants   pi e tau phi inf      ans or _ = last result
Functions   sin cos tan asin acos atan sinh cosh tanh
            sqrt cbrt exp ln log log2 log10 abs round floor ceil
            fact gcd lcm min max sum hypot pow mod deg rad
Variables   x = 5 * 3             then use x in any expression
Commands    deg / rad   angle mode      vars   list variables
            clear       reset all       help   this text
            q / quit    leave
"""


def handle(line):
    line = line.strip()
    if not line:
        return None
    low = line.lower()
    if low in ("q", "quit", "exit"):
        raise EOFError
    if low in ("help", "?"):
        return HELP.rstrip("\n")
    if low == "deg":
        state.degrees = True
        return "angle mode: degrees"
    if low == "rad":
        state.degrees = False
        return "angle mode: radians"
    if low == "clear":
        state.variables.clear()
        state.ans = 0
        return "cleared"
    if low == "vars":
        if not state.variables:
            return "no variables"
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
            raise CalcError("invalid variable name")
        name, line = left, right

    try:
        tree = ast.parse(prepare(line.strip()), mode="eval")
    except SyntaxError:
        raise CalcError("syntax error")
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
            line = status or ""
            if len(line) > self.width() - 4:
                line = line[: self.width() - 5] + "…"
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
            self.render(buf, pos, "")
            while True:
                try:
                    data = os.read(self.fd, 64)
                except KeyboardInterrupt:
                    buf, pos = "", 0
                    self.render(buf, pos, "")
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
            print(RED + "error: " + str(exc) + RESET, file=sys.stderr)
            sys.exit(1)
        return

    print(BOLD + "Calculator" + RESET + DIM + "  live results, Tab completes, help for functions, q to quit" + RESET)
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
            print(RED + "error: " + str(exc) + RESET)
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
