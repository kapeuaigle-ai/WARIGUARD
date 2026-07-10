"""
test_extraction.py
-------------------
Teste le module extraction_rules.py sur un fichier CSV de messages.

Deux usages :
  1) Fichier avec colonnes deja annotees (contient_lien, mots_cles_declencheurs,
     niveau_urgence) -> mode VERIFICATION : compare l'extraction fraiche aux
     valeurs existantes et signale les ecarts (test de non-regression).
  2) Fichier avec uniquement une colonne `texte` (ex. nouvelles reponses du
     formulaire Google Forms) -> mode EXTRACTION : calcule les features et
     les ajoute au fichier.

Usage :
    python3 test_extraction.py mon_fichier.csv
"""

import sys
import csv
from extraction_automatique import extraire_features

def charger_csv(chemin):
    with open(chemin, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        return list(reader), reader.fieldnames

def mode_verification(rows, fieldnames, chemin_sortie):
    """Compare l'extraction fraiche aux colonnes deja presentes dans le fichier."""
    colonnes_a_verifier = ["contient_lien", "mots_cles_declencheurs", "niveau_urgence"]
    ecarts = {c: [] for c in colonnes_a_verifier}
    resultats = []

    for r in rows:
        features = extraire_features(r["texte"])
        nouveau = {
            "contient_lien": "oui" if features["contient_lien"] else "non",
            "url": features["url"] or "",
            "mots_cles_declencheurs": features["mots_cles_declencheurs"],
            "niveau_urgence": features["niveau_urgence"],
        }
        ligne_resultat = dict(r)
        for c in colonnes_a_verifier:
            ancien = r.get(c, "")
            if ancien != nouveau[c]:
                ecarts[c].append({"id": r.get("id", "?"), "texte": r["texte"],
                                   "ancien": ancien, "nouveau": nouveau[c]})
            ligne_resultat[f"{c}_recalcule"] = nouveau[c]
        resultats.append(ligne_resultat)

    # Rapport dans la console
    print(f"Lignes testees : {len(rows)}\n")
    for c in colonnes_a_verifier:
        n = len(ecarts[c])
        print(f"[{c}] : {n} ecart(s) sur {len(rows)} ({n/len(rows)*100:.1f}%)")
        for ex in ecarts[c][:3]:
            print(f"    id={ex['id']} | texte=\"{ex['texte'][:60]}...\"")
            print(f"        ancien   = {ex['ancien']!r}")
            print(f"        nouveau  = {ex['nouveau']!r}")
        print()

    # Sauvegarde du detail complet
    fieldnames_sortie = list(resultats[0].keys())
    with open(chemin_sortie, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames_sortie)
        writer.writeheader()
        writer.writerows(resultats)
    print(f"Detail complet sauvegarde dans : {chemin_sortie}")

    total_ecarts = sum(len(v) for v in ecarts.values())
    return total_ecarts == 0

def mode_extraction(rows, chemin_sortie):
    """Calcule les features pour un fichier qui n'a que du texte brut."""
    resultats = []
    for r in rows:
        features = extraire_features(r["texte"])
        ligne = dict(r)
        ligne["contient_lien"] = "oui" if features["contient_lien"] else "non"
        ligne["url"] = features["url"] or ""
        ligne["mots_cles_declencheurs"] = features["mots_cles_declencheurs"]
        ligne["niveau_urgence"] = features["niveau_urgence"]
        ligne["texte_normalise"] = features["texte_normalise"]
        resultats.append(ligne)

    fieldnames_sortie = list(resultats[0].keys())
    with open(chemin_sortie, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames_sortie)
        writer.writeheader()
        writer.writerows(resultats)
    print(f"{len(rows)} lignes traitees. Resultat sauvegarde dans : {chemin_sortie}")

if __name__ == "__main__":
    chemin_entree = sys.argv[1] if len(sys.argv) > 1 else "wariguard_dataset.csv"
    rows, fieldnames = charger_csv(chemin_entree)

    a_deja_annotations = all(c in fieldnames for c in
                              ["contient_lien", "mots_cles_declencheurs", "niveau_urgence"])

    if a_deja_annotations:
        print("Mode VERIFICATION (colonnes deja annotees detectees)\n")
        chemin_sortie = chemin_entree.replace(".csv", "_verification.csv")
        ok = mode_verification(rows, fieldnames, chemin_sortie)
        print("\n>>> AUCUN ECART, le module est coherent avec le dataset." if ok
              else "\n>>> DES ECARTS ONT ETE TROUVES, voir detail ci-dessus et dans le fichier de sortie.")
    else:
        print("Mode EXTRACTION (pas de colonnes d'annotation existantes)\n")
        chemin_sortie = chemin_entree.replace(".csv", "_extrait.csv")
        mode_extraction(rows, chemin_sortie)