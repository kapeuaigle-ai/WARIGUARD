# Script de démo WariGuard — 2 min 30

> Préparation : `flutter run -d chrome` (ou l'APK sur téléphone) lancé AVANT le
> passage, stockage du site vidé pour repartir de l'onboarding.

## 0:00 — Onboarding (20 s)
- Écran **Bienvenue** : « Le bouclier intelligent contre le phishing vocal ». → *Continuer*.
- Écran **Permissions** : micro + superposition d'écran, chacune justifiée.
  « WariGuard n'accède à ces fonctions que pendant un appel suspect. Rien n'est
  enregistré. » → *Autoriser et continuer*.

## 0:20 — Accueil (20 s)
- Bouclier vert **Protection active**, toggle, compteur de menaces, dernière analyse.
- « La sécurité doit être invisible jusqu'à ce qu'elle soit nécessaire. »

## 0:40 — L'écran roi : le pop-up d'alerte (50 s)
- Appuyer sur **Simuler un appel suspect**. Le pipeline réel tourne : le moteur
  analyse la transcription et produit l'alerte (rien n'est scripté).
- Le pop-up se superpose à l'app : **RISQUE ÉLEVÉ**, « Arnaque probable détectée »,
  3 déclencheurs (demande de code secret, usurpation d'identité d'agent, menace
  de blocage), et le chip **Bouclier Texte** qui a détecté la menace.
- Trois actions : **Raccrocher** (rouge, dominante), **Signaler** (orange),
  **Continuer l'appel** (discret). → *Raccrocher*.
- L'app bascule sur Alertes : l'entrée est loguée avec le statut « Bloqué ».

## 1:30 — Alertes & détail (35 s)
- Ouvrir **SMS « Vous avez gagné 500 000 FCFA »**.
- Les deux boucliers apparaissent : **Bouclier Texte** + **Bouclier Lien**, avec
  « Lien bloqué avant ouverture — raccourcisseur d'url (bit.ly) ».
- **Pourquoi cette détection** : réclamation de lot, loterie fictive, annonce de gain.
- **Conseil** : « Aucun gain légitime n'exige de frais ou de code. »

## 2:05 — Preuves (20 s)
- **Paramètres** : modes de protection (automatique / à la demande), autorisations.
  Couper le micro → bandeau orange « Action requise » sur l'Accueil : aucun crash,
  mode dégradé (critère d'acceptation du cahier des charges). Réactiver.
- **Données locales & chiffrement** : le blob **AES-256** illisible, puis
  *Déchiffrer avec la clé locale*. Chiffres réels du moteur : rappel 98 %,
  précision 98 %, F1 98 %, sur 67 exemples annotés.

## 2:25 — Clôture (5 s)
- « Détection locale, consentement d'abord, preuves à l'appui. »

## Plan B (si souci machine)
- Les tests tournent hors UI : `flutter test` (11 verts).
