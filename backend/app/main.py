"""Serveur modèle WariGuard (optionnel pour la démo).

L'app Flutter fonctionne 100% en local. Ce serveur FastAPI existe pour :
  1. Servir le futur modèle ML de Cephas derrière le même contrat JSON.
  2. Montrer l'architecture cible (app -> API modèle) au jury.

Lancement :
    cd backend
    python -m venv .venv && .venv\\Scripts\\activate
    pip install -r requirements.txt
    uvicorn app.main:app --reload --port 8000

Bascule vers le modèle ML (quand livré) :
    WARIGUARD_ENGINE=ml uvicorn app.main:app --port 8000
"""

import json
import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .engine.base import DetectionEngine
from .engine.heuristic import HeuristicEngine
from .link_shield import check_link
from .schemas import (
    AnalysisResult,
    AnalyzeRequest,
    LinkCheckRequest,
    LinkCheckResult,
    RiskLevel,
)

DATASET_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "dataset_wariguard.json"


def build_engine() -> DetectionEngine:
    if os.getenv("WARIGUARD_ENGINE", "heuristic") == "ml":
        from .engine.ml_adapter import MLEngine

        return MLEngine()
    return HeuristicEngine()


engine = build_engine()

app = FastAPI(
    title="WariGuard — API modèle",
    version="1.0.0",
    description="Contrat JSON partagé avec l'app Flutter. Voir docs/CONTRAT_MODELE.md.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # démo hackathon — restreindre en production
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
def health() -> dict:
    return {
        "status": "ok",
        "engine": {"name": engine.name, "version": engine.version},
    }


@app.post("/api/analyze", response_model=AnalysisResult)
def analyze(req: AnalyzeRequest) -> AnalysisResult:
    return engine.analyze(req.text, req.channel)


@app.post("/api/link/check", response_model=LinkCheckResult)
def link_check(req: LinkCheckRequest) -> LinkCheckResult:
    return check_link(req.url)


@app.get("/api/stats")
def stats() -> dict:
    """Métriques réelles : le moteur actif évalué sur le dataset annoté."""
    data = json.loads(DATASET_PATH.read_text(encoding="utf-8"))
    examples = data["exemples"]

    tp = fp = tn = fn = 0
    type_correct = 0
    by_type: dict[str, int] = {}
    for ex in examples:
        label = ex["label"]
        by_type[label] = by_type.get(label, 0) + 1
        is_scam = label != "legitime"
        result = engine.analyze(ex["text"], ex["channel"])
        predicted_scam = result.risk_level != RiskLevel.GREEN
        if is_scam and predicted_scam:
            tp += 1
            if result.scam_type.value == label:
                type_correct += 1
        elif is_scam:
            fn += 1
        elif predicted_scam:
            fp += 1
        else:
            tn += 1

    precision = tp / (tp + fp) if tp + fp else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    return {
        "dataset": {"total": len(examples), "par_type": by_type, "meta": data["meta"]},
        "modele": {"name": engine.name, "version": engine.version},
        "metriques": {
            "precision": round(precision, 3),
            "rappel": round(recall, 3),
            "f1": round(2 * precision * recall / (precision + recall), 3)
            if precision + recall
            else 0.0,
            "exactitude_type": round(type_correct / tp, 3) if tp else 0.0,
            "matrice": {"tp": tp, "fp": fp, "tn": tn, "fn": fn},
        },
    }
