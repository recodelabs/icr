// ODK Locations — Observable Framework configuration.
export default {
  title: "ODK Locations",
  root: "src",
  pages: [{name: "Export", path: "/"}],
  head: '<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>📍</text></svg>">',
  footer: "ICR — Integrated Campaign Registry · data regenerated from the FHIR registry by tools/warehouse/refresh.sh",
  sidebar: false,
  toc: false,
  pager: false,
  search: false,
  theme: ["light", "alt"],
  cleanUrls: true
};
