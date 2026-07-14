/*--------------------------------------------------------------*
 |  Dependance sectorielle : pays leader par secteur/annee      |
 |  Logique reprise de france_ocde_dependency.sas :             |
 |    dep_fr_imp_sec -> dep_fr_imp_sec_part -> leader_sec        |
 |                                                              |
 |  Donnees d'exemple (fr_import) memes colonnes que le projet  |
 |  (t, s = secteur SITC, pays_expo, quantite).                 |
 *--------------------------------------------------------------*/
data fr_import;
    length pays_expo $3 s $2;
    input t s $ pays_expo $ quantite;
    datalines;
2017 84 DEU 900
2017 84 ITA 400
2017 84 USA 250
2017 78 DEU 700
2017 78 ESP 620
2017 78 BEL 300
2017 33 USA 1200
2017 33 NLD 800
2017 33 DEU 500
2018 84 DEU 950
2018 84 ITA 500
2018 84 USA 200
2018 78 ESP 720
2018 78 DEU 660
2018 78 BEL 280
2018 33 USA 1300
2018 33 NLD 760
2018 33 DEU 540
;
run;

/* Part des pays dans chaque secteur (importations francaises) */
proc sql;
    create table dep_fr_imp_sec as
    select  t,
            s,
            pays_expo as partenaire,
            sum(quantite) as q_imp_sec
    from fr_import
    group by t, s, pays_expo;
quit;

/* Part de chaque pays par secteur + annee (en %) */
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

/* Pays dominant par secteur/annee (leader de la dependance) */
proc sql;
    create table leader_sec as
    select *
    from dep_fr_imp_sec_part
    group by t, s
    having part_sec = max(part_sec);
quit;

proc print data=leader_sec;
    title "Pays dont la France depend le plus par secteur";
run;
