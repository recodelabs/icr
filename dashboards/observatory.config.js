// The ICR's dashboards at https://dashboards.healthcampaigns.org, built and deployed with
// Observatory (https://github.com/recodelabs/observatory): `npx observatory deploy [site…]`.
// See README.md here and the runbook in tools/warehouse/README.md.
export default {
  host: "https://dashboards.healthcampaigns.org",
  cloudflare: {
    bucket: "icr",
    rclone: "r2",
    // Builds go to this folder plus each site's path (/ug/ → _site/campaignhq/ug/), where the
    // gate in worker/ serves them.
    sites: "_site/campaignhq/",
    worker: "worker",
    // The gate's users and sessions; `observatory deploy` applies its migrations first.
    d1: "observatory"
  },
  brand: {title: "Campaign Dashboards", accent: "#0b57d0", logo: "/_obs/observatory.svg"},
  warehouses: {
    // tools/warehouse/refresh.sh --push writes the main warehouse to the bucket root.
    main: {r2: "", local: "../data"},
    // country/uganda/warehouse.sh --push writes Uganda's to uga/.
    uga: {r2: "uga/", local: "../country/uganda/warehouse"}
  },
  // Who sees what. A site without `access` needs sign-in. Admins (auth.admins) see every site.
  sites: [
    {name: "main", path: "/", dir: "sites/main", warehouse: "main", access: "public"},
    {name: "uganda", path: "/ug/", dir: "sites/uganda", warehouse: "uga",
     access: [{oidc: "uga", group: "/dashboards"}, {emailDomain: "ona.io"}, {role: "admin"}]},
    // The Sierra Leone DHIS2 demo sites read the raw Location download in the local data/,
    // which is not pushed, so they have no warehouse and always build from this machine's copy.
    {name: "sldash", path: "/dhis2-sl/", dir: "sites/sldash", access: "public"},
    {name: "sl-redux", path: "/dhis2-sl-redux/", dir: "sites/sl-redux", access: "public"}
  ],
  auth: {
    // Keycloak users sign in with the uga realm; its groups decide access. The client secret is
    // the Worker secret OIDC_UGA_SECRET.
    oidc: [{id: "uga", name: "Uganda (Keycloak)", issuer: "https://auth.healthcampaigns.org/realms/uga"}],
    // Admins see every site and manage users at /_obs/admin.
    admins: [{email: "mberg@ona.io"}, {oidc: "uga", group: "/dashboards-admins"}],
    // Everyone else signs in by email. A verified ona.io address is active at once; others wait
    // for an admin's approval, and adminNotify gets an email about each.
    email: {allowedDomains: ["ona.io"], from: "dashboards@healthcampaigns.org", adminNotify: "mberg@ona.io"}
  }
};
