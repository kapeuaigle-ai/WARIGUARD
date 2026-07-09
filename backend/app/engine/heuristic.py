"""Moteur heuristique de détection d'arnaques Mobile Money.

Règles pondérées par catégorie, adaptées au contexte ivoirien : français,
Nouchi, scénarios faux agent / faux gain / transfert erroné / phishing.
Produit le même JSON que le futur modèle ML (contrat schemas.AnalysisResult).
"""

import re
import time
import unicodedata

from ..schemas import (
    AnalysisResult,
    Channel,
    RiskLevel,
    ScamType,
    Trigger,
)
from .base import DetectionEngine


def _normalize(text: str) -> str:
    """Minuscule + suppression des accents pour un matching robuste."""
    text = text.lower()
    text = unicodedata.normalize("NFD", text)
    return "".join(c for c in text if unicodedata.category(c) != "Mn")


# (motif regex, poids, catégorie lisible)
# Les poids reflètent la force du signal : demander un code PIN est presque
# toujours une arnaque ; un simple ton d'urgence ne l'est pas seul.
RULES: dict[str, list[tuple[str, float, str]]] = {
    "demande_code": [
        (r"\b(code|pin|mot de passe|otp)\b.{0,40}\b(envoie|envoyer|donne|donner|communique|confirme|confirmer|tape|taper|transmets?)\b", 0.55, "demande de code secret"),
        (r"\b(envoie|donne|communique|confirme|tape)\b.{0,40}\b(ton|votre|le)?\s*(code|pin|mot de passe|otp)\b", 0.55, "demande de code secret"),
        (r"\bcode (secret|de validation|de confirmation|momo|orange money|wave)\b", 0.5, "demande de code secret"),
        (r"\bcompose\w*\b.{0,30}[#*]\d", 0.5, "composition USSD demandée"),
        (r"[#*]\d{2,3}[#*]", 0.35, "syntaxe USSD suspecte"),
    ],
    "faux_agent": [
        (r"\b(agent|conseiller|service client|assistance|technicien|operateur)\b.{0,50}\b(orange|mtn|moov|wave|momo|mobile money)\b", 0.45, "usurpation d'identité d'agent"),
        (r"\b(orange|mtn|moov|wave)\b.{0,30}\b(agent|service|assistance|securite|technique)\b", 0.4, "usurpation d'identité d'opérateur"),
        (r"\b(ton|votre) compte\b.{0,60}\b(bloque|suspendu|desactive|ferme|expirer?|probleme|pirate)\b", 0.45, "menace de blocage de compte"),
        (r"\b(verification|mise a jour|reactiv\w+|regularis\w+)\b.{0,40}\b(compte|sim|carte|numero)\b", 0.35, "prétexte de vérification"),
    ],
    "faux_gain": [
        (r"\b(felicitations?|bravo|gagne|gagnant|remporte)\b", 0.35, "annonce de gain"),
        (r"\b(loterie|tombola|tirage|jackpot|promo(tion)? speciale|jeu concours)\b", 0.4, "loterie fictive"),
        (r"\b(lot|prix|cadeau|bon d'achat|recompense)\b.{0,40}\b(reclamer|recuperer|retirer|recevoir)\b", 0.45, "réclamation de lot"),
        (r"\bfrais (de dossier|de retrait|d'envoi|de livraison)\b", 0.5, "frais à payer d'avance"),
        (r"\b\d{2,3}[ .]?(000|millions?)\b.{0,30}\b(fcfa|francs?|cfa|f)\b", 0.2, "somme d'argent alléchante"),
    ],
    "transfert_errone": [
        (r"\b(envoye|transfere|depose)\b.{0,40}\bpar erreur\b", 0.55, "faux transfert par erreur"),
        (r"\bpar erreur\b.{0,50}\b(renvoie|renvoyer|rembourse|retourne|restitue)\b", 0.55, "demande de remboursement"),
        (r"\b(renvoie|rembourse|retourne)[ -]?(moi)?\b.{0,40}\b(argent|somme|depot|transfert|unites?)\b", 0.4, "demande de renvoi d'argent"),
        (r"\bje me suis trompe\b.{0,40}\b(numero|destinataire)\b", 0.5, "erreur de numéro simulée"),
    ],
    "urgence": [
        (r"\b(urgent|urgence|vite|rapidement|immediatement|tout de suite|maintenant|dernier delai|dans les \d+ (minutes?|heures?))\b", 0.2, "pression temporelle"),
        (r"\b(sinon|avant que|expire|sera (bloque|supprime|ferme))\b", 0.2, "menace conditionnelle"),
        (r"\bne (le )?dis? a personne\b|\bgarde (ca|le) secret\b|\bconfidentiel\b", 0.3, "demande de secret"),
    ],
    "nouchi": [
        (r"\b(mogo|mögö|le vieux pere|vieux pere|tchoko|djossi|gaou|un gbe|c'?est gbe|faut gerer ca|ya foye|choco?ya)\b", 0.15, "expression Nouchi de mise en confiance"),
        (r"\b(bara|go(s)? la|desce?nds? l'argent|fais? vite le truc|c'?est chaud dedans)\b", 0.2, "pression en Nouchi"),
    ],
    "lien": [
        (r"https?://[^\s]+", 0.2, "lien à vérifier"),
        (r"\b(bit\.ly|tinyurl|cutt\.ly|t\.co|goo\.gl|is\.gd|rb\.gy)/", 0.35, "raccourcisseur d'URL"),
        (r"\b(clique|cliquez|ouvre|ouvrez|suis le lien|via le lien)\b", 0.2, "incitation au clic"),
    ],
}

