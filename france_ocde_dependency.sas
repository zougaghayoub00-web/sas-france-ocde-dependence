/*--------------------------------------------------------------*
 |  PROJET SAS –                                                 |
 |                                                              |
 |  Problématique :                                             |
 |  Analyse de la dépendance sectorielle de la France vis-à-vis |
 |  de ses partenaires de l’OCDE entre 2017 et 2023, en lien    |
 |  avec les chocs internationaux                               |
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 |  LISTE DES PARTENAIRES (code BACI)                     |
 |                                                              |
 |  FRA : France                                                |
 |  DEU : Allemagne                                             |
 |  ITA : Italie                                                |
 |  ESP : Espagne                                               |
 |  BEL : Belgique                                              |
 |  NLD : Pays-Bas                                              |
 |  POL : Pologne                                               |
 |  GBR : Royaume-Uni                                           |
 |  USA : États-Unis                                            |
 |  CAN : Canada                                                |
 |  JPN : Japon                                                 |
 |  KOR : Corée du Sud                                          |
 |  MEX : Mexique                                               |
 |  CHL : Chili                                                 |
 |  AUS : Australie                                             |
 |  IRL : Irlande                                               |
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 |  SOURCE DES DONNÉES – BACI (CEPII)                           |
 |                                                              |
 |  Version      : 202501                                       |
 |  Release Date : 2025-01-30                                   |
 |  Lien         : http://www.cepii.fr/CEPII/en/bdd_modele/     |
 |                 bdd_modele_item.asp?id=37                    |
 |                                                              |
 |  Structure : flux commerciaux au niveau                      |
 |              année – exportateur – importateur – produit.   |
 |  Nomenclature produits : HS6.                               |
 |  Variables :                                                 |
 |      t : année                                               |
 |      i : exportateur (code ISO3 num.)                        |
 |      j : importateur (code ISO3 num.)                        |
 |      k : produit                                             |
 |      v : valeur (en milliers USD)                            |
 |      q : quantité (en tonnes)                                |
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 |  DÉFINITION DU LIBNAME                                       |
 *--------------------------------------------------------------*/

libname in "C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects";

/*--------------------------------------------------------------*
 |  PARTIE 1 – Importation des bases BACI 2017–2023             |
 |                                                              |
 |  Objectif : importer les fichiers BACI (HS07) pour           |
 |  les années 2017 à 2023 dans des tables SAS :                |
 |      baci2017, baci2018, ..., baci2023                       |
 *--------------------------------------------------------------*/

/* Macro  d’import des bases de données*/
%macro import_tables(
    fichier=,
    prefixe_fichier=,
    annee_debut=,
    annee_fin=
);

    %do year = &annee_debut %to &annee_fin;

        data baci&year;
            infile "&fichier./&prefixe_fichier.&year._V202501.csv"
                   dsd
                   dlm=","
                   firstobs=2;
            input
                t      /* année */
                i      /* exportateur */
                j      /* importateur */
                k  $   /* produit HS (caractère) */
                v      /* valeur en milliers USD */
                q      /* quantité en tonnes */
            ;
        run;

    %end;

%mend import_tables;

/* Appel de la macro pour les années 2017 à 2023
   – base BACI HS07, version 202501 */
%import_tables(
    fichier=C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects\bases de donées,
    prefixe_fichier=BACI_HS07_Y,
    annee_debut=2017,
    annee_fin=2023
);







 /*--------------------------------------------------------------*
 |   PARTIE 2 – Préparation de la base complète BACI 2017–2023   |
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 | 1. Concaténation des tables annuelles                        |
 |    -> Création d’une base unique : baci100                   |
 *--------------------------------------------------------------*/

data baci100;
    set baci2017
        baci2018
        baci2019
        baci2020
        baci2021
        baci2022
        baci2023;
run;


/*--------------------------------------------------------------*
 | 2. Filtrage des observations: beaucoup de valeurs manquantes  |
 |   dans certaines variables                                    |
 |                                                               |
 |    Solution : limiter l’analyse aux partenaires de l’OCDE.    |
 *--------------------------------------------------------------*/

/* Liste des 16 pays OCDE retenus (codes BACI = ISO3 numériques)
    FRA : 251      BEL : 56       MEX : 484      USA : 842
    DEU : 276      NLD : 528      CHL : 152      CAN : 124
    ITA : 380      POL : 616      AUS : 36       JPN : 392
    ESP : 724      GBR : 826      IRL : 372      KOR : 410
*/
%let ocde_codes =
    251 276 380 724 56 528 616 826
    842 124 392 410 484 152 36 372;

/*--------------------------------------------------------------*
 | 3. Conservation uniquement des flux impliquant ces pays      |
 *--------------------------------------------------------------*/

data baci100;
    set baci100;

    /* Garder uniquement les lignes où exportateur ET importateur
       appartiennent à la liste OCDE */
    if i not in (&ocde_codes) then delete;
    if j not in (&ocde_codes) then delete;

