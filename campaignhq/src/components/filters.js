// Cascading pulldowns for Observable Framework pages.
//
// Inputs.select builds a plain <select> whose option values index into the
// array it was given, and the form it returns has a `value` setter and re-reads
// itself on a bubbling "input" event. That is enough to make several selects
// aware of each other: after any of them changes, recompute which choices still
// have data under the other filters, grey the rest out, and if the current
// choice is one of them, fall back and notify the reactive graph.

/**
 * Grey out the options of an Inputs.select that have no data.
 *
 * @param input   the form returned by Inputs.select
 * @param data    the array the select was built from (same order)
 * @param valid   Set of the values that still have data
 * @param keep    a value that is always enabled (the "All" choice); null if none
 * @param fallback where to go when the current value became invalid; defaults to
 *                `keep`, or to the first valid value when there is no `keep`
 * @param suffix  appended to greyed-out labels
 * @returns true if the value was changed
 */
export function constrain(input, data, valid, {keep = "All", fallback, suffix = " — none"} = {}) {
  const select = input.querySelector("select");
  if (!select) return false;
  for (const opt of select.options) {
    const v = data[+opt.value];
    const ok = v === keep || valid.has(v);
    opt.disabled = !ok;
    if (opt.dataset.label === undefined) opt.dataset.label = opt.textContent;
    opt.textContent = ok ? opt.dataset.label : opt.dataset.label + suffix;
  }
  const cur = input.value;
  if (cur === keep || valid.has(cur)) return false;
  let next = fallback !== undefined ? fallback : keep !== null ? keep : data.find((d) => valid.has(d));
  if (next === undefined) return false;
  input.value = next;
  input.dispatchEvent(new Event("input", {bubbles: true}));
  return true;
}

/** Rows of `combos` matching every filter in `filters` (a value of "All" matches anything). */
export function matching(combos, filters) {
  const entries = Object.entries(filters).filter(([, v]) => v !== "All" && v !== undefined && v !== null);
  return combos.filter((c) => entries.every(([k, v]) => c[k] === v));
}

/** Set of distinct `key` values among the combos matching `filters`. */
export function available(combos, key, filters) {
  return new Set(matching(combos, filters).map((c) => c[key]));
}
