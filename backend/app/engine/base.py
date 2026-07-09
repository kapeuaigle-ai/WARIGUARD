"""Interface commune des moteurs de détection WariGuard.

Deux implémentations prévues :
  - HeuristicEngine (engine/heuristic.py) : règles + mots-clés, actif par défaut.
  - MLEngine (engine/ml_adapter.py)       : modèle de Cephas, branché dès qu'il
    est prêt. Sélection via la variable d'environnement WARIGUARD_ENGINE=ml.

Toute implémentation DOIT retourner un AnalysisResult (schemas.py) — c'est le
contrat JSON partagé avec le frontend Flutter.
"""

from abc import ABC, abstractmethod

from ..schemas import AnalysisResult, Channel


class DetectionEngine(ABC):
    name: str = "base"
    version: str = "0.0.0"

    @abstractmethod
    def analyze(self, text: str, channel: Channel) -> AnalysisResult:
        """Analyse un texte (SMS ou transcription d'appel) et retourne le verdict."""
        raise NotImplementedError