run;




/*--------------------------------------------------------------*
 | Transformation du code produit (k)                           |
 | Objectif : insérer un point après les 4 premiers caractères  |
 | Exemple : "840820" -> "8408.20"                              |
 *--------------------------------------------------------------*/

data baci100;
    set baci100;
    k2 = cats(substr(k, 1, 4), '.', substr(k, 5));
    drop k;
run;


/*--------------------------------------------------------------*
 |  IMPORTATION DE LA TABLE DE passage HS2007  SITC Rev.4       |
 *--------------------------------------------------------------*/

proc import
    out     = pass
    datafile= "C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects\bases de donées\UN Comtrade Conversion table HS2007 to SITCRev4.xls"
    dbms    = xls
    replace;
run;

/*--------------------------------------------------------------*
 |  NETTOYAGE DE LA TABLE DES SECTEURS                         |
 |  - On conserve uniquement les variables HS07 et S4          |
 |  - On supprime les lignes sans correspondance SITC (S4 vide)|
 *--------------------------------------------------------------*/

data pass;
    set pass;
    keep HS07 S4;
    if S4 = "" then delete;
run;

/*--------------------------------------------------------------*
 |  ALIGNEMENT DES CLÉS DANS LES DEUX TABLES                   |
 |  Objectif : préparer la fusion sur le code produit          |
 |  - baci100 : clé = k2 (de type HS07 au format xxxx.xx)      |
 |  - pass    : clé = HS07                                     |
 *--------------------------------------------------------------*/

proc sort data=baci100;
    by k2;
run;

proc sort data=pass;
    by HS07;
run;

/*--------------------------------------------------------------*
 |  FUSION BACI + TABLE DE CONCORDANCE                         |
 |  - Ajout du secteur SITC (S4) à chaque ligne de baci100     |
 |  - Renommage : HS07 -> k2, S4 -> secteur                      |
 |  - Création d’un agrégat sectoriel plus grossier : s       |
 |    (les 2 premiers caractères de S4)                        |
 *--------------------------------------------------------------*/

data baci100;
    merge
        baci100(in=in1)
        pass   (in=in2 rename=(HS07 = k2
                               S4   = secteur));
    by k2;
    if in1;
    s = substr(secteur, 1, 2);

    drop secteur;
run;



/*--------------------------------------------------------------*
 |  Construction de la valeur unitaire (V)                      |
 *--------------------------------------------------------------*/

data baci100;
    set baci100;
    if q = "" then q = 0;
    if q > 0 then V = v / q;
    else V = 0; 
run;


/*--------------------------------------------------------------*
 |  Pondération à l’intérieur de (i, j, t, s)                   |
 |  - ponderation = q / somme(q)                                |
 |  - Si V = 0, la pondération = 0                              |
 *--------------------------------------------------------------*/

proc sql;
    create table baci95 as   
    select *,
           case 
               when V = 0 then 0
               else q / sum(q)
           end as ponderation
    from baci100
    group by i, j, t, s;
quit;


/*----------------------------------------------------------------------*
 |  Agrégation par année – pays – secteur pays exportateur/importateur  |
 |  - quantite        : somme des q                                     |
 |  - la valeur unitaire moyen pondérer : somme(V * ponderation)        |
 *----------------------------------------------------------------------*/

proc sql;
    create table baci90 as
    select t,
           i,
           j,
           s,
           sum(q)               as quantite,
           sum(V * ponderation) as valeur_unitaire
    from baci95
    group by t, i, j, s;
quit;

/* 105105 rows and 6 columns*/


/*--------------------------------------------------------------*
 |  IMPORTATION DE LA TABLE DES CODES PAYS                      |
 *--------------------------------------------------------------*/

data country_codes;
    infile "C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects\bases de donées\country_codes_V202501.csv"
           dlm=";"
           dsd
           firstobs=2;
    input country_code
          country_name  $
          country_iso2  $
          country_iso3  $;
    ;  /* adapte les variables selon ta table */
run;


/*--------------------------------------------------------------*
 |  AJOUT DU PAYS EXPORTATEUR (pays_expo)                       |
 *--------------------------------------------------------------*/

/* Tri des tables sur le code pays exportateur (i / country_code) */
proc sort data=baci90;
    by i;
run;

proc sort data=country_codes;
    by country_code;
run;

/* Merge pour faire apparaître le pays exportateur (ISO3) exp: FRA */
data baci90;
    merge baci90       (in=in1)
          country_codes(in=in2 rename=(country_code = i
                                       country_iso3 = pays_expo));
    by i;
    if in1;
run;


/*--------------------------------------------------------------*
 |  AJOUT DU PAYS IMPORTATEUR (pays_impo)                       |
 *--------------------------------------------------------------*/

/* Tri des tables sur le code pays importateur (j / country_code) */
proc sort data=baci90;
    by j;
