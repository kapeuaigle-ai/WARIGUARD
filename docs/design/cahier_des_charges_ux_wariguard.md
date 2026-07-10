# Cahier des charges UX/UI — WariGuard (MVP hackathon)

**Objectif du document :** définir précisément le contenu, les états et les critères d'acceptation de chaque écran.

---

## 1. Principes UX directeurs

- **La sécurité doit être invisible jusqu'à ce qu'elle soit nécessaire.** En dehors d'une menace, l'app ne réclame pas d'attention.
- **Le pop-up d'alerte est l'écran roi.** Il doit être compris en moins de 3 secondes de lecture, sans effort.
- **Confiance par la transparence.** On n'affiche jamais un score seul — toujours accompagné du "pourquoi" (déclencheurs explicites).
- **Cohérence par les composants.** Tout est construit en Auto Layout Figma pour que les 4 devs réutilisent les mêmes briques sans dériver visuellement.

## 2. Arborescence de navigation (scope MVP)

```
Onboarding (1er lancement uniquement)
 ├── Bienvenue
 └── Permissions

Accueil
 ├── Toggle protection
 ├── Bouton "Simuler un appel suspect" (mode démo)
 └── Résumé (dernière analyse, nb menaces)

Pop-up d'alerte (overlay système, déclenché depuis n'importe où)

Alertes / Historique
 └── Détail d'une alerte

Paramètres

À propos
```

Pas de menu latéral ni de navigation profonde pour le MVP : une barre de navigation basse à 4 entrées (Accueil, Alertes, Paramètres, À propos) suffit.

## 3. Écrans détaillés

### 3.0 Onboarding

**Écran 1 — Bienvenue**
- *Objectif :* établir la confiance en une lecture, sans scroll.
- *Contenu :* icône bouclier, titre ("WariGuard, le bouclier intelligent contre le phishing vocal"), une phrase de sous-titre, bouton unique "Continuer".
- *États :* statique, un seul.
- *Critère d'acceptation :* un seul CTA visible à l'écran, pas de texte secondaire distrayant.

**Écran 2 — Permissions**
- *Objectif :* obtenir micro + superposition d'écran, avec justification claire de chaque demande.
- *Contenu :* liste de 2 permissions, une icône + une phrase "pourquoi" pour chacune, bouton "Autoriser et continuer".
- *États :* permission accordée / refusée.
- *Comportement si refus :* l'app reste utilisable en mode dégradé — un bandeau permanent sur l'Accueil invite à activer la permission manquante, pas de blocage total ni de crash.
- *Critère d'acceptation :* aucun écran blanc ou état indéfini si l'utilisateur refuse une permission.

### 3.1 Accueil

- *Objectif :* rassurer d'un coup d'œil et servir de point d'entrée au mode démo.
- *Contenu :*
  - Indicateur d'état visuel (bouclier vert = actif, rouge = désactivé)
  - Toggle Activer / Désactiver
  - Dernière analyse (date/heure)
  - Nombre de menaces détectées
  - Bouton "Simuler un appel suspect" (mode démo — visible pour le hackathon, à masquer ou retirer en version publique)
