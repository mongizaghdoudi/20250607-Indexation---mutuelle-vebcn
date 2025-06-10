/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+ 									Mutuelle fictive VousEtesBienChezNous (VEBCN)
+ 									 Indexation des tarifs pour l'exercice 2026
+ 									  Réalisation : Mongi Zaghdoudi - Juin 2025
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 									  INDEXATION MUTUALISATION CALCULS HT ET TTC	 							 */

/*========================================== Constantes et hypothèses ============================================*/
/* Plafond annuel de la Sécurité Sociale 2025 et 2025*/
%let pass25=46368;
%let pmss25 = %sysfunc(int(%sysevalf(&pass25./12)));

/* Taux de frais de gestion : 8% des cotisations HT */
%let tx_fdg = .08;

/* Taux de frais d'acquisition : 6% des cotisations HT */
%let tx_fa = .06;

/* TCA : 7% des cotisations HT */
%let tca = .07;

/* Taxe CMU : 6,27% des cotisations HT */
%let tcmu = .0627;

/* Pass_N+1 = pass_N * (1 + inflation moyenne)*/
%let pass26 = %sysfunc(int(%sysevalf(&pass25.*1.045)));
%let pmss26 = %sysfunc(int(%sysevalf(&pass26./12)));

/* Progression du pass 25/26 */
%let evo_pass=%sysfunc(round(%sysevalf(&pass26./&pass25.),0.001));
%put &evo_pass.;


/* Agrégation des effectifs par tranche d'âge pour l'exercice concerné (2026) */
proc freq data=base ;
table tranche_age_26 /
out=effectifs(rename=(tranche_age_26=tranche_age count=freq) drop=percent);
run;

/* Import de la base des garanties */
proc import
datafile="&mypath.base_garanties.xlsx"
out=indexation
dbms=xlsx
replace;
dlm=";";
getnames=yes;
sheet="indexation";
run;

/* Prime pure 2026 : application de l'inflation sur CBSM et de l'effet évolution du PASS */
data nouvelle_pp;
set indexation(rename=(prime_pure=pp2025));
pp2026=pp2025*(1+inflation);
if evolution_pass=1 then pp2026_pass=pp2026 * &evo_pass.;
else pp2026_pass=pp2026;
run;

proc sql;
create table pp2026 as
select 
sum(pp2025) as pp2025,
sum(pp2026_pass) as pp2026 
from nouvelle_pp
;
quit;
run;

data _null_;
set pp2026;
call symput("pp2026", round(pp2026,0.01));
call symput("pp2025", round(pp2025,0.01));
run;
*%put &pp2026.;
*%put &pp2025.;

/* Prime pure 2026 : application du ratio par âge déterminé par le service technique par GLM */
proc import
datafile="&mypath.base_garanties.xlsx"
out=mutualisation
dbms=xlsx
replace;
dlm=";";
getnames=yes;
sheet="mutualisation";
run;

data mutualisation;
set mutualisation;
pp2025_age = round(&pp2025 * ratio_pp * 12,0.001);
pp2026_age = round(&pp2026 * ratio_pp * 12,0.001);
run;

proc sql;
create table mutualisation as 
select * 
from mutualisation a
left join effectifs b
on a.tranche_age=b.tranche_age
;
quit;
run;

/* HT 2026 : Chargement */
data mutualisation;
set mutualisation;
ht_brut = pp2026_age / (1 - &tx_fdg. - &tx_fa.);
ht2026 = ht_brut * freq;
effectif_mut = freq * coeff_mut;
run;

/* HT 2026 : Application de la mutualisation */
proc sql;
create table tmp as
select 
 sum(ht2026) as ht2026
,sum(effectif_mut) as effectif_mut 
from mutualisation 
;
quit;
run;

data _null_;
set tmp;
call symput("ht2026", ht2026);
call symput("effectif_mut", effectif_mut);
run;
%put &ht2026.;
%put &effectif_mut.;

data mutualisation;
set mutualisation;
ht_final = (&ht2026. / &effectif_mut.) * coeff_mut;
ht_final_pf = ht_final * freq;
ttc_tranche_age_annee = round(ht_final * (1 + &tca. + &tcmu.),.01);
ttc_tranche_age_mois = round(ttc_tranche_age_annee / 12,.01) ;
run;

/* Recette du budget */
proc sql;
create table controle as
select 
 sum(ht2026) as ht2026
,sum(ht_final*freq) as ht_final 
from mutualisation 
;
quit;
run;