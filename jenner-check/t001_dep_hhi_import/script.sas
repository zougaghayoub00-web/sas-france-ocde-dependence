/*--------------------------------------------------------------*
 |  Dependance globale + HHI des importations francaises        |
 |  Logique reprise de france_ocde_dependency.sas :             |
 |    dep_fr_imp -> dep_fr_imp_parts -> top_imp -> hhi_import    |
 |                                                              |
 |  Donnees d'exemple (fr_import) : flux ou la France importe,  |
 |  memes colonnes que la base du projet (t, pays_expo,         |
 |  quantite) pour 6 grands partenaires OCDE, 2017-2019.        |
 *--------------------------------------------------------------*/
data fr_import;
    length pays_expo $3;
    input t pays_expo $ quantite;
    datalines;
2017 DEU 5200
2017 ITA 3100
2017 USA 2600
2017 BEL 2400
2017 NLD 1900
2017 ESP 1500
2018 DEU 5400
2018 ITA 2900
2018 USA 2800
2018 BEL 2300
2018 NLD 2000
2018 ESP 1600
2019 DEU 5600
2019 ITA 3000
2019 USA 3100
2019 BEL 2200
2019 NLD 2100
2019 ESP 1700
;
run;

/* Quantites totales importees par partenaire chaque annee */
proc sql;
    create table dep_fr_imp as
    select  t,
            pays_expo as partenaire,
            sum(quantite) as q_imp
    from fr_import
    group by t, pays_expo;
quit;

/* Part de chaque pays dans les importations francaises */
proc sql;
    create table dep_fr_imp_parts as
    select  a.*,
            a.q_imp / b.total_q as part_imp
    from dep_fr_imp as a
    left join (
        select  t,
                sum(q_imp) as total_q
        from dep_fr_imp
        group by t
    ) as b
    on a.t = b.t;
quit;

/* Quantite totale importee par partenaire (2017-2019) */
proc sql;
    create table top_imp as
    select  partenaire,
            sum(q_imp) as q_totale
    from dep_fr_imp_parts
    group by partenaire
    order by q_totale desc;
quit;

proc print data=top_imp;
    title "Classement des partenaires selon les quantites importees par la France";
run;

/* HHI = somme des parts^2 pour chaque annee */
proc sql;
    create table hhi_import as
    select  t,
            sum(part_imp * part_imp) as hhi_imp
    from dep_fr_imp_parts
    group by t;
quit;

proc print data=hhi_import;
    title "Indice de concentration HHI des importations de la France (2017-2019)";
run;
