# 🇫🇷 Analyse de la dépendance sectorielle de la France vis-à-vis de ses partenaires OCDE (2017–2023) — SAS

##  Contexte & Problématique
Ce projet étudie la **dépendance sectorielle de la France** vis-à-vis d’un ensemble de partenaires de l’**OCDE** entre **2017 et 2023**, en lien avec des **chocs internationaux** (COVID-19, tensions sur les chaînes d’approvisionnement, inflation, événements géopolitiques, etc.).

L’objectif est de mesurer :
- la **dépendance globale** de la France (importations) vis-à-vis de certains pays,
- la **dépendance sectorielle** (par grands secteurs SITC),
- la **concentration** des importations via l’indice **HHI**,
- et d’estimer un **modèle gravitaire** (gravity model) avec contrôles macroéconomiques et effets fixes.

---

##  Pays partenaires (OCDE) étudiés
France (FRA), Allemagne (DEU), Italie (ITA), Espagne (ESP), Belgique (BEL), Pays-Bas (NLD), Pologne (POL), Royaume-Uni (GBR), États-Unis (USA), Canada (CAN), Japon (JPN), Corée du Sud (KOR), Mexique (MEX), Chili (CHL), Australie (AUS), Irlande (IRL).

---

##  Sources de données
- **BACI (CEPII)** — flux commerciaux bilatéraux au niveau **année × exportateur × importateur × produit (HS6)**  
  Variables principales : année `t`, exportateur `i`, importateur `j`, produit `k`, valeur `v`, quantité `q`.
- **Table de concordance HS2007 → SITC Rev.4** — conversion produits → secteurs
- **CEPII Distances** — distance bilatérale (km)
- **CEPII GEO / Langues** — variable de langue (langue principale)
- **World Bank** — **PIB** et **Population** (2017–2023)

⚠️ **Important :** le dataset complet BACI est très volumineux (**~5GB**) et **n’est pas inclus** dans ce dépôt GitHub.

---

##  Méthodologie (pipeline)
### 1) Import & concaténation (2017–2023)
- Import des fichiers annuels BACI (version indiquée dans le code)
- Concaténation dans une base unique

### 2) Filtrage (pays OCDE)
- Conservation uniquement des flux où **exportateur ET importateur** appartiennent à la liste OCDE retenue.

### 3) Construction sectorielle
- Transformation de `k` (HS6) pour correspondre au format de la table de passage
- Fusion avec la table HS→SITC Rev.4
- Création d’un secteur agrégé `s` (2 premiers caractères de SITC)

### 4) Valeur unitaire & agrégation
- Valeur unitaire `V = v / q` (avec gestion des quantités nulles)
- Calcul d’une **moyenne pondérée** de la valeur unitaire par `(i, j, t, s)` via une pondération basée sur `q`
- Agrégation finale par `(année, exportateur, importateur, secteur)` :
  - `quantite = sum(q)`
  - `valeur_unitaire = sum(V * pondération)`

### 5) Enrichissement par variables externes
- Ajout du pays exportateur/importateur en ISO3
- Merge avec :
  - **distance bilatérale**
  - **langue** (langue exportateur/importateur)
  - **PIB** exportateur/importateur
  - **population** exportateur/importateur

---

##  Analyses descriptives principales
### Dépendance globale (France importatrice)
- Construction de la sous-base `fr_import` (France comme importateur)
- Parts des partenaires dans les importations françaises (en quantité)
- Classement des partenaires selon les quantités importées
- Évolution des parts des principaux partenaires sur 2017–2023

### Dépendance sectorielle
- Parts des partenaires **par secteur** et par année
- Identification du pays “leader” (part maximale) pour chaque secteur/année

### Concentration (HHI)
- Calcul du **HHI des importations françaises** par année  
  (somme des parts au carré, donnant plus de poids aux partenaires dominants)

---

##  Modèle économétrique (Gravity Model)
### Variable expliquée
- `log_quantite` : logarithme de la quantité importée/exportée agrégée

### Variables explicatives (exemples)
- `log_valeur_unit`
- `log_dist_km`
- `log_pib_exp`, `log_pib_impo`
- `log_pop_exp`, `log_pop_impo`
- `langue` : indicatrice “même langue” (exportateur = importateur)

### Effets fixes / contrôles
- Indicatrices pays exportateur & importateur
- Effets croisés **année × secteur** via indicatrices `tsYYYY_SS`

Estimation via `PROC REG` (résidus + valeurs prédites sauvegardés), puis visualisation de la densité des résidus.

---

##  Contenu du dépôt
- `france_ocde_dependency.sas` → **code SAS complet**
- `results.pdf` → **résultats** (sorties, tableaux, graphiques, régression)
- `README.md` → description détaillée du projet

---

## ▶ Reproductibilité
Ce dépôt est pensé comme **portfolio / démonstration** :
- Le code est fourni intégralement
- Les résultats sont fournis dans `results.pdf`
- Les bases complètes ne sont pas incluses (taille + contraintes de distribution)

Pour reproduire l’exécution :
1. Télécharger les données (BACI, CEPII, World Bank)
2. Mettre à jour les chemins `C:\Users\...` dans le code (paths locaux)
3. Lancer le script SAS


---

##  Author
**Ayoub Zougagh**  
GitHub: https://github.com/zougaghayoub00-web