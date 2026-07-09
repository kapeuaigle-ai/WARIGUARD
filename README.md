# WariGuard — MVP

**Bouclier IA contre les arnaques Mobile Money** · Hackathon IA & Mobile Money Afrique 2026 — ClaPay SA.

Application **Flutter** (mobile / web / desktop) avec moteur de détection **100% local** :
aucun message n'est envoyé à un serveur, l'historique est chiffré **AES-256** sur l'appareil.
Un serveur FastAPI optionnel est prêt pour accueillir le modèle ML en cours de développement
(contrat JSON figé — voir [docs/CONTRAT_MODELE.md](docs/CONTRAT_MODELE.md)).

## Couverture du « Done » MVP (plan de répartition)

| Exigence | Où dans l'app |
|---|---|
| Scénario texte/vocal → alerte rouge/orange/vert | Onglet **Text Shield** (simulateur SMS + transcription d'appel, jauge + signaux déclencheurs) |
| Lien malveillant détecté et bloqué avant ouverture | Onglet **Link Shield** + blocage inline depuis Text Shield |
| Écran de consentement ≥ 2 modes d'activation | **Onboarding** au premier lancement (permanent / à la demande / désactivé), modifiable dans **Sécurité** |
| Preuve données locales/chiffrées (AES-256) | Onglet **Sécurité** : blob chiffré affiché + déchiffrement à la demande, empreinte de clé |
| Chiffres réels dataset + performance | **Accueil** : précision, rappel, F1, exactitude de type mesurés en direct sur les 67 exemples annotés |

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
flutter test        # 11 tests : moteur de détection + Link Shield + contrat JSON
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
