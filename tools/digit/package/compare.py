#!/usr/bin/env python3
"""Compare the resources of an `import run` output folder with transform.py's output.

  python3 -I compare.py --new OUT --ref REF --type Location \
      [--where PATH=VALUE[,VALUE...]] [--where PATH^=PREFIX] [--known FILE | --no-known] [--examples N]

Reads OUT/<Type>.ndjson and REF/<Type>.ndjson. --where selects the resources compared, on both
sides (repeat it: all must hold). PATH is a dotted path of element names; arrays on the way are
gone through, and the condition holds when any value there matches: `type.coding.code=admin-unit`.

Reports the counts on each side, the ids only on one side, and for ids on both sides how many
are equal as JSON values; for the others, each differing path (array indexes as []) with how
many resources differ there and a few example ids. Differences listed in the known-differences
file (default: known-differences.toml beside this script) are counted apart, by their entry, and
do not count as differing. Also reports whether the ids common to both come in the same order.

Exits 0 when nothing differs beyond the known differences, 1 otherwise, 2 on a usage error.
Only the new side is indexed in memory (id and byte offset); the reference is read as a stream.
"""
import argparse
import collections
import json
import os
import re
import sys
import tomllib

HERE = os.path.dirname(os.path.abspath(__file__))


def usage(message):
    print(f"compare.py: {message}", file=sys.stderr)
    sys.exit(2)


def values_at(v, path):
    """The values at a dotted path, going through arrays."""
    cur = [v]
    for name in path:
        nxt = []
        for x in cur:
            if isinstance(x, list):
                x_items = x
            else:
                x_items = [x]
            for y in x_items:
                if isinstance(y, dict) and name in y:
                    z = y[name]
                    nxt.extend(z if isinstance(z, list) else [z])
        cur = nxt
    return cur


def condition(text):
    """`PATH=V1,V2` or `PATH^=PREFIX` as a test on a resource."""
    m = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_.]*)(\^=|=)(.*)", text)
    if not m:
        usage(f"--where {text!r}: give PATH=VALUE[,VALUE] or PATH^=PREFIX")
    path, op, value = m.group(1).split("."), m.group(2), m.group(3)
    if op == "=":
        wanted = set(value.split(","))
        return lambda r: any(isinstance(x, str) and x in wanted for x in values_at(r, path))
    return lambda r: any(isinstance(x, str) and x.startswith(value) for x in values_at(r, path))


def same(a, b):
    """JSON value equality: numbers by value, booleans apart from numbers."""
    if isinstance(a, bool) or isinstance(b, bool):
        return isinstance(a, bool) and isinstance(b, bool) and a == b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return a == b
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return type(a) is type(b) and a == b


MISSING = object()


def diff(ref, new, path, out):
    """Appends (path, kind, ref value, new value) for each difference. kind is `changed`,
    `only in reference` or `only in new`. An array missing on one side counts as empty, so
    each of its items is a difference of its own."""
    if isinstance(ref, dict) and isinstance(new, dict):
        for k in list(ref) + [k for k in new if k not in ref]:
            r, n = ref.get(k, MISSING), new.get(k, MISSING)
            if r is MISSING and isinstance(n, list):
                r = []
            if n is MISSING and isinstance(r, list):
                n = []
            diff(r, n, f"{path}.{k}" if path else k, out)
        return
    if isinstance(ref, list) and isinstance(new, list):
        for i in range(max(len(ref), len(new))):
            r = ref[i] if i < len(ref) else MISSING
            n = new[i] if i < len(new) else MISSING
            diff(r, n, f"{path}[{i}]", out)
        return
    if ref is MISSING:
        out.append((path, "only in new", None, new))
    elif new is MISSING:
        out.append((path, "only in reference", ref, None))
    elif not same(ref, new):
        out.append((path, "changed", ref, new))


def general(path):
    return re.sub(r"\[\d+\]", "[]", path)


def short(v, n=90):
    s = json.dumps(v, ensure_ascii=False, separators=(",", ":"))
    return s if len(s) <= n else s[: n - 3] + "..."


class Known:
    """The known-differences file: [[difference]] entries, each with `reason`."""

    KINDS = {"reference": "only in reference", "new": "only in new", "changed": "changed"}

    def __init__(self, path, rtype):
        self.entries = []
        self.order = None
        if not path:
            return
        with open(path, "rb") as f:
            data = tomllib.load(f)
        unknown = set(data) - {"difference"}
        if unknown:
            usage(f"{path}: unknown keys {sorted(unknown)}")
        for i, e in enumerate(data.get("difference", [])):
            bad = set(e) - {"name", "resource", "path", "kind", "match", "order", "reason"}
            if bad or "reason" not in e or "name" not in e or "resource" not in e:
                usage(f"{path}: difference {i + 1}: needs name, resource and "
                                 f"reason, with path (and kind, match) or order = true; unknown {sorted(bad)}")
            if e["resource"] != rtype:
                continue
            if e.get("order"):
                self.order = e
                continue
            if "path" not in e:
                usage(f"{path}: difference {e['name']!r} needs path or order = true")
            if e.get("kind") and e["kind"] not in self.KINDS:
                usage(f"{path}: difference {e['name']!r}: kind is reference, new or changed")
            self.entries.append(e)

    def which(self, path, kind, ref, new):
        """The entry that explains a difference, if one does."""
        for e in self.entries:
            if general(path) != e["path"]:
                continue
            if e.get("kind") and self.KINDS[e["kind"]] != kind:
                continue
            value = ref if kind == "only in reference" else new
            match = e.get("match")
            if match:
                if not isinstance(value, dict):
                    continue
                if not all(value.get(k) in (v if isinstance(v, list) else [v]) for k, v in match.items()):
                    continue
            return e
        return None


