// Campaign Dashboards — Observable Framework configuration.
// https://observablehq.com/framework/config
export default {
  title: "Campaign Dashboards",
  root: "src",
  pages: [
    {name: "Campaign calendar", path: "/"},
    {name: "Campaign coverage", path: "/coverage"},
    {name: "NTD endemicity", path: "/ntd"},
    {name: "Georegistry", path: "/georegistry"},
    {name: "About the data", path: "/about"}
  ],
  head: '<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🗓️</text></svg>">',
  footer: "ICR — Integrated Campaign Registry · data regenerated from the FHIR registry by tools/warehouse/refresh.sh",
  sidebar: true,
  toc: false,
  pager: false,
  search: false,
  theme: ["light", "alt"],
  // Every page's data comes from static parquet + pmtiles produced by the loaders
  // in src/data, so the site builds to plain static files.
  cleanUrls: true
};
