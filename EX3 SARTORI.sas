/*EXERCICE 1*/
/*QUESTION_1*/

/*Importer le fichier Panel95light.csv pour en faire une table SAS.*/
proc import datafile='/home/u63824488/sasuser.v94/Panel95light.csv'
    out=PanelEuropeenMenages95
    dbms=csv
    replace;
    getnames=yes;
run;

proc print data=PanelEuropeenMenages95;
run;
/*QUESTION_2*/

proc freq data=PanelEuropeenMenages95;
    tables sexe etudes;
run;

/*Visualitation de la variable Sexe*/
proc freq data=PanelEuropeenMenages95;
  tables sexe / out=sexe_freq (rename=(count=Freq));
run;
proc gchart data=sexe_freq;
  pie sexe / sumvar=Freq;
run;

/*Visualitation de la variable études*/

proc freq data=PanelEuropeenMenages95;
  tables etudes / out=etudes_freq (rename=(count=Freq));
run;

proc gchart data=etudes_freq;
  pie etudes / sumvar=Freq;
run;


/*Procédure PROC MEANS pour obtenir les statistiques descriptives des variables numériques */
proc means data=PanelEuropeenMenages95 n mean median min max stddev;
    var lw exper mois;
run;

/*Procédure PROC UNIVARIATE pour obtenir des informations supplémentaires sur la distribution des variables numériques */
proc univariate data=PanelEuropeenMenages95;
    var lw exper mois;
    histogram lw exper mois / normal;
    inset n mean median min max stddev / position=ne;
run;


/*QUESTION_3*/
/*Indicatrices */

data PanelEuropeenMenages95;
    set PanelEuropeenMenages95;
    if sexe = 'Homme' then sexeN = 1;
    else if sexe = 'Femme' then sexeN = 2;
run;

proc sql;
    create table dummy_data as 
    select *,
        (case when etudes = 'deuxieme cycle' then 1 else 0 end) as etudes_deuxieme_cycle,
        (case when etudes = 'primaire' then 1 else 0 end) as etudes_primaire,
        (case when etudes = 'professionnel' then 1 else 0 end) as etudes_professionnel,
        (case when etudes = 'secondaire' then 1 else 0 end) as etudes_secondaire,
        (case when etudes = 'troisieme cycl' then 1 else 0 end) as etudes_troisieme_cycle,
        (case when sexeN = 2 then 1 else 0 end) as sexe_femme,
        (case when sexeN = 1 then 1 else 0 end) as sexe_homme
    from PanelEuropeenMenages95;
quit;


/*QUESTION_4*/

/* Calculer le log-salaire moyen par niveau d'études */
proc means data=PanelEuropeenMenages95 mean;
    class etudes;
    var lw;
    output out=mean_by_etudes mean(lw)=lw_moyen;
run;

/* Calculer le log-salaire moyen dans l'échantillon */
proc means data=PanelEuropeenMenages95 mean;
    var lw;
    output out=mean_log_salaire mean(lw)=lw_moyen;
run;


/*QUESTION_5*/


/* 1. Tous les niveaux d'étude, "sans précaution" */
proc reg data=dummy_data outest=reg1;
    model lw = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    output out=predicted1 p=pred1;
run;

/* 2. Tous les niveaux d'étude, sans constante */
proc reg data=dummy_data outest=reg2;
    model lw = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle / NOINT;
    output out=predicted2 p=pred2;
run;

/* 3. Tous les niveaux d'étude, sauf primaire (référence 1) */
proc reg data=dummy_data outest=reg3 plots(maxpoints=10000);
    model lw = etudes_deuxieme_cycle etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    output out=predicted3 p=pred3;
run;

/* 4. Tous les niveaux d'étude, sauf primaire (référence 6) */
proc reg data=dummy_data outest=reg4;
    model lw = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_troisieme_cycle;
    output out=predicted4 p=pred4;
run;

/* Calculer les effectifs de chaque niveau d'étude */
proc freq data=PanelEuropeenMenages95 noprint;
    tables etudes / out=effectifs_etudes;
run;

/* Fusionner les effectifs avec les données */
proc sql;
    create table dummy_data_with_effectifs as 
    select dummy_data.*, effectifs_etudes.Count
    from dummy_data, effectifs_etudes
    where dummy_data.etudes = effectifs_etudes.etudes;
