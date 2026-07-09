# Script de démo WariGuard — 2 min 30

> Préparation : `flutter run -d chrome` lancé AVANT le passage, app sur l'onboarding
> (effacer le stockage du site pour repartir de zéro). Zoom navigateur 110%.

## 0:00 — Consentement (15 s)
- « Avant toute analyse, l'utilisateur choisit. Deux modes : protection permanente,
  ou à la demande. Rien ne tourne sans accord. »
- Sélectionner **À la demande** → **Activer WariGuard**.

## 0:15 — Accueil : des chiffres, pas des promesses (25 s)
- Montrer le bloc **Moteur de détection — chiffres mesurés** : rappel, précision, F1
  calculés en direct sur 67 exemples annotés (FR + Nouchi).
- « Ces chiffres sont recalculés à chaque lancement, sur l'appareil. »

## 0:40 — Text Shield : l'arnaque au faux agent (40 s)
- Onglet **Text Shield** → chip **Faux agent** (transcription d'appel).
- Le message arrive, l'analyse tourne, verdict **ROUGE / DANGER** :
  jauge, type d'arnaque, mots déclencheurs (« code secret », « compte bloqué »),
  recommandation (« un opérateur ne demande JAMAIS votre code »).
- Enchaîner chip **Message légitime** → **VERT**. « Pas de sur-blocage : un vrai
  reçu Orange Money passe. »

## 1:20 — Link Shield : le lien piégé (30 s)
- Onglet **Link Shield** → lien `orange-money-verification.xyz`.
- Verdict **LIEN BLOQUÉ** avant ouverture : usurpation de marque, TLD à risque,
  pas de HTTPS.
- Contraste : `wave.com` → **SÛR**.

## 1:50 — Sécurité : la preuve (30 s)
- Onglet **Sécurité** : montrer le blob **AES-256** (illisible), cliquer
  **Déchiffrer avec la clé locale** → données lisibles. « Tout reste sur le
  téléphone, chiffré. »
- Montrer **Moteur d'analyse** : « Le classifieur CamemBERT arrive — le contrat
  JSON est figé, on bascule ici sans changer une ligne d'interface. »

## 2:20 — Clôture (10 s)
- Retour **Accueil** : compteurs d'activité mis à jour (analyses, menaces).
- « WariGuard : détection locale, consentement d'abord, preuves à l'appui. »

## Plan B (si souci machine)
- Les tests tournent hors UI : `flutter test` (11 verts).
- Captures d'écran de secours dans le dossier de pitch (à générer vendredi).
