// Bangladesh EPI dashboards, served at https://dashboards.healthcampaigns.org/bd/ (sign-in only).
// The 2026 MR campaign (EPI campaign DHIS2) and routine immunization (EPI e-Tracker, through the
// DGHS GIS dashboard), both imported into a FHIR server that is kept offline. Its warehouse is
// built with fhir-pipes and uploaded by country/bangladesh/push.sh; the loaders in src/data read
// the warehouse at build time.
// https://observablehq.com/framework/config
export default {
  title: "Bangladesh EPI: MR campaign 2026 and routine",
  root: "src",
  pages: [
    {name: "MR Vaccination Campaign 2026", path: "/"},
    {name: "Routine immunization", path: "/routine"},
    {name: "Routine vs MR campaign", path: "/routine-vs-campaign"},
    {name: "Do routine and the campaign plan for the same children?", path: "/target-gap"},
    {name: "Where the campaign may have missed children", path: "/missed"},
    {name: "Did routine immunization change during the campaign?", path: "/campaign-effect"},
    {name: "About the data", path: "/about"}
  ],
  footer: "",
  sidebar: true,
  toc: false,
  pager: false,
  search: false,
  style: "style.css",
  cleanUrls: true,
  // DuckDB 2.0 (swapped in by observatory) has json and parquet built in; don't bundle Framework's 1.1.1 ones.
  duckdb: {extensions: {json: null, parquet: null}}
};
