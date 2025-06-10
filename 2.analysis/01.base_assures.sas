
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+ 									Mutuelle fictive VousEtesBienChezNous (VEBCN)
+ 									 Indexation des tarifs pour l'exercice 2026
+ 									  Réalisation : Mongi Zaghdoudi - Juin 2025
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 									 CONSTRUCTION DE LA BASE DES ASSURES FICTIFS								*/

%let path_adresses=Z:\20250607 Indexation - mutuelle vebcn\1.indata\rues\;
%let mypath=Z:\20250607 Indexation - mutuelle vebcn\1.indata\;

options mprint symbolgen mlogic;
proc delete data=_all_;

/*============================================== Base des rues de France ============================================*/
data fichier_rues(keep=nom_fichier); 
   rc=filename("mydir", "&path_adresses.");
   did=dopen("mydir"); 
   if did > 0 then do; 
   *put did;
	nb_fichiers=dnum(did);
	do i=1 to nb_fichiers;
		nom_fichier=dread(did,i);
		output;
	end;
   end; 
   else do; 
      msg=sysmsg(); 
      put msg; 
   end;
run;

data _null_;
set fichier_rues;
call symput('fichier_'||left(trim(_n_)),nom_fichier);
call symput('nb',_n_);
run;

%macro importer(i);
	proc import
	datafile="&path_adresses.&&fichier_&i." 
	out=donnees&i.
	dbms=csv
	replace;
	dlm=';';
	getnames=yes;
	run;
%mend;

%macro empiler();
	%importer(1);
	data rues;
	set donnees1(keep=libvoie);
	run;
	proc delete data=donnees1;
	run;
	%do i=2 %to &nb.; 
		%importer(&i.);
		data rues; 
		set rues donnees&i.(keep=libvoie);
		run;
		proc delete data=donnees&i.;
		run;
	%end;
	%mend() ;
%empiler;

/*================================================= Base des communes de France =================================================*/
proc import 
datafile="&mypath.communes-fr.xlsx"
out=communes
dbms=xlsx
replace;
*dlm=",";
getnames=yes;
run;

/*================================================= Base des assurés anonymisée =================================================*/
/* https://www.data.gouv.fr/fr/datasets/liste-de-prenoms-et-patronymes/#/community-reuses*/
proc import 
datafile="&mypath.prenom.csv"
out=prenoms
dbms=csv
replace;
dlm=",";
getnames=yes;
run;

proc import
datafile="&mypath.patronymes.csv"
out=patronymes
dbms=csv
replace;
dlm=",";
getnames=yes;
run;

/* Macro de génération automatiques des lignes aléatoires */
%macro gen_liste_aleatoire(table,variables,seed);
%global l&table.;
%let l&table.=%sysfunc(int(&seed.*%sysfunc(ranuni(0))));
data &table._bd;
alea=int(1000*(ranuni(0))); 
output;
set &table.(keep=&variables.);
run;

proc sort data=&table._bd;
by alea;
run;

data &table._bd;
i=_N_;
set &table._bd;
run;
%mend;

/* Génération des tables anonymisées */
%gen_liste_aleatoire(prenoms,prenom,10e4);
%gen_liste_aleatoire(patronymes,patronyme,10e5);
%gen_liste_aleatoire(communes,code_postal nom_commune,10e2);
%gen_liste_aleatoire(rues,libvoie,10e5);

/* Tables des âges */
proc import
datafile="&mypath.ages.csv"
out=ages
dbms=csv
replace;
dlm=";";
getnames=yes;
sheet="ages";
run;

/*========================================== Affectation des ages et création de la base finale  ===========================================*/

data base;
set prenoms_bd;
where i >= &lprenoms. and i <= &lprenoms.+10e3-1;
drop i alea;
run;

data base;
set base;
set patronymes_bd;
where i >= &lpatronymes. and i <= &lpatronymes.+10e3-1;
drop i alea;
run;

data base;
set base;
set rues_bd;
num_al=int(1000*(ranuni(0)));
libvoie=num_al||" "||libvoie;
where i >= &lrues. and i <= &lrues.+10e3-1;
drop i alea num_al;
run;

data base;
set base;
set communes_bd;
where i >= &lcommunes. and i <= &lcommunes.+10e3-1;
drop i alea;
run;

/* Classification par tranche d'âge */
data base;
set base;
set ages;
select ;
when (age <= 20) tranche_age = "jusqu'à 20 ans";
when (age > 20 and age<=25) tranche_age = "21 à 25 ans";
when (age > 25 and age<=30) tranche_age = "26 à 30 ans";
when (age > 30 and age<=35) tranche_age = "31 à 35 ans";
when (age > 35 and age<=40) tranche_age = "36 à 40 ans";
when (age > 40 and age<=45) tranche_age = "41 à 45 ans";
when (age > 45 and age<=50) tranche_age = "46 à 50 ans";
when (age > 50 and age<=55) tranche_age = "51 à 55 ans";
when (age > 55 and age<=60) tranche_age = "56 à 60 ans";
when (age > 60 and age<=65) tranche_age = "61 à 65 ans";
when (age > 65 and age<=70) tranche_age = "66 à 70 ans";
when (age > 70 and age<=75) tranche_age = "71 à 75 ans";
when (age > 75 and age<=80) tranche_age = "76 à 80 ans";
when (age > 80 and age<=85) tranche_age = "81 à 85 ans";
when (age > 85) tranche_age = "86 ans et +";
otherwise;
end;
rename age=age_25 tranche_age=tranche_age_25;
run;

/* Appliquer le viellissement d'un an à la nouvelle année */
data base;
set base;
age = age_25 +1;
select ;
when (age <= 20) tranche_age = "jusqu'à 20 ans";
when (age > 20 and age<=25) tranche_age = "21 à 25 ans";
when (age > 25 and age<=30) tranche_age = "26 à 30 ans";
when (age > 30 and age<=35) tranche_age = "31 à 35 ans";
when (age > 35 and age<=40) tranche_age = "36 à 40 ans";
when (age > 40 and age<=45) tranche_age = "41 à 45 ans";
when (age > 45 and age<=50) tranche_age = "46 à 50 ans";
when (age > 50 and age<=55) tranche_age = "51 à 55 ans";
when (age > 55 and age<=60) tranche_age = "56 à 60 ans";
when (age > 60 and age<=65) tranche_age = "61 à 65 ans";
when (age > 65 and age<=70) tranche_age = "66 à 70 ans";
when (age > 70 and age<=75) tranche_age = "71 à 75 ans";
when (age > 75 and age<=80) tranche_age = "76 à 80 ans";
when (age > 80 and age<=85) tranche_age = "81 à 85 ans";
when (age > 85) tranche_age = "86 ans et +";
otherwise;
end;
rename age=age_26 tranche_age=tranche_age_26;
run;

