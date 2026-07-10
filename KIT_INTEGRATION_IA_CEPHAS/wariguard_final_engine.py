"""
WariGuard — Final IA Engine
Auteur : BROU KOUAKOU CEPHAS

Ce module charge les deux modèles IA entraînés et expose une seule fonction :

    analyser_message_wariguard(texte)

Fichiers requis dans le même dossier que ce fichier :
- wariguard_binary_model_augmented_hard.pkl
- wariguard_multiclass_model_augmented_hard.pkl
- wariguard_scenario_mapping.json

Dépendances :
    pip install scikit-learn joblib pandas
"""

import os
import re
import json
import joblib
import unicodedata
from typing import Dict, List


# ============================================================
# 1. Chemins des fichiers modèles
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

BINARY_MODEL_PATH = os.path.join(BASE_DIR, "wariguard_binary_model_augmented_hard.pkl")
MULTICLASS_MODEL_PATH = os.path.join(BASE_DIR, "wariguard_multiclass_model_augmented_hard.pkl")
MAPPING_PATH = os.path.join(BASE_DIR, "wariguard_scenario_mapping.json")


# ============================================================
# 2. Chargement des modèles
# ============================================================

if not os.path.exists(BINARY_MODEL_PATH):
    raise FileNotFoundError(f"Modèle binaire introuvable : {BINARY_MODEL_PATH}")

if not os.path.exists(MULTICLASS_MODEL_PATH):
    raise FileNotFoundError(f"Modèle multiclasse introuvable : {MULTICLASS_MODEL_PATH}")

if not os.path.exists(MAPPING_PATH):
    raise FileNotFoundError(f"Mapping des scénarios introuvable : {MAPPING_PATH}")

binary_model = joblib.load(BINARY_MODEL_PATH)
multiclass_model = joblib.load(MULTICLASS_MODEL_PATH)

with open(MAPPING_PATH, "r", encoding="utf-8") as f:
    SCENARIO_MAPPING = json.load(f)


# ============================================================
# 3. Normalisation du texte
# ============================================================

def normaliser_texte(texte: str) -> str:
    """Normalise un texte pour faciliter la détection des mots déclencheurs."""
    if not isinstance(texte, str):
        return ""

    texte = texte.lower()
    texte = unicodedata.normalize("NFD", texte)
    texte = "".join(c for c in texte if unicodedata.category(c) != "Mn")
    texte = re.sub(r"[^a-z0-9\s./:-]", " ", texte)
    texte = re.sub(r"\s+", " ", texte).strip()
    return texte


# ============================================================
# 4. Moteur de règles explicable
# ============================================================

REGLES_MOTS_CLES = {
    "faux_agent": [
        "agent", "service client", "support", "operateur", "orange money", "wave", "mtn", "moov",
        "mobile money", "compte", "verification", "verifier", "mise a jour", "activation",
        "suspension", "bloque", "deblocage", "otp", "pin", "code secret", "code confidentiel",
        "mot de passe", "code recu", "message recu", "lisez-moi", "sequence recue", "numero temporaire"
    ],
    "faux_gain": [
        "gagne", "gagnant", "felicitation", "felicitations", "promotion", "promo", "loterie",
        "bonus", "cadeau", "prix", "recompense", "gain", "lot", "tirage", "selectionne",
        "dotation", "beneficiaire", "frais administratifs", "programme fidelite"
    ],
    "faux_transfert": [
        "transfert", "erreur", "envoye par erreur", "mauvais transfert", "trompe de numero",
        "renvoyer", "renvoie", "rembourser", "remboursement", "restituer", "retourner",
        "retour", "montant", "solde est chez vous", "confusion", "pas destine"
    ],
    "phishing_lien": [
        "connectez-vous", "reconnectez", "validez", "revalider", "confirmez", "lien", "http",
        "https", "infos demandees", "restriction", "acces limite", "page de verification"
    ],
    "urgence_familiale": [
        "accident", "hopital", "urgence", "commissariat", "police", "garde a vue", "caution",
        "telephone d un ami", "portefeuille disparu", "bloque", "aider discretement", "je t explique apres",
        "probleme", "maman", "papa", "tantie"
    ],
    "fausse_promotion": [
        "double", "triple", "retour automatique", "multiplication", "offre speciale", "offre secrete",
        "operation speciale", "depot minimum", "solde multiplie", "validation manuelle", "premiers clients"
    ],
    "nouchi_mixte": [
        "mon vieux", "chef", "tantie", "yako", "compte-la", "affaire-la", "faut pas dormir",
        "ca passe", "faut faire vite", "numero-la", "argent-la", "drap", "gbair"
    ]
}

SIGNAUX_CRITIQUES = [
    "otp", "pin", "code secret", "code confidentiel", "mot de passe", "code recu",
    "message recu", "lisez-moi", "sequence recue", "donne les chiffres", "http", "https"
]


def extraire_mots_declencheurs(texte: str) -> List[str]:
    """Extrait les mots ou expressions déclencheurs détectés dans le texte."""
    texte_norm = normaliser_texte(texte)
    mots = []

    for _, liste_mots in REGLES_MOTS_CLES.items():
        for mot in liste_mots:
            mot_norm = normaliser_texte(mot)
            if mot_norm and mot_norm in texte_norm:
                mots.append(mot)

    # Extraction simple des montants potentiels, ex : 25000F, 5000 FCFA.
    montants = re.findall(r"\b\d{3,}\s*(?:f|fcfa)?\b", texte_norm)
    mots.extend([m.strip() for m in montants])

    return sorted(set(mots))


