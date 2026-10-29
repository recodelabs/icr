// DIGIT demo dashboards, served at https://dashboards.healthcampaigns.org/digit/.
// The data is the DIGIT ICR server (fhir-digit.healthcampaigns.org): eGov's DIGIT HCM demo data,
// which is fake, transformed to ICR profiles. It is exported with fhir-pipes by
// country/digit/warehouse.sh; the loaders in src/data read it at build time.
// https://observablehq.com/framework/config
export default {
  title: "DIGIT demo",
  root: "src",
  pages: [
    {name: "Overview", path: "/"},
    {name: "Georegistry", path: "/georegistry"},
    {name: "Campaign calendar", path: "/calendar"},
    {name: "Campaign delivery", path: "/delivery"},
    {name: "Stock", path: "/stock"},
    {
      name: "Resources",
      path: null,
      pages: [
        {name: "ICR implementation guide", path: "https://icr.healthcampaigns.org/"},
        {name: "DIGIT Health documentation", path: "https://docs.digit.org/health"}
      ]
    }
  ],
  head: `<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🧪</text></svg>">
<style>#observablehq-sidebar a[target="_blank"]::after { content: " ↗"; }</style>`,
  footer: "ICR — Integrated Campaign Registry · DIGIT HCM demo data (fake) from fhir-digit.healthcampaigns.org, exported with fhir-pipes (country/digit/warehouse.sh)",
  sidebar: true,
  toc: false,
  pager: false,
  search: false,
  theme: ["light", "alt"],
  cleanUrls: true,
  // DuckDB 2.0 (swapped in by observatory) has json and parquet built in; don't bundle Framework's 1.1.1 ones.
  duckdb: {extensions: {json: null, parquet: null}}
};
