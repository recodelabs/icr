// Campaign Dashboards static host: a Cloudflare Worker that serves the built site from
// R2. Cloudflare Pages caps files at 25 MiB, and DuckDB-WASM's two engine
// builds (~35-40 MiB each) exceed it; R2 has no such limit, and keeping the
// site next to the data hub in the same bucket keeps one thing to manage.
//
// Bucket layout (see data/README.md):
//   parquet/ tiles/ views/ manifest.json catalog.sql   ← the data hub
//   _site/campaignhq/…                                 ← this site (Framework dist/)
//
// Routing: /  → index.html, /about → about.html (Framework cleanUrls),
// everything else → the object at that path. Immutable hashed assets under
// _npm/, _import/, _observablehq/ and _file/ get a long cache; pages do not.

const SITE_PREFIX = "_site/campaignhq/";

const TYPES = {
  html: "text/html; charset=utf-8", js: "text/javascript; charset=utf-8", css: "text/css; charset=utf-8",
  json: "application/json", wasm: "application/wasm", parquet: "application/vnd.apache.parquet",
  pmtiles: "application/octet-stream", svg: "image/svg+xml", png: "image/png", jpg: "image/jpeg",
  woff2: "font/woff2", woff: "font/woff", txt: "text/plain; charset=utf-8", map: "application/json"
};

function contentType(key) {
  const ext = key.slice(key.lastIndexOf(".") + 1).toLowerCase();
  return TYPES[ext] ?? "application/octet-stream";
}

export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") return new Response("Method not allowed", {status: 405});
    const url = new URL(request.url);
    let path = decodeURIComponent(url.pathname).replace(/^\/+/, "");
    if (path === "" || path.endsWith("/")) path += "index.html";

    const candidates = [path];
    if (!path.includes(".")) candidates.push(`${path}.html`, `${path}/index.html`);

    const ranged = request.headers.has("range");
    for (const key of candidates) {
      const obj = await env.ICR.get(SITE_PREFIX + key, {range: ranged ? request.headers : undefined, onlyIf: request.headers});
      if (!obj) continue;
      const headers = new Headers();
      obj.writeHttpMetadata(headers);
      headers.set("etag", obj.httpEtag);
      headers.set("content-type", contentType(key));
      headers.set("accept-ranges", "bytes");
      const immutable = /^(_npm|_import|_observablehq|_file)\//.test(key);
      headers.set("cache-control", immutable ? "public, max-age=31536000, immutable" : "public, max-age=300");
      const partial = ranged && obj.range && "body" in obj && obj.body;
      if (partial) {
        const {offset = 0, length = obj.size - offset} = obj.range;
        headers.set("content-range", `bytes ${offset}-${offset + length - 1}/${obj.size}`);
        headers.set("content-length", String(length));
      } else if ("body" in obj && obj.body) {
        headers.set("content-length", String(obj.size));
      }
      const status = "body" in obj && obj.body ? (partial ? 206 : 200) : 304;
      const body = status === 304 || request.method === "HEAD" ? null : obj.body;
      return new Response(body, {status, headers});
    }

    const notFound = await env.ICR.get(SITE_PREFIX + "404.html");
    return new Response(notFound ? notFound.body : "Not found", {status: 404, headers: {"content-type": "text/html; charset=utf-8"}});
  }
};