run;

proc sort data=country_codes;
    by country_code;
run;

/* Merge pour faire apparaître le pays importateur (ISO3) */
data baci90;
    merge baci90       (in=in1)
          country_codes(in=in2 rename=(country_code = j
                                       country_iso3 = pays_impo));
    by j;
    if in1;
    keep t i j s quantite valeur_unitaire pays_expo pays_impo;
run;



/*--------------------------------------------------------------*
 |  IMPORTATION DE LA BASE DES DISTANCES CEPII                 |
 *--------------------------------------------------------------*/

proc import
    out     = dist
    datafile= "C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects\dist_cepii.xls"
    dbms    = xls
    replace;
run;


/*--------------------------------------------------------------*
 |  HARMONISATION DES LONGUEURS DES CLÉS DE JOINTURE           |
 |  -> évite les WARNING sur pays_expo / pays_impo             |
 *--------------------------------------------------------------*/

/* pays_expo / pays_impo dans baci90 en $3 (ISO3) */
data baci90;
    length pays_expo $3 pays_impo $3;
    set baci90;
run;

/* iso_o / iso_d dans dist en $3 (ISO3) */
data dist;
    length iso_o $3 iso_d $3;
    set dist;
run;


/*--------------------------------------------------------------*
 |  Tri dES BASES AVANT FUSION                                  |
 *--------------------------------------------------------------*/
proc sort data=baci90;
    by pays_expo pays_impo;
run;
proc sort data=dist;
    by iso_o iso_d;
run;


/*--------------------------------------------------------------*
 |  MERGE BACI + DISTANCES CEPII                               |
 |  - Jointure sur (pays_expo, pays_impo)                      |
 |  - dist_km : distance bilatérale en km                      |
 *--------------------------------------------------------------*/

data baci90;
    merge baci90(in=in1)
          dist  (in=in2 rename=(iso_o = pays_expo
                                iso_d = pays_impo
                                dist  = dist_km));
    by pays_expo pays_impo;
    if in1;

    keep t i j s quantite valeur_unitaire pays_expo pays_impo dist_km;
run;


/*--------------------------------------------------------------*
 |  IMPORTATION DE LA BASE DES LANGUES (GEO CEPII)             |
 *--------------------------------------------------------------*/

proc import
    out     = lang
    datafile= "C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects\geo_cepii.xls"
    dbms    = xls
    replace;
run;


/*--------------------------------------------------------------*
 |  FILTRAGE SUR LES 16 PAYS OCDE + VARIABLES UTILES           |
 |  - iso3      : code ISO3 du pays                            |
 |  - lang20_1  : langue principale (par la population)        |
 *--------------------------------------------------------------*/

data lang;
    set lang;

    /* Garder uniquement les 16 pays sélectionnés */
    if iso3 not in (
        'FRA', 'DEU', 'ITA', 'ESP', 'BEL', 'NLD', 'POL', 'GBR',
        'USA', 'CAN', 'JPN', 'KOR', 'MEX', 'CHL', 'AUS', 'IRL'
    ) then delete;

    /* Ne garder que les colonnes utiles */
    keep iso3 lang20_1;
run;

/* Suppression des doublons éventuels par pays */
proc sort data=lang nodupkey;
    by iso3;
run;

/*--------------------------------------------------------------*
 |  Rappel :                                                   |
 |  - langoff_1 : langue officielle                            |
 |  - lang20_1  : langue principale dans la population         |
 |    -> c’est lang20_1 que tu utilises dans ton modèle        |
 *--------------------------------------------------------------*/


/*--------------------------------------------------------------*
 |  AJOUT DE LA LANGUE DU PAYS EXPORTATEUR (lang_expo)         |
 *--------------------------------------------------------------*/

proc sort data=baci90;
    by pays_expo;
run;

proc sort data=lang;
    by iso3;
run;

data baci90;
    merge baci90(in=in1)
          lang  (in=in2 rename=(iso3     = pays_expo
                                lang20_1 = lang_expo));
    by pays_expo;
    if in1;
run;


/*--------------------------------------------------------------*
 |  AJOUT DE LA LANGUE DU PAYS IMPORTATEUR (lang_impo)         |
 *--------------------------------------------------------------*/

proc sort data=baci90;
    by pays_impo;
run;

proc sort data=lang;
    by iso3;
run;

data baci90;
    merge baci90(in=in1)
          lang  (in=in2 rename=(iso3     = pays_impo
                                lang20_1 = lang_impo));
    by pays_impo;
    if in1;

    /* Variables finales conservées */
    keep t i j s quantite valeur_unitaire
         pays_expo pays_impo dist_km
         lang_impo lang_expo;
run;


/*--------------------------------------------------------------*
 |  IMPORTATION DE LA BASE DES PIB (World Bank)                |
 *--------------------------------------------------------------*/

