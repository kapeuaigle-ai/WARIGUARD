# WariGuard — MVP

**Bouclier IA contre les arnaques Mobile Money** · Hackathon IA & Mobile Money Afrique 2026 — ClaPay SA.

Application **Flutter** (mobile / web / desktop) avec moteur de détection **100% local** :
aucun message n'est envoyé à un serveur, l'historique est chiffré **AES-256** sur l'appareil.
Un serveur FastAPI optionnel est prêt pour accueillir le modèle ML en cours de développement
(contrat JSON figé — voir [docs/CONTRAT_MODELE.md](docs/CONTRAT_MODELE.md)).

## Couverture du « Done » MVP (plan de répartition)

| Exigence | Où dans l'app |
|---|---|
| Scénario texte/vocal → alerte rouge/orange/vert | **Simuler un appel suspect** (Accueil) → pop-up d'alerte produit par le vrai moteur ; niveaux de risque en couleur |
| Lien malveillant détecté et bloqué avant ouverture | **Bouclier Lien** : chip dans la page d'alerte + « Lien bloqué avant ouverture » avec la raison |
| Écran de consentement ≥ 2 modes d'activation | **Permissions** à l'onboarding + **Paramètres** : mode automatique / à la demande, autoriser l'analyse |
| Preuve données locales/chiffrées (AES-256) | **Paramètres → Données locales & chiffrement** : blob chiffré affiché + déchiffrement, empreinte de clé |
| Chiffres réels dataset + performance | Même écran : précision, rappel, F1, exactitude de type mesurés en direct sur les 67 exemples annotés |

Les deux boucliers du dossier technique apparaissent en français dans la page
d'alerte : **Bouclier Texte** (SMS et transcriptions d'appel) et **Bouclier
Lien** (URL vérifiées avant ouverture).

## Écrans

Onboarding (Bienvenue, Permissions) · Accueil · Pop-up d'alerte (« écran roi »)
· Alertes + détail · Paramètres · À propos. Navigation basse à 4 entrées,
conforme au cahier des charges UX.

## Lancer l'app (démo)

```bash
cd frontend
flutter pub get
flutter run -d chrome     # ou -d windows, ou un téléphone Android branché
```

Build de production :

```bash
flutter build web --release    # puis servir frontend/build/web
flutter build apk --release    # APK Android pour démo sur téléphone
```

## Lancer les tests

```bash
cd frontend
flutter test        # 11 tests : moteur de détection + Bouclier Lien + contrat JSON
```

## Serveur modèle (optionnel — pour le futur classifieur)

```bash
cd backend
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

L'app le détecte automatiquement (écran Sécurité → « Modèle ML distant »).
Intégration du modèle : `backend/app/engine/ml_adapter.py`.

## Structure

```
frontend/          App Flutter (écrans, moteur Dart local, AES-256, tests)
backend/           Serveur FastAPI optionnel (même contrat JSON, adaptateur ML)
data/              Jeu de données annoté (67 exemples FR + Nouchi, 5 classes)
docs/              Contrat modèle + script de démo
```

## Script de démo (2-3 min)

Voir [docs/SCRIPT_DEMO.md](docs/SCRIPT_DEMO.md).
