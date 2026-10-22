// sl-redux — the Sierra Leone DHIS2 dashboards (see ../sldash) with the same indicators,
// redrawn for comparing districts: filters, rankings, maps, heatmaps and trends.
// https://observablehq.com/framework/config
export default {
  title: "DHIS2 Demo Dashboards (powered by FHIR)",
  root: "src",
  pages: [
    {name: "Overview", path: "/"},
    {name: "Antenatal Care", path: "/antenatal-care"},
    {name: "Delivery", path: "/delivery"},
    {name: "Disease Surveillance", path: "/disease-surveillance"},
    {name: "Immunization", path: "/immunization"},
    {name: "Immunization data", path: "/immunization-data"},
    {name: "Key Indicators", path: "/key-indicators"},
    {name: "Malnutrition", path: "/malnutrition"},
    {name: "Measles", path: "/measles"},
    {name: "Mother and Child Health", path: "/mother-and-child-health"},
    {name: "Nutrition", path: "/nutrition"},
    {name: "Reporting Rates", path: "/reporting-rates"},
    {name: "Reporting Reproductive Health", path: "/reporting-reproductive-health"},
    {name: "Staffing", path: "/staffing"},
    {name: "Visits ANC", path: "/visits-anc"},
    {name: "About", path: "/about"}
  ],
  head: `<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>📈</text></svg>">`,
  footer: "",
  sidebar: true,
  toc: false,
  pager: false,
  search: false,
  style: "style.css",
  cleanUrls: true,
  // DuckDB 2.0 (duckdb-wasm2.sh) has json and parquet built in; don't bundle Framework's 1.1.1 ones.
  duckdb: {extensions: {json: null, parquet: null}}
};
