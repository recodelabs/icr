// Uganda campaign dashboards, served at https://dashboards.healthcampaigns.org/ug/.
// The data is the Uganda ICR server (fhir-uga.healthcampaigns.org), exported with
// fhir-pipes by refresh.sh into warehouse/; the loaders in src/data read it at build time.
// https://observablehq.com/framework/config
export default {
  title: "Uganda Campaign Dashboards",
  root: "src",
  pages: [
    {name: "ICHD targets", path: "/"},
    {name: "Campaign plan", path: "/plan"},
    {name: "Population estimates", path: "/population"},
    {name: "Georegistry", path: "/georegistry"},
    {
      name: "Resources",
      path: null,
      pages: [
        {name: "Uganda SDI", path: "https://sdi.healthcampaigns.org/uga/"},
        {name: "ICR implementation guide", path: "https://icr.healthcampaigns.org/"}
      ]
    }
  ],
  head: `<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🗓️</text></svg>">
<style>#observablehq-sidebar a[target="_blank"]::after { content: " ↗"; }</style>`,
  footer: "ICR — Integrated Campaign Registry · Uganda data from fhir-uga.healthcampaigns.org, exported with fhir-pipes (campaignhq/uganda/refresh.sh)",
  sidebar: true,
  toc: false,
  pager: false,
  search: false,
  theme: ["light", "alt"],
  cleanUrls: true,
  // DuckDB 2.0 (duckdb-wasm2.sh) has json and parquet built in; don't bundle Framework's 1.1.1 ones.
  duckdb: {extensions: {json: null, parquet: null}}
};
