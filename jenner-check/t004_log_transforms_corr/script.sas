/*--------------------------------------------------------------*
 |  Transformations logarithmiques + matrice de correlation     |
 |  Reprise de france_ocde_dependency.sas :                     |
 |    log_quantite, log_valeur_unit, log_dist_km, log_pib_*,    |
 |    log_pop_* puis PROC CORR sur les variables log.           |
 |                                                              |
 |  Donnees d'exemple (baci90) memes colonnes que le projet.    |
 *--------------------------------------------------------------*/
data baci90;
    input quantite valeur_unitaire dist_km pib_impo pib_exp pop_exp pop_impo;
    datalines;
900   2.5  1050  2.9e12  4.2e12  83000000 67000000
850   3.1  1050  4.2e12  2.9e12  67000000 83000000
400   1.8  1100  2.9e12  1.9e12  60000000 67000000
1200  4.4  6200  1.9e12  25e12   331000000 38000000
300   0.9  180   17e11   9e11    17000000  11000000
620   2.2  1050  2.9e12  1.4e12  47000000  67000000
1500  5.1  5900  25e12   3.1e12  67000000  331000000
280   1.1  180   11e11   17e11   11000000  17000000
;
run;

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
run;

proc corr data=baci90;
    title "Correlation entre les variables log-transformees";
    var
        log_quantite
        log_valeur_unit
        log_dist_km
        log_pib_impo
        log_pib_exp
        log_pop_exp
        log_pop_impo;
run;
