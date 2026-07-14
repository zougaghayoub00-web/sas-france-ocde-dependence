/*--------------------------------------------------------------*
 |  Macro %countries_indicators                                 |
 |  Reprise de france_ocde_dependency.sas : construit, pour     |
 |  chaque pays de la liste OCDE, deux indicatrices             |
 |    &pays._i = (pays_expo = "&pays")                          |
 |    &pays._j = (pays_impo = "&pays")                          |
 |  + l'indicatrice de langue commune (lang_expo = lang_impo).  |
 |                                                              |
 |  Donnees d'exemple (baci90) memes colonnes que le projet.    |
 *--------------------------------------------------------------*/
data baci90;
    length pays_expo $3 pays_impo $3 lang_expo $12 lang_impo $12;
    input pays_expo $ pays_impo $ lang_expo $ lang_impo $ quantite;
    datalines;
DEU FRA German French 900
FRA DEU French German 850
ITA FRA Italian French 400
USA CAN English English 1200
BEL NLD Dutch Dutch 300
ESP FRA Spanish French 620
GBR USA English English 1500
NLD BEL Dutch Dutch 280
;
run;

/* Indicatrice de langue commune */
data baci90;
    set baci90;
    langue = (lang_expo = lang_impo);
run;

/* Liste des 16 pays OCDE */
%let list_countries = FRA DEU ITA ESP BEL NLD POL GBR
                      USA CAN JPN KOR MEX CHL AUS IRL;

%macro countries_indicators;
    %let i = 1;
    %do %while (%scan(&list_countries, &i) ne );

        %let countries = %scan(&list_countries, &i);

        /* Exportateur */
        &countries._i = (pays_expo = "&countries");

        /* Importateur */
        &countries._j = (pays_impo = "&countries");

        %let i = %eval(&i + 1);
    %end;
%mend;

data baci90;
    set baci90;
    %countries_indicators;
run;

proc print data=baci90;
    var pays_expo pays_impo langue FRA_i FRA_j DEU_i DEU_j USA_i USA_j;
    title "Indicatrices pays et langue commune (extrait)";
run;
