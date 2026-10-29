"""DIGIT product / product-variant -> event kind and codes (the per-instance ConceptMap)."""
from fhirutil import IDSYS, CS

ATC = "http://www.whocc.no/atc"
CVX = "http://hl7.org/fhir/sid/cvx"

# DIGIT Product.type -> delivery-event kind (configured per tenant; this is the demo tenant's)
TYPE_KIND = {
    "TONIC": "vaccine",      # demo tenant files its oral polio / MR vaccines under TONIC
    "DRUG": "drug",
    "TABLET": "drug",
    "BEDNET": "commodity",
    "RESIDUAL_SPRAY": "commodity",
}

DRUGS = {
    "sp": ("P01BD51", "sulfadoxine and pyrimethamine"),
    "automated-sp": ("P01BD51", "sulfadoxine and pyrimethamine"),
    "updated-automated-sp": ("P01BD51", "sulfadoxine and pyrimethamine"),
    "aq": ("P01BA06", "amodiaquine"),
    "ivermectin": ("P02CF01", "ivermectin"),
    "albendazole": ("P02CA03", "albendazole"),
    "azm": ("J01FA10", "azithromycin"),
    "vas": ("A11CA01", "retinol (vitamin A)"),
    "vitamin a": ("A11CA01", "retinol (vitamin A)"),
    "vit a": ("A11CA01", "retinol (vitamin A)"),
}
COPACK = {"spaq1": ["sp", "aq"], "spaq2": ["sp", "aq"]}
VACCINES = {"mr vaccine": ("04", "measles and rubella virus vaccine"),
            "mr": ("04", "measles and rubella virus vaccine")}
COMMODITY = {"BEDNET": ("llin", "Long-lasting insecticidal net (LLIN)"),
             "RESIDUAL_SPRAY": ("irs-insecticide", "IRS insecticide")}


class Catalog:
    def __init__(self, products, variants):
        self.p = products
        self.v = variants

    def known(self, pvid):
        return pvid in self.v and self.v[pvid]["productId"] in self.p

    def product(self, pvid):
        return self.p[self.v[pvid]["productId"]]

    def kind(self, pvid):
        if not self.known(pvid):
            return None
        return TYPE_KIND.get(self.product(pvid)["type"])

    def label(self, pvid):
        if not self.known(pvid):
            return f"DIGIT product variant {pvid}"
        v = self.v[pvid]
        return (v.get("sku") or self.product(pvid)["name"]).strip()

    def _local(self, pvid):
        return {"system": IDSYS + "product-variant", "code": pvid, "display": self.label(pvid)}

    def components(self, pvid):
        """Co-pack variants give one administration per component: [(suffix, CodeableConcept)]."""
        if not self.known(pvid):
            return [("", {"coding": [self._local(pvid)], "text": self.label(pvid)})]
        name = self.product(pvid)["name"].strip().lower()
        if name in COPACK and self.kind(pvid) == "drug":
            out = []
            for c in COPACK[name]:
                code, disp = DRUGS[c]
                out.append(("-" + c, {"coding": [{"system": ATC, "code": code, "display": disp}],
                                      "text": f"{disp} (from co-pack {self.label(pvid)})"}))
            return out
        return [("", self.code(pvid))]

    def code(self, pvid):
        loc = self._local(pvid)
        if not self.known(pvid):
            return {"coding": [loc], "text": self.label(pvid)}
        p = self.product(pvid)
        name = p["name"].strip().lower()
        kind = self.kind(pvid)
        codings = []
        if kind == "drug" and name in DRUGS:
            codings.append({"system": ATC, "code": DRUGS[name][0], "display": DRUGS[name][1]})
        elif kind == "vaccine" and name in VACCINES:
            codings.append({"system": CVX, "code": VACCINES[name][0], "display": VACCINES[name][1]})
        elif kind == "commodity" and p["type"] in COMMODITY:
            c, d = COMMODITY[p["type"]]
            codings.append({"system": CS + "icr-commodity-class-cs", "code": c, "display": d})
        codings.append(loc)
        return {"coding": codings, "text": self.label(pvid)}

    def unit(self, pvid):
        k = self.kind(pvid)
        if k == "commodity":
            if self.known(pvid) and self.product(pvid)["type"] == "BEDNET":
                return {"unit": "nets", "system": "http://unitsofmeasure.org", "code": "{Net}"}
            return {"unit": "units", "system": "http://unitsofmeasure.org", "code": "1"}
        if k == "drug":
            return {"unit": "tablets", "system": "http://unitsofmeasure.org", "code": "{tbl}"}
        if k == "vaccine":
            return {"unit": "doses", "system": "http://unitsofmeasure.org", "code": "{dose}"}
        return {"unit": "units", "system": "http://unitsofmeasure.org", "code": "1"}
