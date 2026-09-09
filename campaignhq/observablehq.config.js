// Campaign Dashboards — Observable Framework configuration.
// https://observablehq.com/framework/config
export default {
  title: "Campaign Dashboards",
  root: "src",
  pages: [
    {name: "Campaign calendar", path: "/"},
    {name: "Campaign coverage", path: "/coverage"},
    {name: "Campaign targeting", path: "/targeting"},
    {name: "NTD endemicity", path: "/ntd"},
    {name: "Microplan (NIPDs, Toro)", path: "/microplan"},
    {name: "Georegistry", path: "/georegistry"},
    {
      name: "Resources",
      path: null,
      pages: [
        // An external URL here (unlike the /-prefixed paths above) makes Framework
        // open it in a new tab automatically; the ↗ is added by the CSS below.
        {name: "ODK Locations", path: "https://odklocations.healthcampaigns.org/"},
        {name: "SDI Portolan", path: "https://sdi.healthcampaigns.org/"}
      ]
    }
  ],
  head: `<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🗓️</text></svg>">
<style>#observablehq-sidebar a[target="_blank"]::after { content: " ↗"; }</style>`,
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
