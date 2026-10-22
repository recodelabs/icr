// The ICR's dashboards at https://dashboards.healthcampaigns.org, built and deployed with
// Observatory (https://github.com/recodelabs/observatory): `npx observatory deploy [site…]`.
// See README.md here and the runbook in tools/warehouse/README.md.
export default {
  host: "https://dashboards.healthcampaigns.org",
  cloudflare: {
    bucket: "icr",
    rclone: "r2",
    // Builds go to this folder plus each site's path (/ug/ → _site/campaignhq/ug/), where the
    // campaignhq Worker in worker/ serves them.
    sites: "_site/campaignhq/",
    worker: "worker"
  },
  warehouses: {
    // tools/warehouse/refresh.sh --push writes the main warehouse to the bucket root.
    main: {r2: "", local: "../data"},
    // country/uganda/warehouse.sh --push writes Uganda's to uga/.
    uga: {r2: "uga/", local: "../country/uganda/warehouse"}
  },
  // `access` takes effect with Observatory's gate (phase 3); the campaignhq Worker serves every
  // site publicly until then.
  sites: [
    {name: "main", path: "/", dir: "sites/main", warehouse: "main", access: "public"},
    {name: "uganda", path: "/ug/", dir: "sites/uganda", warehouse: "uga",
     access: [{oidc: "uga", group: "/dashboards"}, {emailDomain: "ona.io"}, {role: "admin"}]},
    // The Sierra Leone DHIS2 demo sites read the raw Location download in the local data/,
    // which is not pushed, so they have no warehouse and always build from this machine's copy.
    {name: "sldash", path: "/dhis2-sl/", dir: "sites/sldash", access: "public"},
    {name: "sl-redux", path: "/dhis2-sl-redux/", dir: "sites/sl-redux", access: "public"}
  ]
};
