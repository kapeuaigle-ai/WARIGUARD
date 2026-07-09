"""Contrat JSON WariGuard — figé pour l'intégration du modèle ML.

Le futur modèle de Cephas (CamemBERT/DistilBERT ou LLM) doit produire une
sortie conforme à `AnalysisResult`. Tant qu'il n'est pas prêt, le moteur
heuristique (engine/heuristic.py) produit exactement le même format.
"""

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class RiskLevel(str, Enum):
    RED = "rouge"
    ORANGE = "orange"
    GREEN = "vert"


class ScamType(str, Enum):
    FAUX_AGENT = "faux_agent"
    FAUX_GAIN = "faux_gain"
    TRANSFERT_ERRONE = "transfert_errone"
    PHISHING_LIEN = "phishing_lien"
    AUCUN = "aucun"


class Channel(str, Enum):
    SMS = "sms"
    APPEL = "appel"


class Trigger(BaseModel):
    """Mot ou expression ayant contribué au score."""

    text: str
    category: str
    weight: float


class AnalyzeRequest(BaseModel):
    text: str = Field(min_length=1, max_length=5000)
    channel: Channel = Channel.SMS


class AnalysisResult(BaseModel):
    """Sortie JSON standard — contrat partagé avec le modèle ML."""

    risk_score: float = Field(ge=0.0, le=1.0)
    risk_level: RiskLevel
    scam_type: ScamType
    triggers: list[Trigger]
    explanation: str
    recommendation: str
    model_name: str
    model_version: str
    latency_ms: float


class LinkCheckRequest(BaseModel):
    url: str = Field(min_length=1, max_length=2000)


class LinkVerdict(str, Enum):
    BLOQUE = "bloque"
    SUSPECT = "suspect"
    SUR = "sur"


class LinkCheckResult(BaseModel):
    url: str
    domain: str
    verdict: LinkVerdict
    risk_score: float = Field(ge=0.0, le=1.0)
    reasons: list[str]


class ConsentMode(str, Enum):
    PERMANENT = "permanent"
    ON_DEMAND = "a_la_demande"
    OFF = "desactive"


class ConsentRequest(BaseModel):
    mode: ConsentMode
    text_shield: bool = True
    link_shield: bool = True
    behavior_shield: bool = False


class HistoryEntry(BaseModel):
    id: str
    timestamp: str
    channel: str
    text_preview: str
    risk_level: RiskLevel
    scam_type: ScamType
    risk_score: float