quit;

/* 5. Tous les niveaux d'étude, en imposant la nullité de la moyenne des coefficients des 
indicatrices, pondérée par les effectifs: */
proc reg data=dummy_data outest=reg5;
    model lw = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    output out=predicted5 p=pred5;
    restrict etudes_deuxieme_cycle + etudes_primaire + etudes_professionnel + etudes_secondaire + etudes_troisieme_cycle = 0;
run;



/* Ajout des salaires prédits de chaque modèle à la table dummy_data */
data predicted_all;
    merge dummy_data 
          predicted1 (rename=(pred1=lw_pred1)) 
          predicted2 (rename=(pred2=lw_pred2)) 
          predicted3 (rename=(pred3=lw_pred3)) 
          predicted4 (rename=(pred4=lw_pred4)) 
          predicted5 (rename=(pred5=lw_pred5));
run;


/* Afficher les premières observations de la table predicted_all */
proc print data=predicted_all (obs=1000);
run;

/*QUESTION_7*/

/* Calcule l'erreur absolue pour chaque modèle */
data errors;
    set predicted_all;
    lw_error1 = abs(lw - lw_pred1);
    lw_error2 = abs(lw - lw_pred2);
    lw_error3 = abs(lw - lw_pred3);
    lw_error4 = abs(lw - lw_pred4);
    lw_error5 = abs(lw - lw_pred5);
run;

/* Calcule la moyenne des erreurs absolues pour chaque modèle */
proc means data=errors mean;
    var lw_error1 lw_error2 lw_error3 lw_error4 lw_error5;
    output out=mae mean(lw_error1)=mae1 mean(lw_error2)=mae2 mean(lw_error3)=mae3 mean(lw_error4)=mae4 mean(lw_error5)=mae5;
run;

/* Afficher les résultats */
proc print data=mae;
    var mae1 mae2 mae3 mae4 mae5;
run;

/* Exercice2 */

/*Chargement de la database complète*/
proc import datafile="/home/u63824488/PanelEuropeen95.csv" out=mydata dbms=csv replace;
    getnames=yes;
run;

/* Creation d'une nouvelle table contenant les dites varibles*/
proc sql;
    create table newtable as
    select mident, mois, actif, actifp, actifs, agea
    from mydata;
quit;

/* chargement de la table predicted_all créée au préalable */
data predicted_all;
    set work.predicted_all;
run;

/*fusion de newtable et de predicted_all en fonction de mident et mois */ 
data merged;
    merge newtable predicted_all;
    by mident mois;
run;

/* Régression par toutes les indicatrices d'éducation*/ 
proc reg data=merged outest=estimates_actifs;
    model actifs = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    output out=actifs_MCO p=p1reg r=residu;
run;

/* permet de nommer la variable sigma1ref*/
proc means data=actifs_MCO mean;
    var residu_sq;
    output out=sigma1reg mean=residu_sq_mean;
run;

/* Ajout à la table actifs_MCO les résidus au carré*/
data actifs_MCO;
    set actifs_MCO;
    residu_sq = residu**2;
run;


/* Étape DATA pour créer une macrovariable */
data _null_;
    set sigma1reg;	
    call symput('sigma1reg', residu_sq_mean); /* Stocke la moyenne dans la macrovariable */
run;

/* Ajoutez p1reg et sigma1reg à la table de travail */
proc sql;
    create table merged_p1reg_sigma1reg as
	select a.*, b.p1reg, &sigma1reg as sigma1reg
    from merged as a left join actifs_MCO (keep=mident mois p1reg) as b
    on a.mident = b.mident and a.mois = b.mois; /* condition de jointure*/
quit;


/* Représentez graphiquement la distribution de p1reg */
proc univariate data=merged_p1reg_sigma1reg;
	var p1reg;
	histogram p1reg / norm;
run;

/*Question 4*/
/* Calcul des poids wi = sqrt(yi*(1-yi)) */
data merged_weights;
    set actifs_MCO;
    wi = sqrt(p1reg*(1-p1reg));
run;

