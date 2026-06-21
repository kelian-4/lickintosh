#!/usr/bin/env python3
import sys
import math

print("=== CLI Calculator ===")
print("Type 'q' to quit.")

while True:
    try:
        expr = input("> ")
        if expr.lower() in ('q', 'quit', 'exit'):
            break
        # Safe eval-ish with math functions
        result = eval(expr, {"__builtins__": None}, {
            "sin": math.sin, "cos": math.cos, "tan": math.tan,
            "sqrt": math.sqrt, "pi": math.pi, "e": math.e,
            "pow": pow, "log": math.log
        })
        print(f"Result: {result}")
    except Exception as e:
        print(f"Error: {e}")
