\# Kit d’intégration IA — WariGuard



\## Responsable



\*\*BROU KOUAKOU CEPHAS\*\*  

Pilote IA de détection — Text Shield \& Behavior Shield



\---



\## Objectif du kit



Ce dossier contient le module IA final permettant d’analyser un SMS, un message WhatsApp ou une transcription simplifiée d’appel afin de détecter une tentative d’arnaque Mobile Money.



Le moteur IA retourne :



\- un score de risque ;

\- un niveau d’alerte : vert, orange ou rouge ;

\- le label : arnaque ou légitime ;

\- le type d’arnaque détecté ;

\- les mots déclencheurs ;

\- un message utilisateur prêt à afficher dans l’interface.



\---



\## Contenu du dossier



```text

KIT\_INTEGRATION\_IA\_CEPHAS/

│

├── wariguard\_binary\_model\_augmented\_hard.pkl

├── wariguard\_multiclass\_model\_augmented\_hard.pkl

├── wariguard\_scenario\_mapping.json

├── WariGuard\_Final\_Fusion\_Engine.ipynb

└── wariguard\_api\_contract\_example.json



Rôle des fichiers

wariguard\_binary\_model\_augmented\_hard.pkl



Modèle binaire.



Il prédit si le texte analysé est :



Plain Text

1

arnaque

Afficher plus de lignes



ou



Plain Text

1

legitime

Afficher plus de lignes

wariguard\_multiclass\_model\_augmented\_hard.pkl



Modèle multiclasse.



Il est utilisé uniquement lorsque le modèle binaire détecte une arnaque.



Il prédit le scénario frauduleux parmi :



Plain Text

1

T1 = Faux agent Mobile Money

2

T2 = Faux transfert erroné

3

T3 = Faux gain / loterie

4

T4 = Phishing / faux lien officiel

5

T5 = Usurpation d'urgence familiale

6

T6 = Fausse promotion opérateur

Afficher plus de lignes

wariguard\_scenario\_mapping.json



Fichier de correspondance entre les codes de scénarios et leurs noms lisibles.



Exemple :



JSON

1

{

2

"T1": "Faux agent Mobile Money",

3

"T2": "Faux transfert erroné",

4

"T3": "Faux gain / loterie",

5

"T4": "Phishing / faux lien officiel",

6

"T5": "Usurpation d'urgence familiale",

7

"T6": "Fausse promotion opérateur"

8

}

Afficher plus de lignes

WariGuard\_Final\_Fusion\_Engine.ipynb



Notebook principal d’intégration.



Il charge :



le modèle binaire ;

le modèle multiclasse ;

le mapping JSON ;

le moteur de règles explicables.



Il contient la fonction principale :



Python

1

analyser\_message\_wariguard(texte)

2

`

Afficher plus de lignes

wariguard\_api\_contract\_example.json



Exemple de sortie JSON du moteur IA.



Ce fichier sert de contrat d’interface pour l’intégration avec le MVP.



Fonction principale



La fonction principale à utiliser est :



Python

1

analyser\_message\_wariguard(texte)

Afficher plus de lignes



Exemple :



Python

1

resultat = analyser\_message\_wariguard(

2

"Bonjour je suis agent Wave, donnez votre code OTP"

3

)

4

 

5

print(resultat)

Afficher plus de lignes

Exemple de sortie JSON

JSON

1

{

2

"score\_risque": 0.92,

3

"niveau\_alerte": "rouge",

4

"label": "arnaque",

5

"type\_scenario": "T1",

6

"type\_arnaque": "Faux agent Mobile Money",

7

"mots\_declencheurs": \[

8

"agent",

9

"code",

10

"otp"

11

],

12

"message\_utilisateur": "🔴 Alerte élevée..."

13

}

Afficher plus de lignes

Champs importants pour l’interface

score\_risque



Score compris entre 0 et 1.



Exemple :



Plain Text

1

0.92 = 92 %

Afficher plus de lignes

niveau\_alerte



Niveau d’alerte à afficher dans l’interface.



Valeurs possibles :



Plain Text

1

vert

2

orange

3

rouge

Afficher plus de lignes



Correspondance :



Plain Text

1

vert = aucun risque détecté

2

orange = prudence

3

rouge = alerte élevée

Afficher plus de lignes

label



Résultat binaire du moteur.



Valeurs possibles :



Plain Text

1

arnaque

2

legitime

Afficher plus de lignes

type\_scenario



Code du scénario détecté.



Exemple :



Plain Text

1

T1

Afficher plus de lignes

type\_arnaque



Nom lisible du scénario détecté.



Exemple :



Plain Text

1

Faux agent Mobile Money

Afficher plus de lignes

mots\_declencheurs



Liste des mots ou expressions ayant contribué à l’alerte.



Exemple :



JSON

1

\["agent", "code", "otp"]

Afficher plus de lignes

message\_utilisateur



Message directement affichable dans l’interface utilisateur.



Exemple :



Plain Text

1

🔴 Alerte élevée

2

Cette communication présente de forts signes d'arnaque.

3

Conseil : ne communiquez aucun code et ne transférez pas d'argent.

Afficher plus de lignes

Dépendances nécessaires



Installer les dépendances Python suivantes :



Shell

1

pip install pandas scikit-learn joblib matplotlib

Afficher plus de lignes

Logique du moteur IA

Plain Text

1

Texte entrant

2

↓

3

Modèle binaire

4

↓

5

Arnaque ou légitime ?

6

↓

7

Si légitime : alerte verte

8

↓

9

Si arnaque : modèle multiclasse

10

↓

11

Type d’arnaque T1 à T6

12

↓

13

Moteur de règles

14

↓

15

Score final + mots déclencheurs

16

↓

17

JSON pour l’application

Afficher plus de lignes

Convention sur les appels



Pour les appels téléphoniques, le champ texte représente une transcription simplifiée des propos de l’interlocuteur externe, c’est-à-dire la personne qui appelle l’utilisateur.



Pour le MVP, le moteur analyse principalement le contenu reçu par l’utilisateur.



Dans une version industrielle, les conversations pourront être structurées avec séparation des locuteurs :



Plain Text

1

APPELANT :

2

UTILISATEUR :

Afficher plus de lignes

Utilisation prévue dans le MVP



Le module IA peut être appelé par l’application de démonstration pour analyser :



un SMS simulé ;

un message WhatsApp simulé ;

une transcription d’appel simulée.



Le résultat JSON permet ensuite à l’interface d’afficher :



une couleur d’alerte ;

un score de risque ;

le type de fraude ;

les mots déclencheurs ;

un conseil utilisateur.

Remarque importante



Cette version est une version MVP.



Les modèles ont été entraînés sur un dataset augmenté avec des cas difficiles.



Pour une mise en production réelle, il faudra enrichir le dataset avec :



plus de messages réels anonymisés ;

davantage de nouchi ;

des conversations d’appel multi-locuteurs ;

des cas terrain collectés auprès d’utilisateurs ivoiriens.