def index(path, keep):
    """id -> byte offset of each selected resource of an NDJSON file, the ids in file order,
    the count of lines read, and the ids found more than once."""
    at, order, dups, lines = {}, [], collections.Counter(), 0
    with open(path, "rb") as f:
        while True:
            offset = f.tell()
            line = f.readline()
            if not line:
                break
            if not line.strip():
                continue
            lines += 1
            r = json.loads(line)
            if not keep(r):
                continue
            rid = r.get("id")
            if rid in at:
                dups[rid] += 1
                continue
            at[rid] = offset
            order.append(rid)
    return at, order, lines, dups


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--new", required=True, help="the import run's --out folder")
    ap.add_argument("--ref", required=True, help="transform.py's output folder")
    ap.add_argument("--type", required=True, help="the resource type, such as Location")
    ap.add_argument("--where", action="append", default=[], help="PATH=V1,V2 or PATH^=PREFIX")
    ap.add_argument("--known", default=os.path.join(HERE, "known-differences.toml"))
    ap.add_argument("--no-known", action="store_true", help="count every difference")
    ap.add_argument("--examples", type=int, default=3, help="example ids per difference (3)")
    a = ap.parse_args()

    tests = [condition(w) for w in a.where]
    keep = lambda r: all(t(r) for t in tests)
    known = Known(None if a.no_known else a.known, a.type)
    new_path = os.path.join(a.new, a.type + ".ndjson")
    ref_path = os.path.join(a.ref, a.type + ".ndjson")
    for p in (new_path, ref_path):
        if not os.path.isfile(p):
            usage(f"{p}: no such file")

    new_at, new_order, new_lines, new_dups = index(new_path, keep)
    ref_order, ref_dups, ref_lines = [], collections.Counter(), 0
    seen = set()
    only_ref = []
    equal = 0
    explained = collections.Counter()   # entry name -> resources whose differences it explains (in part)
    explained_only = 0                   # resources equal but for known differences
    differing = 0
    groups = collections.OrderedDict()   # (general path, kind) -> [count, example ids, example values]
    with open(new_path, "rb") as nf, open(ref_path, "rb") as rf:
        for line in rf:
            if not line.strip():
                continue
            ref_lines += 1
            r = json.loads(line)
            if not keep(r):
                continue
            rid = r.get("id")
            if rid in seen:
                ref_dups[rid] += 1
                continue
            seen.add(rid)
            ref_order.append(rid)
            if rid not in new_at:
                only_ref.append(rid)
                continue
            nf.seek(new_at[rid])
            n = json.loads(nf.readline())
            found = []
            diff(r, n, "", found)
            if not found:
                equal += 1
                continue
            left, names = [], set()
            for d in found:
                e = known.which(*d)
                if e:
                    names.add(e["name"])
                else:
                    left.append(d)
            for name in names:
                explained[name] += 1
            if not left:
                explained_only += 1
                continue
            differing += 1
            for path, kind, rv, nv in left:
                g = groups.setdefault((general(path), kind), [0, [], []])
                g[0] += 1
                if len(g[1]) < a.examples and rid not in g[1]:
                    g[1].append(rid)
                    g[2].append((rv, nv))
    only_new = [i for i in new_order if i not in seen]

    common_ref = [i for i in ref_order if i in new_at]
    common_new = [i for i in new_order if i in seen]
    order_same = common_ref == common_new
    first = next((k for k, (x, y) in enumerate(zip(common_ref, common_new)) if x != y), None)

    sel = " where " + " and ".join(a.where) if a.where else ""
    print(f"{a.type}{sel}")
    print(f"  reference: {len(ref_order)} of {ref_lines} ({ref_path})")
    print(f"  new:       {len(new_order)} of {new_lines} ({new_path})")
    for side, d in (("reference", ref_dups), ("new", new_dups)):
        if d:
            print(f"  ids more than once in {side}: {len(d)} ({sum(d.values())} extra lines), "
                  f"e.g. {', '.join(list(d)[:a.examples])}")
    print(f"  only in reference: {len(only_ref)}" + (f", e.g. {', '.join(only_ref[:a.examples])}" if only_ref else ""))
    print(f"  only in new:       {len(only_new)}" + (f", e.g. {', '.join(only_new[:a.examples])}" if only_new else ""))
    both = len(common_ref)
    print(f"  in both: {both}: {equal} equal, {explained_only} equal but for known differences, {differing} differ")
    for name, count in explained.items():
        e = next(x for x in known.entries if x["name"] == name)
        print(f"    known: {name}: {count} resources ({e['reason']})")
    for (path, kind), (count, ids, vals) in groups.items():
        print(f"    {path} ({kind}): {count} resources, e.g.")
        for rid, (rv, nv) in zip(ids, vals):
            print(f"      {rid}: reference {short(rv)}, new {short(nv)}")
    order_known = False
    if order_same:
        print("  order of the ids in both: the same")
    else:
        where = f"first at #{first + 1}: reference {common_ref[first]}, new {common_new[first]}" if first is not None else ""
        if known.order:
            order_known = True
            print(f"  order of the ids in both: differs ({where}); known: {known.order['name']} ({known.order['reason']})")
        else:
            print(f"  order of the ids in both: differs ({where})")
    bad = only_ref or only_new or differing or ref_dups or new_dups or (not order_same and not order_known)
    print("  result: " + ("DIFFERENT" if bad else "the same, but for the known differences listed"
                           if explained_only or order_known else "the same"))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
