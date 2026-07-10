"""
link_shield.py
--------------
Module Link Shield — analyse une URL extraite d'un message et retourne un
verdict (sain / suspect) avec le detail des signaux qui ont motive ce verdict.

Reutilise detect_url() de extraction_rules.py pour rester coherent avec le
reste du pipeline (meme principe de source unique que pour les mots-cles).

Usage :
    from link_shield import analyser_url
    resultat = analyser_url("http://orange-money-secure.tk/verif")
"""

import re
from urllib.parse import urlparse

# ---------------------------------------------------------------------------
# 1) Extensions de domaine gratuites/suspectes
#    (tres utilisees en phishing car gratuites et faciles a obtenir en masse)
# ---------------------------------------------------------------------------

EXTENSIONS_SUSPECTES = {".tk", ".ga", ".cf", ".ml", ".gq"}

# ---------------------------------------------------------------------------
# 2) Raccourcisseurs de liens connus (masquent la vraie destination)
# ---------------------------------------------------------------------------

RACCOURCISSEURS_CONNUS = {
    "bit.ly", "tinyurl.com", "cutt.ly", "is.gd", "t.co", "goo.gl",
    "rebrand.ly", "shorte.st", "tiny.cc", "clck.ru",
}

# ---------------------------------------------------------------------------
# 3) Domaines officiels des operateurs (liste blanche) vs mots-cles
#    d'operateur qui peuvent apparaitre dans un faux domaine (typosquatting)
# ---------------------------------------------------------------------------

DOMAINES_OFFICIELS = {
    "orange.ci", "orangemoney.ci", "mtn.ci", "mtnmobilemoney.ci",
    "moov.ci", "moovmoney.ci", "wave.com",
    "google.com", "meet.google.com", "classroom.google.com", "forms.gle",
    "zoom.us", "drive.google.com", "whatsapp.com", "chat.whatsapp.com",
    "coursera.org", "moodle.inphb.ci", "inphb.ci",
}

MOTS_OPERATEURS = ["orange", "mtn", "moov", "wave", "mobilemoney", "mobile-money"]

# ---------------------------------------------------------------------------
# 4) Mots-cles suspects dans le chemin/domaine de l'URL elle-meme
#    (distinct des mots-cles du texte du message, ici on regarde l'URL seule)
# ---------------------------------------------------------------------------

MOTS_CLES_URL_SUSPECTS = [
    "gain", "reclamer", "reclam", "verif", "secure", "confirm",
    "bonus", "prix", "gagner", "urgent", "suspendu", "bloque",
]


def extraire_domaine(url):
    """Extrait le nom de domaine (sans www.) d'une URL."""
    if not url.startswith(("http://", "https://")):
        url = "http://" + url
    try:
        return urlparse(url).netloc.lower().removeprefix("www.")
    except ValueError:
        return ""


def a_extension_suspecte(domaine):
    return any(domaine.endswith(ext) for ext in EXTENSIONS_SUSPECTES)


def est_raccourcisseur(domaine):
    return domaine in RACCOURCISSEURS_CONNUS


def detecter_typosquatting(domaine):
    """
    Retourne True si le domaine contient le nom d'un operateur connu
    (orange, mtn, moov, wave...) MAIS n'est pas dans la liste blanche des
    domaines officiels -> tres probablement une imitation.
    """
    if domaine in DOMAINES_OFFICIELS:
        return False
    return any(mot in domaine for mot in MOTS_OPERATEURS)


def mots_cles_dans_url(url):
    url_lower = url.lower()
    return [m for m in MOTS_CLES_URL_SUSPECTS if m in url_lower]


def analyser_url(url):
    """
    Analyse une URL et retourne un dict complet :
      - domaine
      - extension_suspecte (bool)
      - raccourcisseur (bool)
      - typosquatting (bool)
      - mots_cles_url (liste)
      - score (nombre de signaux positifs)
      - verdict ("sain" / "suspect")
    """
    if not url:
        return None

    domaine = extraire_domaine(url)
    extension_suspecte = a_extension_suspecte(domaine)
    raccourcisseur = est_raccourcisseur(domaine)
    typosquatting = detecter_typosquatting(domaine)
    mots_cles = mots_cles_dans_url(url)

    score = sum([extension_suspecte, raccourcisseur, typosquatting, len(mots_cles) > 0])

    # Cas particulier : domaine officiel connu -> toujours sain, meme si un
    # mot-cle apparait par coincidence dans le chemin (ex. une vraie page
    # "orange.ci/gains-promo" ne doit pas etre signalee).
    if domaine in DOMAINES_OFFICIELS:
        verdict = "sain"
        score = 0
    else:
        verdict = "suspect" if score >= 1 else "sain"

    return {
        "domaine": domaine,
        "extension_suspecte": extension_suspecte,
        "raccourcisseur": raccourcisseur,
        "typosquatting": typosquatting,
        "mots_cles_url": mots_cles,
        "score": score,
        "verdict": verdict,
    }