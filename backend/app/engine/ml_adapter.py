"""Adaptateur pour le modèle ML de Cephas (en cours de développement).

BRANCHEMENT DU MODÈLE — 3 étapes :
  1. Déposer le modèle (ou son client d'inférence) dans ce fichier via
     `load_model()` : fine-tuné CamemBERT/DistilBERT, pipeline sklearn, ou
     appel LLM — peu importe, tant que `predict_json()` sort le contrat JSON.
  2. Le modèle doit produire un dict :
     {
       "risk_score": float 0..1,
       "scam_type": "faux_agent" | "faux_gain" | "transfert_errone"
                    | "phishing_lien" | "aucun",
       "triggers": [{"text": str, "category": str, "weight": float}],
       "explanation": str  # optionnel
     }
  3. Lancer le backend avec WARIGUARD_ENGINE=ml
     → l'API /api/analyze sert alors le modèle, sans toucher au frontend.

Les seuils rouge/orange/vert et la recommandation restent gérés ici, pour
garder une politique d'alerte cohérente quelle que soit la source du score.
"""

import time

from ..schemas import AnalysisResult, Channel, RiskLevel, ScamType, Trigger
from .base import DetectionEngine
from .heuristic import ORANGE_THRESHOLD, RECOMMENDATIONS, RED_THRESHOLD


class MLEngine(DetectionEngine):
    name = "WariGuard-ML"
    version = "0.1.0-dev"

    def __init__(self) -> None:
        self._model = self.load_model()

    def load_model(self):
        """POINT D'INTÉGRATION : charger ici le modèle entraîné.

        Exemple attendu :
            from transformers import pipeline
            return pipeline("text-classification", model="./model_wariguard")
        """
        raise RuntimeError(
            "Modèle ML non encore livré. Implémenter MLEngine.load_model() "
            "et predict_json(), puis relancer avec WARIGUARD_ENGINE=ml. "
            "En attendant, le moteur heuristique est actif par défaut."
        )

    def predict_json(self, text: str) -> dict:
        """POINT D'INTÉGRATION : appeler le modèle et retourner le dict JSON du contrat."""
        raise NotImplementedError

    def analyze(self, text: str, channel: Channel = Channel.SMS) -> AnalysisResult:
        start = time.perf_counter()
        raw = self.predict_json(text)

        score = max(0.0, min(1.0, float(raw["risk_score"])))
        if score >= RED_THRESHOLD:
            level = RiskLevel.RED
        elif score >= ORANGE_THRESHOLD:
            level = RiskLevel.ORANGE
        else:
            level = RiskLevel.GREEN
        scam_type = ScamType(raw.get("scam_type", "aucun"))

        return AnalysisResult(
            risk_score=round(score, 3),
            risk_level=level,
            scam_type=scam_type,
            triggers=[Trigger(**t) for t in raw.get("triggers", [])],
            explanation=raw.get("explanation", "Analyse par modèle ML."),
            recommendation=RECOMMENDATIONS[scam_type],
            model_name=self.name,
            model_version=self.version,
            latency_ms=round((time.perf_counter() - start) * 1000, 2),
        )
