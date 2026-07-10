import re
import unicodedata
import pandas as pd

# ---------------------------------------------------------------------------
# BLOC A — Normalisation du texte
# ---------------------------------------------------------------------------

# Abreviations SMS/oral courantes -> forme longue (pour uniformiser avant
# l'extraction de mots-cles ; evite de rater "code secret stp" vs "code secret
# s'il te plait")
ABREVIATIONS = {
    r"\bstp\b": "s'il te plait",
    r"\bsvp\b": "s'il vous plait",
    r"\bmrc\b": "merci",
    r"\bdac\b": "d'accord",
    r"\bpk\b": "pourquoi",
    r"\bkoi\b": "quoi",
    r"\bkes\b": "qu'est-ce que",
    r"\bbcp\b": "beaucoup",
    r"\bojd\b": "aujourd'hui",
    r"\b2main\b": "demain",
    r"\bmnt\b": "maintenant",
    r"\bjsuis\b": "je suis",
    r"\bjvais\b": "je vais",
}

# Marqueurs Nouchi frequents : on les detecte (pour le bloc F - registre) mais
# on ne les supprime PAS du texte normalise, seulement du texte "de comparaison"
# utilise en interne pour le matching de mots-cles.
MARQUEURS_NOUCHI = [
    r"-la\b", r"\bo\b$", r"\baie\b", r"\bchef\b", r"\btantie\b",
    r"\bwe\b", r"\bo\b",
]



# Suppression des accents

def supprimer_accents(texte):
    """Retire les accents pour une comparaison tolerante aux fautes de frappe."""

    nfkd = unicodedata.normalize("NFKD", texte)
    return "".join(c for c in nfkd if not unicodedata.combining(c))



# Nettoyage des espaces

def nettoyer_espaces(texte):
    """ Nettoye les espaces en plus entre les mots."""
    return re.sub(r"\s+"," ", texte).strip()



def developper_abreviations(texte):

    t = texte

    for pattern, remplacement in ABREVIATIONS.items():
        t = re.sub(pattern,remplacement,t)

    return t



def normaliser(texte_brut):
    """
    Retourne un dict avec :
      - texte_original      : jamais modifie, pour l'affichage utilisateur
      - texte_normalise      : minuscule + espaces nettoyes + abreviations
                               developpees (utilise par les blocs C, D, E, F)
      - texte_comparaison    : version sans accents, la plus tolerante,
                               utilisee uniquement pour le matching regex
                               (jamais affichee)
    """
    texte_original = texte_brut
    texte = nettoyer_espaces(texte_brut)
    texte = texte.lower()
    texte = developper_abreviations(texte)
    texte_normalise = nettoyer_espaces(texte)
    texte_comparaison = supprimer_accents(texte_normalise)

    version = {
        "texte_original": texte_original,
        "texte_normalise": texte_normalise,
        "texte_comparaison": texte_comparaison,
    }
 
    return version



"""texte = " Bonjour svp aidez moi. J'ai aidé plusieurs personnes ici." \
"L'etre humain a été toujours comme çà ojd et 2main"
test = normaliser(texte)

print(test)

"""

# ---------------------------------------------------------------------------
# 1) Detection de lien
# ---------------------------------------------------------------------------
 
URL_REGEX = re.compile(r"(https?://\S+|www\.\S+)", re.IGNORECASE)
 
def detect_url(texte):
    match = URL_REGEX.search(texte)
    if match:
        return True, match.group(0).rstrip(".,;)")
    return False, None
 

 # ---------------------------------------------------------------------------
# 2) Mots-cles declencheurs (liste maitresse, tolerante au nouchi et aux fautes)
#    Chaque entree : (motif_regex, libelle_affiche)
# ---------------------------------------------------------------------------

MOTS_CLES_MAITRES = [
    (r"code\s*secret", "code secret"),
    (r"code\s*(otp|de\s*verification)", "code otp"),
    (r"code[\s-]*(secret)?[\s-]*l[àa]\b", "code-là (nouchi)"),
    (r"d[ée]bloqu\w*", "déblocage"),
    (r"v[ée]rifi\w*", "vérification"),
    (r"compte\s*(suspendu|bloqu\w*)", "compte suspendu"),
    (r"compte[\s-]*l[àa]\b", "compte-là (nouchi)"),
    (r"agent\s*officiel", "agent officiel"),
    (r"\bconseiller\b", "conseiller"),
    (r"erreur", "erreur"),
    (r"tromp[ée]", "trompé"),
    (r"renvoy\w*", "renvoyer"),
    (r"rembours\w*", "rembourser"),
    (r"gagn[ée]?", "gagné"),
    (r"r[ée]clam\w*", "réclamer"),
    (r"f[ée]licitations?", "félicitations"),
    (r"\bprix\b", "prix"),
    (r"confirm\w*", "confirmez"),
    (r"connectez[\s-]vous", "connectez-vous"),
    (r"s[ée]curisez\s*votre\s*compte", "sécurisez votre compte"),
    (r"c'est\s*moi", "c'est moi"),
    (r"probl[èe]me", "problème"),
    (r"\bsoucis\b", "soucis"),
    (r"envoie[\s-]?moi", "envoie-moi"),
    (r"doubl\w*", "doublez"),
    (r"offre\s*sp[ée]ciale", "offre spéciale"),
    (r"bonus", "bonus"),
    (r"promo\w*", "promo"),
    (r"caution", "caution"),
    (r"arret[ée]", "arrêté"),
    (r"chop[ée]", "choppé (nouchi)"),
    (r"police|brigade|gendarmerie", "police/brigade"),
    (r"drogue", "drogue"),
]
 

def extract_keywords(texte_comparaison):
    trouves = []
    for pattern, libelle in MOTS_CLES_MAITRES:
        if re.search(pattern, texte_comparaison):
            trouves.append(libelle)
    return trouves

# ---------------------------------------------------------------------------
# 3) Score d'urgence de surface (comptage pondere, pas de ML)
# ---------------------------------------------------------------------------
 
MOTS_URGENCE = [
    r"\burgent\w*", r"\bvite\b", r"imm[ée]diat\w*", r"maintenant", r"\bmnt\b",
    r"tout\s*de\s*suite", r"rapidement", r"sinon", r"d[ée]p[ée]ch\w*",
]
 
def score_urgence(texte_comparaison, texte_original):
    score = 0
    for pattern in MOTS_URGENCE:
        if re.search(pattern, texte_comparaison):
            score += 1
    score += texte_original.count("!")  # ponctuation excessive (sur le texte original)
    if score == 0:
        return "faible"
    elif score <= 2:
        return "moyen"
    else:
        return "élevé"
    

# ---------------------------------------------------------------------------
# Fonction unique appelee par le pipeline (etape 3) ET par la reannotation
# ---------------------------------------------------------------------------
 
def extraire_features(texte_brut):
    infos = normaliser(texte_brut)
    contient_lien, url = detect_url(infos["texte_original"])
    mots_cles = extract_keywords(infos["texte_comparaison"])
    urgence = score_urgence(infos["texte_comparaison"], infos["texte_original"])
    return {
        "contient_lien": contient_lien,
        "url": url,
        "mots_cles_declencheurs": ";".join(mots_cles),
        "niveau_urgence": urgence,
        "texte_normalise": infos["texte_normalise"],
    }
