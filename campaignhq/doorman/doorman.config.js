// doorman.config.js — the Campaign Dashboards deployment. Imported by worker.js (wrangler
// bundles it). Reference: https://github.com/recodelabs/doorman#config-reference
export default {
  site: {name: "campaignhq", dist: "../dist"},
  brand: {title: "Campaign Dashboards", accent: "#0b57d0", logo: null},
  auth: {allowedDomains: ["ona.io"], sessionDays: 30},
  mail: {from: "doorman@healthcampaigns.org", adminNotify: "mberg@ona.io"},
  pages: [{match: "about", access: "public"}]
};