# Catégorie de règles -> type d'arnaque final
CATEGORY_TO_SCAM: dict[str, ScamType] = {
    "demande_code": ScamType.FAUX_AGENT,
    "faux_agent": ScamType.FAUX_AGENT,
    "faux_gain": ScamType.FAUX_GAIN,
    "transfert_errone": ScamType.TRANSFERT_ERRONE,
    "lien": ScamType.PHISHING_LIEN,
    # urgence / nouchi = amplificateurs, pas un type à part entière
}

RECOMMENDATIONS: dict[ScamType, str] = {
    ScamType.FAUX_AGENT: "Raccrochez / ne répondez pas. Un opérateur ne demande JAMAIS votre code. Appelez vous-même le service client officiel.",
    ScamType.FAUX_GAIN: "Ignorez ce message. Aucun gain légitime n'exige de frais ou de code pour être « débloqué ».",
    ScamType.TRANSFERT_ERRONE: "Ne renvoyez rien. Vérifiez votre solde réel dans l'application officielle avant toute action.",
    ScamType.PHISHING_LIEN: "N'ouvrez pas ce lien. Vérifiez-le d'abord avec Link Shield.",
    ScamType.AUCUN: "Aucune action requise. Restez vigilant sur les demandes de code ou d'argent.",
}

RED_THRESHOLD = 0.65
ORANGE_THRESHOLD = 0.35


class HeuristicEngine(DetectionEngine):
    name = "WariGuard-Heuristic"
    version = "1.0.0"

    def __init__(self) -> None:
        self._compiled: list[tuple[re.Pattern[str], float, str, str]] = [
            (re.compile(pattern), weight, label, category)
            for category, rules in RULES.items()
            for pattern, weight, label in rules
        ]

    def analyze(self, text: str, channel: Channel = Channel.SMS) -> AnalysisResult:
        start = time.perf_counter()
        normalized = _normalize(text)

        triggers: list[Trigger] = []
        category_scores: dict[str, float] = {}
        seen_labels: set[str] = set()

        for pattern, weight, label, category in self._compiled:
            match = pattern.search(normalized)
            if not match:
                continue
            category_scores[category] = category_scores.get(category, 0.0) + weight
            if label not in seen_labels:
                seen_labels.add(label)
                snippet = match.group(0).strip()
                triggers.append(Trigger(text=snippet[:60], category=label, weight=weight))

        # Score global : somme plafonnée, avec amplification si urgence + signal fort
        base = sum(min(s, 0.7) for c, s in category_scores.items() if c not in ("urgence", "nouchi"))
        amplifiers = category_scores.get("urgence", 0.0) + category_scores.get("nouchi", 0.0)
        has_core_signal = base > 0
        score = base + (amplifiers if has_core_signal else amplifiers * 0.5)
        score = max(0.0, min(1.0, score))

        # Type d'arnaque dominant
        scam_type = ScamType.AUCUN
        core = {c: s for c, s in category_scores.items() if c in CATEGORY_TO_SCAM}
        if core and score >= ORANGE_THRESHOLD:
            dominant = max(core, key=lambda c: core[c])
            scam_type = CATEGORY_TO_SCAM[dominant]

        if score >= RED_THRESHOLD:
            level = RiskLevel.RED
        elif score >= ORANGE_THRESHOLD:
            level = RiskLevel.ORANGE
        else:
            level = RiskLevel.GREEN

        explanation = self._explain(level, scam_type, triggers, channel)
        latency = (time.perf_counter() - start) * 1000

        return AnalysisResult(
            risk_score=round(score, 3),
            risk_level=level,
            scam_type=scam_type,
            triggers=sorted(triggers, key=lambda t: -t.weight)[:8],
            explanation=explanation,
            recommendation=RECOMMENDATIONS[scam_type],
            model_name=self.name,
            model_version=self.version,
            latency_ms=round(latency, 2),
        )

    @staticmethod
    def _explain(level: RiskLevel, scam_type: ScamType, triggers: list[Trigger], channel: Channel) -> str:
        source = "Ce SMS" if channel == Channel.SMS else "Cet appel"
        if level == RiskLevel.GREEN:
            return f"{source} ne présente aucun signal d'arnaque connu."
        labels = ", ".join(dict.fromkeys(t.category for t in triggers[:4]))
        type_labels = {
            ScamType.FAUX_AGENT: "une usurpation d'identité d'agent Mobile Money",
            ScamType.FAUX_GAIN: "une arnaque au faux gain",
            ScamType.TRANSFERT_ERRONE: "une arnaque au faux transfert erroné",
            ScamType.PHISHING_LIEN: "une tentative de phishing par lien",
            ScamType.AUCUN: "un contenu suspect",
        }
        certainty = "correspond fortement à" if level == RiskLevel.RED else "présente des signes de"
        return f"{source} {certainty} {type_labels[scam_type]}. Signaux détectés : {labels}."
