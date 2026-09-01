#!/usr/bin/env python3
"""Add bundle: .module to String(localized:) and Text("...") calls in SwiftPM module sources.
Wrap first string-literal arg of SwiftUI views/modifiers (Button, Label, etc.) in
String(localized:..., bundle: .module) since their LocalizedStringKey inits lack a bundle: param.

Usage: python3 localize.py <root_dir>...
"""
import re
import sys
from pathlib import Path


def parse_string_literal(s, start):
    """Return end index (inclusive) of matching '"' starting at s[start] == '"'. Handles escapes and \\(...) interpolation."""
    assert s[start] == '"', f"expected \" at {start}, got {s[start]!r}"
    i = start + 1
    n = len(s)
    while i < n:
        c = s[i]
        if c == '\\':
            if i + 1 < n and s[i + 1] == '(':
                depth = 1
                i += 2
                while i < n and depth > 0:
                    cc = s[i]
                    if cc == '"':
                        end = parse_string_literal(s, i)
                        if end == -1:
                            return -1
                        i = end + 1
                        continue
                    elif cc == '(':
                        depth += 1
                    elif cc == ')':
                        depth -= 1
                    i += 1
                continue
            else:
                i += 2
                continue
        if c == '"':
            return i
        i += 1
    return -1


def parse_call_args(s, open_paren_idx):
    """Return idx of matching ')'. Skips strings, comments, nested parens."""
    i = open_paren_idx + 1
    depth = 1
    n = len(s)
    while i < n:
        c = s[i]
        if c == '"':
            end = parse_string_literal(s, i)
            if end == -1:
                return -1
            i = end + 1
            continue
        elif c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                return i
        elif c == '/' and i + 1 < n and s[i + 1] == '/':
            nl = s.find('\n', i)
            if nl == -1:
                return -1
            i = nl + 1
            continue
        elif c == '/' and i + 1 < n and s[i + 1] == '*':
            close = s.find('*/', i + 2)
            if close == -1:
                return -1
            i = close + 2
            continue
        i += 1
    return -1


def wrap_first_string_arg(content, call_pattern):
    """Replace first positional string-literal arg with String(localized: ..., bundle: .module).
    Used for SwiftUI views/modifiers whose LocalizedStringKey inits lack a bundle: param."""
    out = []
    pos = 0
    while True:
        m = call_pattern.search(content, pos)
        if not m:
            out.append(content[pos:])
            break
        out.append(content[pos:m.start()])
        paren_idx = content.find('(', m.start(), m.end())
        if paren_idx == -1:
            out.append(content[m.start():m.end()])
            pos = m.end()
            continue
        i = m.end()
        while i < len(content) and content[i] in ' \t\n\r':
            i += 1
        if i >= len(content) or content[i] != '"':
            out.append(content[m.start():m.end()])
            pos = m.end()
            continue
        if content[i:i + 3] == '"""':
            end = content.find('"""', i + 3)
            if end == -1:
                out.append(content[m.start():m.end()])
                pos = m.end()
                continue
            str_end = end + 2
        else:
            str_end = parse_string_literal(content, i)
            if str_end == -1:
                out.append(content[m.start():m.end()])
                pos = m.end()
                continue
        call_end = parse_call_args(content, paren_idx)
        if call_end == -1:
            out.append(content[m.start():m.end()])
            pos = m.end()
            continue
        args_text = content[paren_idx + 1:call_end]
        if re.search(r'\bbundle:', args_text):
            out.append(content[m.start():call_end + 1])
            pos = call_end + 1
            continue
        literal = content[i:str_end + 1]
        replacement = f'String(localized: {literal}, bundle: .module)'
        new_call = content[m.start():i] + replacement + content[str_end + 1:call_end + 1]
        out.append(new_call)
        pos = call_end + 1
    return ''.join(out)


def insert_bundle(content, call_pattern, first_arg_must_be_literal=True):
    """Insert ', bundle: .module' after first string-literal arg.
    Used for String(localized:) and Text("...") which accept a bundle: parameter."""
    out = []
    pos = 0
    while True:
        m = call_pattern.search(content, pos)
        if not m:
            out.append(content[pos:])
            break
        out.append(content[pos:m.start()])
        paren_idx = content.find('(', m.start(), m.end())
        if paren_idx == -1:
            out.append(content[m.start():m.end()])
            pos = m.end()
            continue
        i = m.end()
        while i < len(content) and content[i] in ' \t\n\r':
            i += 1
        if first_arg_must_be_literal and (i >= len(content) or content[i] != '"'):
            out.append(content[m.start():m.end()])
            pos = m.end()
            continue
        if first_arg_must_be_literal:
            if content[i:i + 3] == '"""':
                end = content.find('"""', i + 3)
                if end == -1:
                    out.append(content[m.start():m.end()])
                    pos = m.end()
                    continue
                str_end = end + 2
            else:
                str_end = parse_string_literal(content, i)
                if str_end == -1:
                    out.append(content[m.start():m.end()])
                    pos = m.end()
                    continue
        else:
            str_end = i - 1
        call_end = parse_call_args(content, paren_idx)
        if call_end == -1:
            out.append(content[m.start():m.end()])
            pos = m.end()
            continue
        args_text = content[paren_idx + 1:call_end]
        if re.search(r'\bbundle:', args_text):
            out.append(content[m.start():call_end + 1])
            pos = call_end + 1
            continue
        prefix = content[m.start():str_end + 1]
        suffix = content[str_end + 1:call_end + 1]
        new_call = prefix + ', bundle: .module' + suffix
        out.append(new_call)
        pos = call_end + 1
    return ''.join(out)


STRING_LOCALIZED = re.compile(r'String\(\s*localized:\s*')
TEXT_LITERAL = re.compile(r'(?<![A-Za-z0-9_])Text\(')
WRAP_VIEW = re.compile(
    r'(?<![A-Za-z0-9_])(Button|Label|TextField|SecureField|NavigationLink|Toggle|Stepper|Picker|ContentUnavailableView|Section|Menu|Link)\('
)
WRAP_MODIFIER = re.compile(r'\.(alert|confirmationDialog|navigationTitle|navigationBarTitle)\(')


def process_file(path):
    txt = path.read_text()
    new = insert_bundle(txt, STRING_LOCALIZED)
    new = insert_bundle(new, TEXT_LITERAL)
    new = wrap_first_string_arg(new, WRAP_VIEW)
    new = wrap_first_string_arg(new, WRAP_MODIFIER)
    if new != txt:
        path.write_text(new)
        return True
    return False


def main():
    roots = sys.argv[1:]
    if not roots:
        print("usage: localize.py <root_dir>...")
        return 1
    changed = []
    for root in roots:
        for p in Path(root).rglob('*.swift'):
            parts = p.parts
            if 'Tests' in parts or '.build' in parts:
                continue
            if process_file(p):
                changed.append(str(p))
    print(f"Changed {len(changed)} files")
    for c in changed:
        print(f"  {c}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