/*Régression MCP d'actifs sur les indicateurs d'éducation */
proc surveyreg data=merged_weights;
    model actifs = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    weight wi;
run;


/*Question 5*/
/* Création des variables agea2 et agea3 */
data merged_agea2_agea3;
    set merged;
    agea2 = agea**2;
    agea3 = agea**3;
run;


/*Question 6*/
/* Régression d'actifs sur agea, agea2, agea3 et l'indicatrice sexe_femme et toutes celles d'éducation */
proc reg data=merged_agea2_agea3;
    model actifs = agea agea2 agea3 etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle sexe_femme;
run;


/*Question 7*/

/* Estimer le modèle et enregistrer les valeurs prédites */
proc reg data=merged_agea2_agea3 outest=estimates_age;
    model actifs = agea agea2 agea3 etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    output out=predicted_actif predicted=p2reg out=residus residual=res;
run;
/* Créer une nouvelle table avec les valeurs prédites */
data merged_p2reg;
    merge merged_agea2_agea3 predicted_actif(keep=mident mois p2reg);
    by mident mois;
run;

/* Représenter graphiquement la distribution de p2reg */
proc univariate data=merged_p2reg;
    var p2reg;
    histogram p2reg / normal;
run;

/* Représenter graphiquement la distribution des résidus */
proc univariate data=predicted_actif;
    var res;
    histogram res / normal;
run;


/*Question 9*/
/* Régression d'actifs sur agea, agea2, agea3 et l'indicatrice sexe_homme */
/* Estimer le modèle et enregistrer les valeurs prédites */
proc reg data=merged_agea2_agea3 outest=estimates_age2;
    model actifs = agea agea2 agea3 etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle sexe_homme;
    output out=predicted_actif_homme predicted=p2reg out=residus residual=res;
run;

/* Créer une nouvelle table avec les valeurs prédites */
data merged_p2reg2;
    merge merged_agea2_agea3 predicted_actif(keep=mident mois p2reg);
    by mident mois;
run;

/* Représenter graphiquement la distribution de p2reg */
proc univariate data=merged_p2reg2;
    var p2reg;
    histogram p2reg / normal;
run;
/* Régression d'actifs sur agea, agea2, agea3 et sexeN */
/* Estimer le modèle et enregistrer les valeurs prédites */
proc reg data=merged_agea2_agea3 outest=estimates_age3;
    model actifs = agea agea2 agea3 etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle sexeN;
    output out=predicted_actif_sexeN predicted=p2reg out=residus residual=res;
run;

/* Créer une nouvelle table avec les valeurs prédites */
data merged_p2reg3;
    merge merged_agea2_agea3 predicted_actif(keep=mident mois p2reg);
    by mident mois;
run;

/* Représenter graphiquement la distribution de p2reg */
proc univariate data=merged_p2reg3;
    var p2reg;
    histogram p2reg / normal;
run;

/*Exercice 3 */ 

/*commande déjà exécutée dans le premier exercice*/
proc sql;
    create table dummy_data as 
    select *,
        (case when etudes = 'deuxieme cycle' then 1 else 0 end) as etudes_deuxieme_cycle,
        (case when etudes = 'primaire' then 1 else 0 end) as etudes_primaire,
        (case when etudes = 'professionnel' then 1 else 0 end) as etudes_professionnel,
        (case when etudes = 'secondaire' then 1 else 0 end) as etudes_secondaire,
        (case when etudes = 'troisieme cycl' then 1 else 0 end) as etudes_troisieme_cycle,
        (case when sexeN = 2 then 1 else 0 end) as sexe_femme,
        (case when sexeN = 1 then 1 else 0 end) as sexe_homme
    from PanelEuropeenMenages95;
quit;



/* Chargement d'un nouvelle base de donnée contenant mident et lrd0*/
data newtable2;
set mydata (keep=mident lrd0);
run; 

/* Fusion des tables obtenus dans l'exercice précédent et newtable que nous venons de créer*/
data merged_data3;
merge newtable2 merged_p2reg;
by mident;
run;

/*Différentes regression de actifp sur les indicatrices de sexe et lrd0*/
/*Regression sur lrd0 et des deux sexes*/
proc reg data=merged_data3;
  model actifp = sexeN lrd0;
