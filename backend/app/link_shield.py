"""Link Shield — vérification heuristique d'URL avant ouverture.

Signaux : raccourcisseurs, domaines usurpés (typosquatting d'opérateurs),
TLD à risque, mots-clés d'appât dans l'URL, IP littérale, absence de HTTPS.
"""

import re
from urllib.parse import urlparse

from .schemas import LinkCheckResult, LinkVerdict

SHORTENERS = {
    "bit.ly", "tinyurl.com", "cutt.ly", "t.co", "goo.gl", "is.gd",
    "rb.gy", "shorturl.at", "rebrand.ly", "s.id", "tny.im",
}

OFFICIAL_DOMAINS = {
    "orange.ci", "orange.com", "mtn.ci", "mtn.com", "moov-africa.ci",
    "wave.com", "djamo.com", "gouv.ci",
}

# Marques usurpables dans les scénarios Mobile Money CI
BRANDS = ["orange", "mtn", "moov", "wave", "momo", "djamo"]

RISKY_TLDS = {".xyz", ".top", ".click", ".buzz", ".info", ".live", ".icu", ".cam", ".rest"}

BAIT_WORDS = [
    "gagner", "gain", "cadeau", "promo", "bonus", "reclamer", "recompense",
    "gratuit", "verification", "verifier", "compte", "securite", "deblocage",
    "urgent", "prize", "win", "claim", "free", "reward",
]


def _registered_domain(host: str) -> str:
    parts = host.split(".")
    if len(parts) >= 3 and parts[-2] in ("co", "com", "gouv", "org", "net") and len(parts[-1]) == 2:
        return ".".join(parts[-3:])
    return ".".join(parts[-2:]) if len(parts) >= 2 else host


def check_link(raw_url: str) -> LinkCheckResult:
    url = raw_url.strip()
    if not re.match(r"^[a-z][a-z0-9+.-]*://", url, re.I):
        url = "http://" + url

    parsed = urlparse(url)
    host = (parsed.hostname or "").lower()
    domain = _registered_domain(host)
    path_query = f"{parsed.path}?{parsed.query}".lower()

    reasons: list[str] = []
    score = 0.0

    if domain in OFFICIAL_DOMAINS:
        return LinkCheckResult(
            url=raw_url, domain=domain, verdict=LinkVerdict.SUR,
            risk_score=0.02, reasons=["Domaine officiel reconnu"],
        )

    if domain in SHORTENERS:
        score += 0.45
        reasons.append(f"Raccourcisseur d'URL ({domain}) : la destination réelle est masquée")

    if re.fullmatch(r"\d{1,3}(\.\d{1,3}){3}", host or ""):
        score += 0.5
        reasons.append("Adresse IP brute au lieu d'un nom de domaine")

    for brand in BRANDS:
        if brand in host and domain not in OFFICIAL_DOMAINS:
            score += 0.5
            reasons.append(f"Usurpation probable de la marque « {brand} » (domaine non officiel : {domain})")
            break

    for tld in RISKY_TLDS:
        if host.endswith(tld):
            score += 0.3
            reasons.append(f"Extension de domaine à risque ({tld})")
            break

    baits = [w for w in BAIT_WORDS if w in host or w in path_query]
    if baits:
        score += min(0.15 * len(baits), 0.4)
        reasons.append("Mots d'appât dans le lien : " + ", ".join(sorted(set(baits))[:4]))

    if parsed.scheme == "http":
        score += 0.15
        reasons.append("Connexion non sécurisée (pas de HTTPS)")

    if host.count("-") >= 2:
        score += 0.15
        reasons.append("Domaine composite suspect (tirets multiples)")

    if len(host.split(".")) >= 4:
        score += 0.2
        reasons.append("Sous-domaines en cascade pour imiter un site légitime")

    score = max(0.0, min(1.0, score))
    if score >= 0.6:
        verdict = LinkVerdict.BLOQUE
    elif score >= 0.3:
        verdict = LinkVerdict.SUSPECT
    else:
        verdict = LinkVerdict.SUR
        if not reasons:
            reasons.append("Aucun signal malveillant détecté")

    return LinkCheckResult(
        url=raw_url, domain=domain or "inconnu", verdict=verdict,
        risk_score=round(score, 3), reasons=reasons,
    )