proc import
    out     = pib
    datafile= "C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects\API_NY.GDP.MKTP.CD_DS2_en_excel_v2_130130.xls"
    dbms    = xls
    replace;
run;


/*--------------------------------------------------------------*
 |  FILTRAGE SUR LES 16 PAYS ET VARIABLES D’INTÉRÊT            |
 |  - Variables gardées :                                      |
 |      Country_Name                                           |
 |      Country_Code (ISO3)                                    |
 |      _2017 _2018 ... _2023 (PIB en valeur courante)         |
 *--------------------------------------------------------------*/

data pib;
    set pib;

    keep Country_Name Country_Code
         _2017 _2018 _2019 _2020 _2021 _2022 _2023;

    if Country_Code not in (
        'FRA', 'DEU', 'ITA', 'ESP', 'BEL', 'NLD', 'POL', 'GBR',
        'USA', 'CAN', 'JPN', 'KOR', 'MEX', 'CHL', 'AUS', 'IRL'
    ) then delete;
run;


/*--------------------------------------------------------------*
 |  RESTRUCTURATION : ANNÉES EN LIGNES AU LIEU DE COLONNES     |
 |  -> Création de pib2017, pib2018, ..., pib2023              |
 |  -> Chaque table a : Country_Code, pib, t                   |
 *--------------------------------------------------------------*/

/* Macro pour créer une table par année */
%macro pib_tables;
    %do year = 2017 %to 2023;
        data pib&year;
            set pib;
            t   = &year;        
            pib = _&year;       
            keep Country_Code pib t;
        run;
    %end;
%mend;

%pib_tables;


/*--------------------------------------------------------------*
 |  TRI DES TABLES PAR ANNÉE            |
 *--------------------------------------------------------------*/

%macro pib_sorted;
    %do year = 2017 %to 2023;
        proc sort data=pib&year;
            by t Country_Code;
        run;
    %end;
%mend;

%pib_sorted;


/*--------------------------------------------------------------*
 |  CONCATÉNATION DES TABLES EN UNE SEULE : pib_year           |
 |  - Contient : Country_Code, pib, t (2017–2023)              |
 *--------------------------------------------------------------*/

data pib_year;
    set pib2017 pib2018 pib2019 pib2020 pib2021 pib2022 pib2023;
run;

/*--------------------------------------------------------------*
 |  Harmonisation de la longueur des codes pays                 |
 |                                                              |
 *--------------------------------------------------------------*/
data pib_year;
    length Country_Code $3;   
    set pib_year;
run;


/*--------------------------------------------------------------*
 |  AJOUT DU PIB DU PAYS EXPORTATEUR (pib_exp)                 |
 *--------------------------------------------------------------*/

/* Tri des bases sur (pays_expo / Country_Code, t) */
proc sort data=pib_year;
    by Country_Code t;
run;

proc sort data=baci90;
    by pays_expo t;
run;

/* Merge pour ajouter le PIB du pays exportateur */
data baci90;
    merge baci90 (in=in1)
          pib_year(in=in2 rename=(Country_Code = pays_expo
                                  pib          = pib_exp));
    by pays_expo t;
    if in1;
run;


/*--------------------------------------------------------------*
 |  AJOUT DU PIB DU PAYS IMPORTATEUR (pib_impo)                |
 *--------------------------------------------------------------*/

/* Tri des bases sur (pays_impo / Country_Code, t) */
proc sort data=pib_year;
    by Country_Code t;
run;

proc sort data=baci90;
    by pays_impo t;
run;

/* Merge pour ajouter le PIB du pays importateur */
data baci90;
    merge baci90 (in=in1)
          pib_year(in=in2 rename=(Country_Code = pays_impo
                                  pib          = pib_impo));
    by pays_impo t;
    if in1;
run;

/*OBLIGER SAS*/
data baci90;
    set baci90;
    format pib_exp pib_impo comma20.;
run;



/*--------------------------------------------------------------*
 |  IMPORTATION DE LA POPULATION (World Bank)                  |
 *--------------------------------------------------------------*/

proc import out=pop
datafile="C:\Users\lenovo\Desktop\S1 MASERATI\m1 sas\prejects\bases de donées\API_SP.POP.TOTL_DS2_en_excel_v2_130162.xls"
dbms=xls replace;
run;


/*--------------------------------------------------------------*
 |  FILTRAGE PAYS + VARIABLES UTILES                           |
 *--------------------------------------------------------------*/

data pop;
    set pop;
    keep Country_Name Country_Code
         _2017 _2018 _2019 _2020 _2021 _2022 _2023;

    if Country_Code not in (
        'FRA','DEU','ITA','ESP','BEL','NLD','POL','GBR',
        'USA','CAN','JPN','KOR','MEX','CHL','AUS','IRL'
    ) then delete;
run;


/*--------------------------------------------------------------*
 |  CRÉATION DES TABLES ANNUELLES POPULATION                   |
 *--------------------------------------------------------------*/