- *États :* protection active / désactivée / permission manquante (bandeau d'avertissement).
- *Interactions :* le toggle doit changer d'état visuellement en moins d'une seconde ; le bouton démo lance le scénario audio pré-enregistré dans le pipeline réel.
- *Critère d'acceptation :* aucune latence perçue sur le toggle ; le bandeau d'avertissement disparaît automatiquement dès que la permission est accordée.

### 3.2 Pop-up d'alerte (overlay) — écran prioritaire

- *Objectif :* alerter sans ambiguïté, lisible en moins de 3 secondes.
- *Contenu :*
  - En-tête avec niveau de risque (ÉLEVÉ / MOYEN)
  - Liste des déclencheurs, 2-3 lignes maximum — jamais un paragraphe
  - 3 boutons empilés : **Raccrocher** (rouge, action visuellement dominante), **Signaler** (orange), **Continuer l'appel** (texte simple, discret)
- *États :* déclenchement automatique (pipeline réel) ou manuel (mode démo) — **le contenu et l'apparence doivent être strictement identiques dans les deux cas**, sans indice visuel qui trahirait le mode démo.
- *Interactions :*
  - Raccrocher → coupe l'appel, retour à l'Accueil, entrée loguée dans l'historique avec statut "bloqué"
  - Signaler → entrée loguée avec statut "signalé", ferme le pop-up
  - Continuer l'appel → ferme le pop-up, entrée loguée avec statut "ignoré"
- *Point à trancher avec l'équipe :* faut-il un court délai minimum avant que "Continuer l'appel" soit cliquable, pour éviter une fermeture réflexe sans lecture ? À décider avant l'implémentation de Dev B.
- *Critère d'acceptation :* le pop-up s'affiche par-dessus n'importe quelle autre app ouverte, sans exception.

### 3.3 Alertes / Historique

- *Objectif :* consulter les menaces passées, construire la confiance dans la durée.
- *Contenu :* liste de cartes (icône par type, date, type de menace, badge de statut : bloqué / signalé / ignoré). État vide avec message rassurant plutôt qu'un écran blanc au premier lancement.
- *Détail au clic :* pourquoi détecté (déclencheurs), conseil d'action, bouton "partager avec la communauté" si pas déjà fait pendant l'appel.
- *Critère d'acceptation :* tri du plus récent au plus ancien ; distinction visuelle claire entre niveaux de risque par la couleur du badge, pas seulement par le texte.

### 3.4 Paramètres (version légère MVP)

- *Objectif :* donner un sentiment de contrôle sans complexité.
- *Contenu :* toggle mode de protection (auto / à la demande), toggle autoriser l'analyse, sélecteur de langue (une seule option active pour le MVP, mais le sélecteur reste visible).
- *Critère d'acceptation :* chaque toggle affiche un texte explicite ("activé"/"désactivé"), pas uniquement une couleur — pour rester lisible même en cas de daltonisme.

### 3.5 À propos

- *Objectif :* rassurer légalement, réduire la charge de support.
- *Contenu :* mission en 2-3 phrases, lien vers la politique de confidentialité, FAQ (2-3 questions maximum pour le MVP), contact support.
- *Critère d'acceptation :* écran entièrement statique, aucune logique conditionnelle.

## 4. Composants transverses (design system)

| Composant | Réutilisé sur |
|---|---|
| Bouclier d'état (2 variantes : actif / inactif) | Accueil |
| Carte d'alerte | Accueil (résumé) et Historique (liste complète) |
| Bouton primaire (rouge, plein) | Pop-up ("Raccrocher") |
| Bouton secondaire (orange, plein) | Pop-up ("Signaler") |
| Bouton tertiaire (texte, discret) | Pop-up ("Continuer"), navigation |
| Toggle avec libellé texte | Accueil, Paramètres |

Tous ces composants doivent être construits une seule fois en Auto Layout Figma et réutilisés — pas redessinés par écran.

## 5. Parcours utilisateurs à valider avant la démo

1. Premier lancement → Onboarding → Permissions → Accueil
2. Appel suspect détecté → pop-up automatique → action utilisateur → retour à l'état normal
3. Consultation de l'historique après une alerte ignorée
4. Démo live : bouton "Simuler un appel suspect" → même pop-up, même parcours que le cas réel

## 6. Hors scope MVP (explicite)

- KYC / vérification d'identité
- Vue opérateur / dashboard institutionnel
- Fonctionnalité communautaire complète (uniquement un compteur statique sur l'Accueil)
- Paramètres avancés (liste blanche de contacts, sensibilité IA ajustable)
- Support multilingue au-delà du français

## 7. Critères d'acceptation globaux

- Aucun écran ne plante si une permission est refusée
- Le pop-up est visuellement identique qu'il soit déclenché par le pipeline réel ou par le mode démo
- Le temps entre le lancement de l'app et l'affichage de l'Accueil est minimal — pas d'écran de chargement prolongé
