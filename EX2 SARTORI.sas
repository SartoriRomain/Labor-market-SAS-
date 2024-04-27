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
/*QUESTION_2 : Représentation graphique*/

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
/*Indicatrice */

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

/**************QUESTION_6*******************/
/****** VOIR PDF ******/


/**************QUESTION_7*******************/

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

proc import datafile="/home/u63824488/PanelEuropeen95.csv" out=mydata dbms=csv replace;
    getnames=yes;
run;

data newtable;
    set mydata (keep=mident mois actif actifp actifs agea);
run;

data newdata;
    set work.newtable;
run;

data predicted_all;
    set work.predicted_all;
run;

data merged;
    merge newdata predicted_all;
    by mident mois;
run;

proc reg data=merged outest=estimates_actifs;
    model actifs = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    output out=predicted_actifs p=p1reg r=residu;
run;

data predicted_actifs;
    set predicted_actifs;
    residu_sq = residu**2;
run;

proc means data=predicted_actifs mean;
    var residu_sq;
    output out=sigma1reg mean=residu_sq_mean;
run;

data _null_;
    set sigma1reg;
    call symput('sigma1reg', residu_sq_mean);
run;

/* Ajoutez p1reg et sigma1reg à la table de travail */
proc sql;
    create table merged_with_p1reg_sigma1reg as
    select a.*, b.p1reg, &sigma1reg as sigma1reg
    from merged as a left join predicted_actifs (keep=mident mois p1reg) as b
    on a.mident = b.mident and a.mois = b.mois;
quit;

/* Représentez graphiquement la distribution de p1reg */
proc univariate data=merged_with_p1reg_sigma1reg;
	var p1reg;
	histogram p1reg / norm;
run;

/*Question 4*/
/* Étape 1 : Calculer les poids wi = sqrt(yi*(1-yi)) */
data merged_with_weights;
    set predicted_actifs;
    wi = sqrt(p1reg*(1-p1reg));
run;

/* Étape 2 : Régression MCP d'actifs sur les différentes indicatrices d'éducation */
proc surveyreg data=merged_with_weights;
    model actifs = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    weight wi;
run;


/*Question 5*/
/* Création des variables agea2 et agea3 */
data merged_with_agea2_agea3;
    set merged;
    agea2 = agea**2;
    agea3 = agea**3;
run;


/*Question 6*/
/* Régression d'actifs sur agea, agea2, agea3 et l'indicatrice sexe_femme */
proc reg data=merged_with_agea2_agea3;
    model actifs = agea agea2 agea3 sexe_femme;
run;


/*Question 7*/
/* Étape 1: Estimer le modèle et enregistrer les valeurs prédites */
proc reg data=merged_with_agea2_agea3 outest=estimates_age;
    model actifs = agea agea2 agea3 sexe_femme;
    output out=predicted_age predicted=p2reg out=residus residual=res;
run;

/* Étape 2: Créer une nouvelle table avec les valeurs prédites p2reg */
data predicted_p2reg;
    set predicted_age (keep=mident mois p2reg);
run;

/* Étape 3: Fusionner la nouvelle table avec la table de travail existante */
data merged_with_p2reg;
    merge merged_with_agea2_agea3 predicted_p2reg;
    by mident mois;
run;

/* Étape 4: Représenter graphiquement la distribution de p2reg */
proc univariate data=merged_with_p2reg;
    var p2reg;
    histogram p2reg / normal;
run;

proc univariate data=predicted_age;
    var res;
    histogram res / normal;
run;


/*Question 9*/
/* Régression d'actifs sur agea, agea2, agea3 et l'indicatrice sexe_femme */
proc reg data=merged_with_agea2_agea3 outest=estimates_age2;
    model actifs = agea agea2 agea3 sexe_homme;
    output out=predicted_age2 predicted=p2reg out=residus residual=res;
run;


/* Étape 2: Créer une nouvelle table avec les valeurs prédites p2reg */
data predicted_p2reg2;
    set predicted_age2 (keep=mident mois p2reg);
run;

/* Étape 3: Fusionner la nouvelle table avec la table de travail existante */
data merged_with_p2reg2;
    merge merged_with_agea2_agea3 predicted_p2reg;
    by mident mois;
run;

/* Étape 4: Représenter graphiquement la distribution de p2reg */
proc univariate data=merged_with_p2reg2;
    var p2reg;
    histogram p2reg / normal;
run;

proc univariate data=predicted_age2;
    var res;
    histogram res / normal;
run;

proc reg data=dummy_data outest=reg1;
    model lw = etudes_deuxieme_cycle etudes_primaire etudes_professionnel etudes_secondaire etudes_troisieme_cycle;
    output out=predicted1 p=pred1;
run;

proc univariate data=dummy_data 
	var res;
	histogram res / normal;
Run;



