// ICR SDI: a Cloudflare Worker that exposes the `icr` R2 bucket as a Portolan
// catalog at https://sdi.healthcampaigns.org. Same serving pattern as the
// campaignhq / odklocations Workers, minus the site conventions and plus what
// the Portolan spec requires of a host (core.md, "Data Storage"): HTTP range
// requests with Accept-Ranges/206, accurate Content-Length on HEAD, and CORS
// that lets a browser read metadata and data directly.
//
// The SDI is the location registry only. The bucket also holds the campaign
// view tables, the dashboards and the DuckDB catalog (see data/README.md);
// those are ICR-internal and are not served here — only what the Portolan
// catalog links to:
//   catalog.json README.md AGENTS.md versions.json   ← the catalog root
//   parquet/{catalog,README,AGENTS}.*                ← the tables sub-catalog
//   parquet/locations/**                             ← the collection (metadata + GeoParquet)
//   tiles/*.pmtiles                                  ← MapLibre tiles of the same locations
//
// Routing: /  → the Portolan browser opened on this catalog; everything else →
// the object at that path. Objects change in place on each refresh, so nothing
// is cached for long; ETag + conditional requests do the revalidation.

const CATALOG_URL = "https://sdi.healthcampaigns.org/catalog.json";
const BROWSER = "https://browser.portolan-sdi.org/#/external/";
const SERVED = /^(catalog\.json|README\.md|AGENTS\.md|versions\.json|parquet\/(catalog\.json|README\.md|AGENTS\.md|locations\/.+)|tiles\/[^/]+\.pmtiles)$/;
const HIDDEN = /(^|\/)\./;

const TYPES = {
  json: "application/json", geojson: "application/geo+json", parquet: "application/vnd.apache.parquet",
  pmtiles: "application/vnd.pmtiles", md: "text/markdown; charset=utf-8", sql: "text/plain; charset=utf-8",
  txt: "text/plain; charset=utf-8", csv: "text/csv; charset=utf-8", png: "image/png", jpg: "image/jpeg",
  webp: "image/webp", svg: "image/svg+xml", html: "text/html; charset=utf-8"
};

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, HEAD, OPTIONS",
  "access-control-allow-headers": "Range, If-Match, If-Modified-Since, If-None-Match, If-Unmodified-Since, Content-Type",
  "access-control-expose-headers": "Content-Type, Content-Length, Content-Range, Accept-Ranges, ETag, Last-Modified",
  "access-control-max-age": "86400"
};

function contentType(key) {
  const ext = key.slice(key.lastIndexOf(".") + 1).toLowerCase();
  return TYPES[ext] ?? "application/octet-stream";
}

function respond(body, init) {
  const headers = new Headers(init.headers);
  for (const [k, v] of Object.entries(CORS)) headers.set(k, v);
  return new Response(body, {...init, headers});
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return respond(null, {status: 204});
    if (request.method !== "GET" && request.method !== "HEAD") return respond("Method not allowed", {status: 405});

    const url = new URL(request.url);
    const path = decodeURIComponent(url.pathname).replace(/^\/+/, "");
    if (path === "") return Response.redirect(BROWSER + encodeURIComponent(CATALOG_URL), 302);
    if (!SERVED.test(path) || HIDDEN.test(path)) return respond("Not found", {status: 404});

    const ranged = request.headers.has("range");
    const obj = await env.ICR.get(path, {range: ranged ? request.headers : undefined, onlyIf: request.headers});
    if (!obj) return respond("Not found", {status: 404});

    const headers = new Headers();
    obj.writeHttpMetadata(headers);
    headers.set("etag", obj.httpEtag);
    headers.set("last-modified", obj.uploaded.toUTCString());
    headers.set("content-type", contentType(path));
    headers.set("accept-ranges", "bytes");
    headers.set("cache-control", "public, max-age=300");
    const hasBody = "body" in obj && obj.body;
    const partial = ranged && obj.range && hasBody;
    if (partial) {
      const {offset = 0, length = obj.size - offset} = obj.range;
      headers.set("content-range", `bytes ${offset}-${offset + length - 1}/${obj.size}`);
      headers.set("content-length", String(length));
    } else {
      headers.set("content-length", String(obj.size));
    }
    const status = hasBody ? (partial ? 206 : 200) : 304;
    const body = status === 304 || request.method === "HEAD" ? null : obj.body;
    return respond(body, {status, headers});
  }
};
