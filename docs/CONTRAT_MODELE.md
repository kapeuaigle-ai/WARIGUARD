# Contrat JSON du modèle de détection — WariGuard

Document d'intégration pour le modèle ML en cours de développement (Cephas).
Le contrat est **figé** : l'app Flutter et le serveur FastAPI le respectent déjà.
Tant que le modèle n'est pas livré, le moteur heuristique produit exactement le même format.

## Entrée

`POST /api/analyze`

```json
{
  "text": "Cher client, envoyez votre code secret...",
  "channel": "sms"          // "sms" | "appel" (transcription)
}
```

## Sortie attendue du modèle

```json
{
  "risk_score": 0.87,        // float 0..1
  "risk_level": "rouge",     // "rouge" | "orange" | "vert" (dérivé des seuils)
  "scam_type": "faux_agent", // "faux_agent" | "faux_gain" | "transfert_errone"
                             // | "phishing_lien" | "aucun"
  "triggers": [              // mots/expressions ayant contribué au score
    {"text": "code secret", "category": "demande de code secret", "weight": 0.55}
  ],
  "explanation": "Ce SMS correspond fortement à une usurpation d'identité...",
  "recommendation": "Raccrochez / ne répondez pas...",
  "model_name": "WariGuard-ML",
  "model_version": "0.1.0",
  "latency_ms": 42.5
}
```

## Seuils d'alerte (politique commune, ne pas dupliquer dans le modèle)

| Niveau  | Condition            | UI            |
|---------|----------------------|---------------|
| rouge   | `risk_score ≥ 0.65`  | DANGER        |
| orange  | `0.35 ≤ score < 0.65`| MÉFIANCE      |
| vert    | `score < 0.35`       | SÛR           |

Le modèle peut ne produire que `risk_score`, `scam_type`, `triggers`,
`explanation` : le serveur (`backend/app/engine/ml_adapter.py`) applique les
seuils et la recommandation.

## Étapes d'intégration (côté Cephas)

1. Implémenter `MLEngine.load_model()` et `predict_json()` dans
   `backend/app/engine/ml_adapter.py` (exemples dans le fichier).
2. Lancer : `WARIGUARD_ENGINE=ml uvicorn app.main:app --port 8000`.
3. Dans l'app Flutter : écran **Sécurité → Moteur d'analyse → Modèle ML distant**.
   L'app détecte le serveur (`GET /api/health`) et bascule. Aucun écran à modifier.
4. En cas de panne réseau, l'app retombe automatiquement sur le moteur local.

## Jeu de données

`data/dataset_wariguard.json` — 67 exemples annotés (48 arnaques, 19 légitimes),
français + Nouchi, 5 classes. Copie embarquée dans l'app :
`frontend/assets/data/dataset_wariguard.json`. Étendre les deux ou mettre en
place une copie au build.