def calculer_bonus_regles(texte: str, mots_declencheurs: List[str]) -> float:
    """Calcule un bonus de risque basé sur les signaux critiques détectés."""
    texte_norm = normaliser_texte(texte)
    bonus = 0.0

    for signal in SIGNAUX_CRITIQUES:
        if normaliser_texte(signal) in texte_norm:
            bonus += 0.05

    if len(mots_declencheurs) >= 3:
        bonus += 0.05

    if len(mots_declencheurs) >= 6:
        bonus += 0.05

    return min(bonus, 0.20)


# ============================================================
# 5. Message utilisateur
# ============================================================

def generer_message_utilisateur(resultat: Dict) -> str:
    """Génère un message clair prêt à afficher dans l'interface utilisateur."""
    niveau = resultat.get("niveau_alerte", "vert")
    score = int(resultat.get("score_risque", 0) * 100)
    type_arnaque = resultat.get("type_arnaque", "aucune")

    if niveau == "rouge":
        return (
            f"🔴 Alerte élevée ({score}%)\n"
            f"Cette communication présente de forts signes d'arnaque.\n"
            f"Type détecté : {type_arnaque}.\n"
            f"Conseil : ne communiquez aucun code et ne transférez pas d'argent."
        )

    if niveau == "orange":
        return (
            f"🟠 Prudence ({score}%)\n"
            f"Des éléments suspects ont été détectés.\n"
            f"Type probable : {type_arnaque}.\n"
            f"Conseil : vérifiez l'identité de votre interlocuteur avant toute action."
        )

    return (
        f"🟢 Aucun risque détecté ({score}%)\n"
        f"Ce message ne présente pas de signe évident d'arnaque connu."
    )


# ============================================================
# 6. Fonction principale à utiliser dans l'application
# ============================================================

def analyser_message_wariguard(texte: str) -> Dict:
    """
    Analyse un SMS, un message WhatsApp ou une transcription d'appel.

    Paramètre :
        texte (str): texte à analyser.

    Retourne :
        dict: JSON final contenant score, alerte, label, type, mots déclencheurs et message utilisateur.
    """

    # 1. Prédiction binaire : arnaque / légitime
    label_pred = binary_model.predict([texte])[0]
    binary_proba = binary_model.predict_proba([texte])[0]
    binary_proba_dict = dict(zip(binary_model.classes_, binary_proba))
    score_ml = float(binary_proba_dict.get("arnaque", 0.0))

    # 2. Règles explicables
    mots_declencheurs = extraire_mots_declencheurs(texte)
    bonus_regles = calculer_bonus_regles(texte, mots_declencheurs)

    # 3. Score final
    score_final = min(score_ml + bonus_regles, 1.0)

    if score_final >= 0.70:
        niveau_alerte = "rouge"
    elif score_final >= 0.40:
        niveau_alerte = "orange"
    else:
        niveau_alerte = "vert"

    # 4. Cas légitime ou faible risque
    if score_final < 0.40:
        resultat = {
            "score_risque": round(score_final, 4),
            "niveau_alerte": niveau_alerte,
            "label": "legitime",
            "type_scenario": "T7",
            "type_arnaque": "aucune",
            "mots_declencheurs": mots_declencheurs,
            "probabilite_ml_arnaque": round(score_ml, 4),
            "bonus_regles": round(bonus_regles, 4),
            "probabilites_binaires": {k: round(float(v), 4) for k, v in binary_proba_dict.items()},
            "probabilites_types": {}
        }
        resultat["message_utilisateur"] = generer_message_utilisateur(resultat)
        return resultat

    # 5. Cas arnaque : prédiction du scénario T1 à T6
    type_pred = multiclass_model.predict([texte])[0]
    type_proba = multiclass_model.predict_proba([texte])[0]
    type_proba_dict = dict(zip(multiclass_model.classes_, type_proba))

    resultat = {
        "score_risque": round(score_final, 4),
        "niveau_alerte": niveau_alerte,
        "label": "arnaque",
        "type_scenario": type_pred,
        "type_arnaque": SCENARIO_MAPPING.get(type_pred, type_pred),
        "confiance_type": round(float(max(type_proba)), 4),
        "mots_declencheurs": mots_declencheurs,
        "probabilite_ml_arnaque": round(score_ml, 4),
        "bonus_regles": round(bonus_regles, 4),
        "probabilites_binaires": {k: round(float(v), 4) for k, v in binary_proba_dict.items()},
        "probabilites_types": {
            SCENARIO_MAPPING.get(k, k): round(float(v), 4)
            for k, v in type_proba_dict.items()
        }
    }

    resultat["message_utilisateur"] = generer_message_utilisateur(resultat)
    return resultat


# ============================================================
# 7. Test rapide si le fichier est exécuté directement
# ============================================================

if __name__ == "__main__":
    exemple = "Bonjour je suis agent Wave, donnez votre code OTP pour verifier votre compte."
    resultat = analyser_message_wariguard(exemple)
    print(json.dumps(resultat, ensure_ascii=False, indent=2))
