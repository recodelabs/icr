// Worker entry: doorman built from this deployment's config. Everything site-specific
// lives in doorman.config.js and wrangler.jsonc next to this file.
import {createDoorman} from "doorman";
import config from "./doorman.config.js";

export default createDoorman(config);