%macro pop_tables;
    %do year = 2017 %to 2023;
        data pop&year;
            set pop;
            t = &year;
            pop = _&year;
            keep Country_Code pop t;
        run;
    %end;
%mend;

%pop_tables;


/*--------------------------------------------------------------*
 |  TRI DES TABLES PAR ANNÉE                                   |
 *--------------------------------------------------------------*/

%macro pop_sorted;
    %do year = 2017 %to 2023;
        proc sort data=pop&year;
            by t Country_Code;
        run;
    %end;
%mend;

%pop_sorted;


/*--------------------------------------------------------------*
 |  CONCATÉNATION EN 1 SEULE TABLE : pop_year                  |
 *--------------------------------------------------------------*/

data pop_year;
    set pop2017 pop2018 pop2019 pop2020 pop2021 pop2022 pop2023;
run;


/*--------------------------------------------------------------*
 |  CORRECTION : longueur ISO3 (évite les warnings)            |
 *--------------------------------------------------------------*/

data pop_year;
    length Country_Code $3;  
    set pop_year;
run;


/*--------------------------------------------------------------*
 |  AJOUT DE LA POPULATION DU PAYS EXPORTATEUR                  |
 *--------------------------------------------------------------*/

proc sort data=pop_year;  by Country_Code t; run;
proc sort data=baci90;    by pays_expo t; run;

data baci90;
    merge baci90(in=in1)
          pop_year(in=in2 rename=(Country_Code = pays_expo
                                  pop          = pop_exp));
    by pays_expo t;
    if in1;
run;


/*--------------------------------------------------------------*
 |  AJOUT DE LA POPULATION DU PAYS IMPORTATEUR                 |
 *--------------------------------------------------------------*/

proc sort data=pop_year;  by Country_Code t; run;
proc sort data=baci90;    by pays_impo t; run;

data baci90;
    merge baci90(in=in1)
          pop_year(in=in2 rename=(Country_Code = pays_impo
                                  pop          = pop_impo));
    by pays_impo t;
    if in1;
run;








/*--------------------------------------------------------------*
 |  PARTIE 3 – Statistiques  Descriptive                        |
 |                                                              |
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 |  – Suppression des observations sans secteur (s="") et s="35"|
 |      Lors de la fusion , certains produits ne                |
 |      disposent pas de correspondance sectorielle.            |
 *--------------------------------------------------------------*/

data baci90;
    set baci90;
    if s = "" then delete;
	if s = "35" then delete;
run;



/*--------------------------------------------------------------*
 | Représentation de la langue dans la base de données          |
 *--------------------------------------------------------------*/


/* Création du tableau de contingence */
proc freq data=baci90 noprint;
    tables lang_expo * lang_impo / out=lang_freq;
run;



/*--------------------------------------------------------------*
 | Diagrammes en secteurs : langues exportateurs / importateurs |
 *--------------------------------------------------------------*/
proc gchart data=lang_freq;

    pie lang_expo /
        sumvar=count
        type=percent
        value=inside
        slice=outside
        coutline=black
        percent=inside;
    title "Répartition des langues ";
run;
quit;

/*--------------------------------------------------------------*
 |     Construction des sous-bases France importatrice          |
 |                                                              |
 |  Objectif :                                                  |
 |    - Identifier les flux où la France est IMPORTATEUR        |
 |     mesure de la dépendance de la France envers ses          |
 |        partenaires.                                          |
 *--------------------------------------------------------------*/

/*--------------------------------------------------------------*
 |  – France comme importateur (dépendance de la France)        |
 *--------------------------------------------------------------*/

data fr_import;
    set baci90;
    where pays_impo = "FRA";   
run;

/*--------------------------------------------------------------*
 | Dépendance de la France à certains pays                      |
 | Calcul de la part de chaque pays dans les importations       |
 | françaises pour chaque année                                 |
 *--------------------------------------------------------------*/


/* Quantités totale importées par partenaire chaque année et pa par secteur*/
proc sql;
    create table dep_fr_imp as
    select  t,
            pays_expo as partenaire,
            sum(quantite) as q_imp
    from fr_import
    group by t, pays_expo;
quit;


/* Pourcentage (part) de chaque pays dans les importations françaises  en totale */
proc sql;
    create table dep_fr_imp_parts as
    select  a.*,
            a.q_imp / b.total_q as part_imp /*part d'un pays*/
    from dep_fr_imp as a
    left join (
        select  t,
                sum(q_imp) as total_q /*quantite totale de la base*/
        from dep_fr_imp
        group by t
    ) as b
    on a.t = b.t;
quit;


/* Quantité totale importée pour chaque pays partenaire (2017–2023) */
proc sql;
    create table top_imp as
    select  partenaire,
            sum(q_imp) as q_totale
    from dep_fr_imp_parts
    group by partenaire 
    order by q_totale desc;
quit;