run;
/*Regression sur lrd0 et sexe_masculin*/
proc reg data=merged_data3;
  model actifp = sexe_homme lrd0;
run;
/*Regression sur lrd0 et sexe_feminin*/
proc reg data=merged_data3;
  model actifp = sexe_femme lrd0;
run;
/*Différentes regression de actifs sur les indicatrices de sexe et lrd0*/
/*Regression sur lrd0 et des deux sexes*/
proc reg data=merged_data3;
  model actifs = sexeN lrd0;
run;
/*Regression sur lrd0 et sexe_masculin*/
proc reg data=merged_data3;
  model actifs = sexe_homme lrd0;
run;
/*Regression sur lrd0 et sexe_feminin*/
proc reg data=merged_data3;
  model actifs = sexe_femme lrd0;
run;

/* Reprise des modèles en probit*/
/* Regression sur actifs*/
proc probit data=merged_data3;
  model actifs(event='1') = sexeN lrd0;
run;
proc probit data=merged_data3;
  model actifs(event='1') = sexe_homme lrd0;
run;
proc probit data=merged_data3;
  model actifs(event='1') = sexe_femme lrd0;
run;
/* Regression sur actifp*/
proc probit data=merged_data3;
  model actifp(event='1') = sexeN lrd0;
run;
proc probit data=merged_data3;
  model actifp(event='1') = sexe_homme lrd0;
run;
proc probit data=merged_data3;
  model actifp(event='1') = sexe_femme lrd0;
run;
/* Reprise des modèles en logit*/
/* Regression sur actifs*/
proc logistic data=merged_data3;
  model actifs(event='1') = sexeN lrd0;
run;
proc logistic data=merged_data3;
  model actifs(event='1') = sexe_homme lrd0;
run;
proc logistic data=merged_data3;
  model actifs(event='1') = sexe_femme lrd0;
run;
/* Regression sur actifp*/
proc logistic data=merged_data3;
  model actifp(event='1') = sexeN lrd0;
run;
proc logistic data=merged_data3;
  model actifp(event='1') = sexe_homme lrd0;
run;
proc logistic data=merged_data3;
  model actifp(event='1') = sexe_femme lrd0;
run;

/* Création des variables de probabilité d'activité principale et secondaire */
/*Attention il faut tout run en même temps*/
data probabilities;
set merged_data3;
/* Probit */
if sexe='Femme' then do;
p_main_probit_f = cdf('NORMAL', -2.9105 + 0.4661 * lrd0);
p_second_probit_f = 1 - p_main_probit_f;
end;
else do;
p_main_probit_m = cdf('NORMAL', -2.9105 + 0.4661 * lrd0 - 0.1692);
p_second_probit_m = 1 - p_main_probit_m;
end;
/* Logit */
if sexe='Femme' then do;
p_main_logit_f = 1 / (1 + exp(-(-7.2343 + 1.0447 * lrd0)));
p_second_logit_f = 1 - p_main_logit_f;
end;
else do;
p_main_logit_m = 1 / (1 + exp(-(-7.2343 + 1.0447 * lrd0 - 0.4072)));
p_second_logit_m = 1 - p_main_logit_m;
end;
/* MCO */
if sexe='Femme' then do;
p_main_mco_f = 0.9328 + 0.0096 * lrd0;
p_second_mco_f = 1 - p_main_mco_f;
end;
else do;
p_main_mco_m = 0.9328 + 0.0096 * lrd0 + 0.0494;
p_second_mco_m = 1 - p_main_mco_m;
end;
run;

proc sgplot data=probabilities;
    series x=lrd0 y=p_main_probit_f / legendlabel='Probit Femmes';
    series x=lrd0 y=p_main_probit_m / legendlabel='Probit Hommes';
    series x=lrd0 y=p_main_logit_f / legendlabel='Logit Femmes';
    series x=lrd0 y=p_main_logit_m / legendlabel='Logit Hommes';
    series x=lrd0 y=p_main_mco_f / legendlabel='MCO Femmes';
    series x=lrd0 y=p_main_mco_m / legendlabel='MCO Hommes';
    xaxis label='Log-revenu d''inactivité';
    yaxis label='Probabilité d''activité principale';
    keylegend / location=outside position=topright;
run;



