// The dashboards' Worker: Observatory's gate (@recodelabs/observatory-gate). It serves the sites
// from the `icr` R2 bucket under _site/campaignhq/ and applies each site's `access` from
// observatory.config.js: sign-in with Keycloak (the uga realm) or by email, an admin page at
// /_obs/admin, and the old monitor.healthcampaigns.org host 301-redirected to BASE_URL.
import {createGate} from "@recodelabs/observatory-gate";
import config from "../observatory.config.js";

export default createGate(config);