/* Affichage du classement */
proc print data=top_imp;
    title "Classement des partenaires selon les quantités importées par la France (2017–2023)";
run;


/* Évolution de la part des principaux partenaires dans les importations françaises */
proc sgplot data=dep_fr_imp_parts;
    where partenaire in ("DEU","ITA","USA","BEL","NLD","ESP");
    title "Part des principaux partenaires dans les importations de la France en quantité";
    series x=t y=part_imp / group=partenaire markers lineattrs=(thickness=2);
    yaxis label="Part des importations" grid;
    xaxis label="Année"  grid;
run;



/*--------------------------------------------------------------*
 | Dépendance sectorielle de la France                          |
 *--------------------------------------------------------------*/


/* Part des pays dans chaque secteur pour les importations françaises */
proc sql;
    create table dep_fr_imp_sec as
    select  t,
            s,
            pays_expo as partenaire,
            sum(quantite) as q_imp_sec
    from fr_import
    group by t, s, pays_expo;
quit;



/* Part de chaque pays dans les importation de la france  par secteur + année (en %)  */
proc sql;
    create table dep_fr_imp_sec_part as
    select  a.*,
            a.q_imp_sec / b.total_q_sec as part_sec
    from dep_fr_imp_sec as a
    left join (
        select  t,
                s,
                sum(q_imp_sec) as total_q_sec
        from dep_fr_imp_sec
        group by t, s
    ) as b
    on  a.t = b.t
    and a.s = b.s;
quit;


/* Pays dominant par secteur par année (leader de la dépendance) celui qui a la plus grande part_sec  */
proc sql;
    create table leader_sec as
    select *
    from dep_fr_imp_sec_part
    group by t, s
    having part_sec = max(part_sec);
quit;



/* Part du leader dans chaque secteur en 2023 */
proc sgplot data=leader_sec;
    where t = 2017 ;
    title "Pays dont la France dépend le plus par secteur (2022)";
    vbar s / response=part_sec
             group=partenaire
             ;
    yaxis label="Part du leader dans le secteur" grid;
    xaxis label="Secteur"
          valuesrotate=vertical
          valueattrs=(size=7);
run;


/*--------------------------------------------------------------*
 | HHI des importations françaises                              |
 | Calcul : HHI = somme des parts^2 pour chaque année           |
 *--------------------------------------------------------------*/

/*à quel point la France dépend de quelques pays pour ses importations.*/
/*Pourquoi on met au carré ? Parce que ça donne plus de poids aux gros pays.*/
/*Le HHI cherche à savoir si la dépendance est répartie ou pas du tout répartie.*/
/*Concentration forte si un pays a une grande partie de nousimportation*/

/* Calcul du HHI (Herfindahl-Hirschman Index) part de la quantite totale^2 */
proc sql;
    create table hhi_import as
    select  t,
            sum(part_imp * part_imp) as hhi_imp
    from dep_fr_imp_parts
    group by t;
quit;



/* Visualisation du HHI des importations (2017–2023) */
proc sgplot data=hhi_import;
    title "Indice de concentration HHI des importations de la France (2017–2023)";
    series x=t y=hhi_imp /
           markers
           lineattrs=(thickness=2);

    refline 0.18 / label="Forte concentration"
                   lineattrs=(pattern=shortdash);

    yaxis label="HHI";
    xaxis label="Année" integer grid;
run;

/*--------------------------------------------------------------*
 |  PARTIE 3 – Création du modèle gravitaire                    |
 |                                                              |
 *--------------------------------------------------------------*/



/* Création de l'indicatrice de la langue */
data baci90;
    set baci90;
    langue = (lang_expo = lang_impo);
run;





/* Création des indicatrices pays */
%let list_countries = FRA DEU ITA ESP BEL NLD POL GBR
                      USA CAN JPN KOR MEX CHL AUS IRL;

%macro countries_indicators;
    %let i = 1;
    %do %while (%scan(&list_countries, &i) ne ); 

        %let countries = %scan(&list_countries, &i);  

        /* Exp */
        &countries._i = (pays_expo = "&countries"); 

        /* Impo*/
        &countries._j = (pays_impo = "&countries");  

        %let i = %eval(&i + 1); 
    %end;
%mend;


data baci90;
    set baci90;
    %countries_indicators;
run;



/*--------------------------------------------------------------*
 | Création de la variable effet croisé Année × secteur         |
 *--------------------------------------------------------------*/

data baci90;
    set baci90;
    ts = cats(t, "_", s); /* Création d'une clé unique pour chaque combinaison Année × Secteur */
run;


%macro creer_indicatrices_ts;

