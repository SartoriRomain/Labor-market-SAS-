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


proc freq data=PanelEuropeenMenages95;
  tables etudes / out=etudes_freq (rename=(count=Freq));
run;

proc gchart data=etudes_freq;
  pie etudes / sumvar=Freq;
run;



proc means data=PanelEuropeenMenages95 n mean median min max stddev;
    var lw exper mois;
run;


proc univariate data=PanelEuropeenMenages95;
    var lw exper mois;
    histogram lw exper mois / normal;
    inset n mean median min max stddev / position=ne;
run;


/*QUESTION_3*/
/*Indicatrices */
proc sql;
    create table dummy_data as 
    select *,
        (case when etudes = 'deuxieme cycle' then 1 else 0 end) as etudes_deuxieme_cycle,
        (case when etudes = 'primaire' then 1 else 0 end) as etudes_primaire,
        (case when etudes = 'professionnel' then 1 else 0 end) as etudes_professionnel,
        (case when etudes = 'secondaire' then 1 else 0 end) as etudes_secondaire,
        (case when etudes = 'troisieme cycl' then 1 else 0 end) as etudes_troisieme_cycle
    from PanelEuropeenMenages95;
quit;

data PanelEuropeenMenages95;
    set PanelEuropeenMenages95;
    if sexe = 'Homme' then sexeN = 1;
    else if sexe = 'Femme' then sexeN = 2;
run;

proc sql;
    create table dummy_data as 
    select *,
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

proc print data=mae;
    var mae1 mae2 mae3 mae4 mae5;
run;