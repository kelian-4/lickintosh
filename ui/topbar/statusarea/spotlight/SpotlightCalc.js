.pragma library

var CONSTANTS = {
    pi: Math.PI,
    tau: Math.PI * 2,
    e: Math.E,
    phi: 1.6180339887498948
}

var FUNCTIONS = {
    sqrt: Math.sqrt,
    cbrt: Math.cbrt,
    abs: Math.abs,
    sin: Math.sin,
    cos: Math.cos,
    tan: Math.tan,
    asin: Math.asin,
    acos: Math.acos,
    atan: Math.atan,
    sinh: Math.sinh,
    cosh: Math.cosh,
    tanh: Math.tanh,
    ln: Math.log,
    log: Math.log10,
    log2: Math.log2,
    exp: Math.exp,
    floor: Math.floor,
    ceil: Math.ceil,
    round: Math.round,
    sign: Math.sign
}

var MULTI_FUNCTIONS = {
    min: Math.min,
    max: Math.max,
    pow: Math.pow,
    atan2: Math.atan2,
    hypot: Math.hypot
}

function tokenize(input) {
    var tokens = []
    var i = 0
    var n = input.length
    while (i < n) {
        var c = input[i]
        if (c === " " || c === "\t") { i++; continue }
        if (c >= "0" && c <= "9" || c === ".") {
            var start = i
            while (i < n && (input[i] >= "0" && input[i] <= "9" || input[i] === ".")) i++
            if (i < n && (input[i] === "e" || input[i] === "E") && i + 1 < n && (input[i + 1] >= "0" && input[i + 1] <= "9" || input[i + 1] === "+" || input[i + 1] === "-")) {
                i++
                if (input[i] === "+" || input[i] === "-") i++
                while (i < n && input[i] >= "0" && input[i] <= "9") i++
            }
            var raw = input.slice(start, i)
            if ((raw.match(/\./g) || []).length > 1) throw new Error("Nombre invalide : " + raw)
            tokens.push({ type: "num", value: parseFloat(raw) })
            continue
        }
        if (/[a-zA-Z_]/.test(c)) {
            var start2 = i
            while (i < n && /[a-zA-Z_0-9]/.test(input[i])) i++
            tokens.push({ type: "ident", value: input.slice(start2, i).toLowerCase() })
            continue
        }
        if (c === "×") { tokens.push({ type: "op", value: "*" }); i++; continue }
        if (c === "÷") { tokens.push({ type: "op", value: "/" }); i++; continue }
        if ("+-*/^%!(),".indexOf(c) !== -1) {
            tokens.push({ type: "op", value: c })
            i++
            continue
        }
        throw new Error("Caractère non reconnu : '" + c + "'")
    }
    return tokens
}

function factorial(x) {
    if (Math.floor(x) !== x || x < 0) throw new Error("La factorielle n'est définie que pour les entiers positifs")
    if (x > 170) throw new Error("Nombre trop grand pour la factorielle")
    var r = 1
    for (var i = 2; i <= x; i++) r *= i
    return r
}

function parse(tokens) {
    var pos = 0
    function peek() { return tokens[pos] }
    function next() { return tokens[pos++] }
    function isOp(t, v) { return !!t && t.type === "op" && t.value === v }

    function parseExpression() { return parseAdditive() }

    function parseAdditive() {
        var left = parseMultiplicative()
        while (isOp(peek(), "+") || isOp(peek(), "-")) {
            var op = next().value
            var right = parseMultiplicative()
            left = op === "+" ? left + right : left - right
        }
        return left
    }

    function parseMultiplicative() {
        var left = parseImplicit()
        while (isOp(peek(), "*") || isOp(peek(), "/")) {
            var op = next().value
            var right = parseImplicit()
            if (op === "*") {
                left = left * right
            } else {
                if (right === 0) throw new Error("Division par zéro")
                left = left / right
            }
        }
        return left
    }

    function parseImplicit() {
        var left = parseUnary()
        while (peek() && (peek().type === "num" || peek().type === "ident" || isOp(peek(), "("))) {
            var right = parseUnary()
            left = left * right
        }
        return left
    }

    function parseUnary() {
        if (isOp(peek(), "-")) { next(); return -parseUnary() }
        if (isOp(peek(), "+")) { next(); return parseUnary() }
        return parsePower()
    }

    function parsePower() {
        var left = parsePostfix()
        if (isOp(peek(), "^")) {
            next()
            var right = parseUnary()
            left = Math.pow(left, right)
        }
        return left
    }

    function parsePostfix() {
        var left = parsePrimary()
        while (isOp(peek(), "!") || isOp(peek(), "%")) {
            var op = next().value
            left = op === "!" ? factorial(left) : left / 100
        }
        return left
    }

    function parsePrimary() {
        var t = peek()
        if (!t) throw new Error("Expression incomplète")
        if (t.type === "num") { next(); return t.value }
        if (isOp(t, "(")) {
            next()
            var v = parseExpression()
            if (!isOp(peek(), ")")) throw new Error("Parenthèse fermante manquante")
            next()
            return v
        }
        if (t.type === "ident") {
            next()
            if (isOp(peek(), "(")) {
                next()
                var args = [parseExpression()]
                while (isOp(peek(), ",")) { next(); args.push(parseExpression()) }
                if (!isOp(peek(), ")")) throw new Error("Parenthèse fermante manquante")
                next()
                if (FUNCTIONS.hasOwnProperty(t.value)) return FUNCTIONS[t.value](args[0])
                if (MULTI_FUNCTIONS.hasOwnProperty(t.value)) return MULTI_FUNCTIONS[t.value].apply(null, args)
                throw new Error("Fonction inconnue : " + t.value)
            }
            if (CONSTANTS.hasOwnProperty(t.value)) return CONSTANTS[t.value]
            if (FUNCTIONS.hasOwnProperty(t.value) || MULTI_FUNCTIONS.hasOwnProperty(t.value)) {
                throw new Error("'" + t.value + "' est une fonction, utilisez " + t.value + "(...)")
            }
            throw new Error("Symbole inconnu : '" + t.value + "'")
        }
        throw new Error("Expression invalide près de '" + t.value + "'")
    }

    if (tokens.length === 0) throw new Error("Expression vide")
    var result = parseExpression()
    if (pos < tokens.length) throw new Error("Caractères inattendus après l'expression : '" + tokens[pos].value + "'")
    return result
}

function formatResult(n) {
    if (typeof n !== "number" || isNaN(n)) throw new Error("Résultat indéfini")
    if (!isFinite(n)) return n > 0 ? "∞" : "-∞"
    if (Number.isInteger(n) && Math.abs(n) < 1e15) return n.toString()
    var s = n.toPrecision(12)
    if (s.indexOf("e") === -1 && s.indexOf(".") !== -1) {
        s = s.replace(/0+$/, "").replace(/\.$/, "")
    }
    return s
}

function evaluate(expr) {
    try {
        var tokens = tokenize(expr)
        var result = parse(tokens)
        return { ok: true, value: result, display: formatResult(result) }
    } catch (e) {
        return { ok: false, error: e.message || "Expression invalide" }
    }
}