data baci90;
    set baci90;

    /* Liste des années */
    %let annees = 2017 2018 2019 2020 2021 2022 2023;

    /* Liste des codes secteurs */
    %let codes = 00 01 02 03 04 05 06 07 08 09 
                 11 12 21 22 23 24 25 26 27 28 29
                 32 33 34 35 41 42 43 51 52 53 54 55 56 57 58 59
                 61 62 63 64 65 66 67 68 69
                 71 72 73 74 75 76 77 78 79
                 81 82 83 84 85 87 88 89 96 97;

    %do a = 1 %to %sysfunc(countw(&annees));
        %let an = %scan(&annees, &a);

        %do i = 1 %to %sysfunc(countw(&codes));
        %let an = %scan(&annees, &a);
            %let code = %scan(&codes, &i);

            /* Création de l’indicatrice */
            ts&an._&code = (ts = "&an._&code");

        %end;
    %end;

run;

%mend;

%creer_indicatrices_ts;



/*--------------------------------------------------------------*
 | Transformations logarithmiques                               |
 *--------------------------------------------------------------*/

data baci90;
    set baci90;
    if quantite > 0 then log_quantite = log(quantite);
    else log_quantite = .;  
    if valeur_unitaire > 0 then log_valeur_unit = log(valeur_unitaire);
    else log_valeur_unit = .; 
    log_dist_km  = log(dist_km);
    log_pib_impo = log(pib_impo);
    log_pib_exp  = log(pib_exp);
    log_pop_exp  = log(pop_exp);
    log_pop_impo = log(pop_impo);
    drop ts;
run;



/*Matrice de corrélation des logs*/

proc corr data=baci90 ;
    title "Corrélation entre les variables log-transformées";
    var  
        log_quantite
        log_valeur_unit
        log_dist_km
        log_pib_impo
        log_pib_exp
        log_pop_exp
        log_pop_impo;
run;


/*--------------------------------------------------------------*
 | Régression du modèle gravitaire                              |
 | (combinaison linéaire sur log_quantite)                      |
 *--------------------------------------------------------------*/

/* 2017 - Irlande - Secteur 35 */

proc reg data=baci90 ;
title "La régression du modèle gravitaire";
    model log_quantite =
        log_valeur_unit
        log_dist_km
        log_pib_impo
        log_pib_exp
        log_pop_exp
        log_pop_impo
        langue

        FRA_i FRA_j DEU_i DEU_j ITA_i ITA_j ESP_i ESP_j BEL_i BEL_j NLD_i NLD_j
        POL_i POL_j GBR_i GBR_j USA_i USA_j CAN_i CAN_j JPN_i JPN_j KOR_i KOR_j
        MEX_i MEX_j CHL_i CHL_j AUS_i AUS_j 

        ts2018_00 ts2018_01 ts2018_02 ts2018_03 ts2018_04 ts2018_05 ts2018_06
        ts2018_07 ts2018_08 ts2018_09 ts2018_11 ts2018_12 ts2018_21 ts2018_22
        ts2018_23 ts2018_24 ts2018_25 ts2018_26 ts2018_27 ts2018_28 ts2018_29
        ts2018_32 ts2018_33 ts2018_34 ts2018_41 ts2018_42 ts2018_43 ts2018_51
        ts2018_52 ts2018_53 ts2018_54 ts2018_55 ts2018_56 ts2018_57 ts2018_58
        ts2018_59 ts2018_61 ts2018_62 ts2018_63 ts2018_64 ts2018_65 ts2018_66
        ts2018_67 ts2018_68 ts2018_69 ts2018_71 ts2018_72 ts2018_73 ts2018_74
        ts2018_75 ts2018_76 ts2018_77 ts2018_78 ts2018_79 ts2018_81 ts2018_82
        ts2018_83 ts2018_84 ts2018_85 ts2018_87 ts2018_88 ts2018_89 ts2018_96
        ts2018_97

        ts2019_00 ts2019_01 ts2019_02 ts2019_03 ts2019_04 ts2019_05 ts2019_06
        ts2019_07 ts2019_08 ts2019_09 ts2019_11 ts2019_12 ts2019_21 ts2019_22
        ts2019_23 ts2019_24 ts2019_25 ts2019_26 ts2019_27 ts2019_28 ts2019_29
        ts2019_32 ts2019_33 ts2019_34 ts2019_41 ts2019_42 ts2019_43 ts2019_51
        ts2019_52 ts2019_53 ts2019_54 ts2019_55 ts2019_56 ts2019_57 ts2019_58
        ts2019_59 ts2019_61 ts2019_62 ts2019_63 ts2019_64 ts2019_65 ts2019_66
        ts2019_67 ts2019_68 ts2019_69 ts2019_71 ts2019_72 ts2019_73 ts2019_74
        ts2019_75 ts2019_76 ts2019_77 ts2019_78 ts2019_79 ts2019_81 ts2019_82
        ts2019_83 ts2019_84 ts2019_85 ts2019_87 ts2019_88 ts2019_89 ts2019_96
        ts2019_97

        ts2020_00 ts2020_01 ts2020_02 ts2020_03 ts2020_04 ts2020_05 ts2020_06
        ts2020_07 ts2020_08 ts2020_09 ts2020_11 ts2020_12 ts2020_21 ts2020_22
        ts2020_23 ts2020_24 ts2020_25 ts2020_26 ts2020_27 ts2020_28 ts2020_29
        ts2020_32 ts2020_33 ts2020_34 ts2020_41 ts2020_42 ts2020_43 ts2020_51
        ts2020_52 ts2020_53 ts2020_54 ts2020_55 ts2020_56 ts2020_57 ts2020_58
        ts2020_59 ts2020_61 ts2020_62 ts2020_63 ts2020_64 ts2020_65 ts2020_66
        ts2020_67 ts2020_68 ts2020_69 ts2020_71 ts2020_72 ts2020_73 ts2020_74
        ts2020_75 ts2020_76 ts2020_77 ts2020_78 ts2020_79 ts2020_81 ts2020_82
        ts2020_83 ts2020_84 ts2020_85 ts2020_87 ts2020_88 ts2020_89 ts2020_96
        ts2020_97

        ts2021_00 ts2021_01 ts2021_02 ts2021_03 ts2021_04 ts2021_05 ts2021_06
        ts2021_07 ts2021_08 ts2021_09 ts2021_11 ts2021_12 ts2021_21 ts2021_22
        ts2021_23 ts2021_24 ts2021_25 ts2021_26 ts2021_27 ts2021_28 ts2021_29
        ts2021_32 ts2021_33 ts2021_34 ts2021_41 ts2021_42 ts2021_43 ts2021_51
        ts2021_52 ts2021_53 ts2021_54 ts2021_55 ts2021_56 ts2021_57 ts2021_58
        ts2021_59 ts2021_61 ts2021_62 ts2021_63 ts2021_64 ts2021_65 ts2021_66
        ts2021_67 ts2021_68 ts2021_69 ts2021_71 ts2021_72 ts2021_73 ts2021_74
        ts2021_75 ts2021_76 ts2021_77 ts2021_78 ts2021_79 ts2021_81 ts2021_82
        ts2021_83 ts2021_84 ts2021_85 ts2021_87 ts2021_88 ts2021_89 ts2021_96
        ts2021_97

        ts2022_00 ts2022_01 ts2022_02 ts2022_03 ts2022_04 ts2022_05 ts2022_06
        ts2022_07 ts2022_08 ts2022_09 ts2022_11 ts2022_12 ts2022_21 ts2022_22
        ts2022_23 ts2022_24 ts2022_25 ts2022_26 ts2022_27 ts2022_28 ts2022_29
        ts2022_32 ts2022_33 ts2022_34 ts2022_41 ts2022_42 ts2022_43 ts2022_51
        ts2022_52 ts2022_53 ts2022_54 ts2022_55 ts2022_56 ts2022_57 ts2022_58
        ts2022_59 ts2022_61 ts2022_62 ts2022_63 ts2022_64 ts2022_65 ts2022_66
        ts2022_67 ts2022_68 ts2022_69 ts2022_71 ts2022_72 ts2022_73 ts2022_74
        ts2022_75 ts2022_76 ts2022_77 ts2022_78 ts2022_79 ts2022_81 ts2022_82
        ts2022_83 ts2022_84 ts2022_85 ts2022_87 ts2022_88 ts2022_89 ts2022_96
        ts2022_97

        ts2023_00 ts2023_01 ts2023_02 ts2023_03 ts2023_04 ts2023_05 ts2023_06
        ts2023_07 ts2023_08 ts2023_09 ts2023_11 ts2023_12 ts2023_21 ts2023_22
        ts2023_23 ts2023_24 ts2023_25 ts2023_26 ts2023_27 ts2023_28 ts2023_29
        ts2023_32 ts2023_33 ts2023_34 ts2023_41 ts2023_42 ts2023_43 ts2023_51
        ts2023_52 ts2023_53 ts2023_54 ts2023_55 ts2023_56 ts2023_57 ts2023_58
        ts2023_59 ts2023_61 ts2023_62 ts2023_63 ts2023_64 ts2023_65 ts2023_66
        ts2023_67 ts2023_68 ts2023_69 ts2023_71 ts2023_72 ts2023_73 ts2023_74
        ts2023_75 ts2023_76 ts2023_77 ts2023_78 ts2023_79 ts2023_81 ts2023_82
        ts2023_83 ts2023_84 ts2023_85 ts2023_87 ts2023_88 ts2023_89 ts2023_96
        ts2023_97
    ;

    output out=modele_residus r=residus p=predit;
run;


 /*--------------------------------------------------------------*
 | Courbe de densité des résidus                               |
 *--------------------------------------------------------------*/

ods graphics / maxobs=200000;

proc sgplot data=modele_residus;
    title "Densité des résidus du modèle";
    density residus / type=kernel;
    xaxis label="Résidus";
    yaxis label="Densité";
run;


/*-------------------------*
 |        Fin du projet    |
 *-------------------------*/


