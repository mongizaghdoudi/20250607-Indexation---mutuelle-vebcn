
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+ 									Mutuelle fictive VousEtesBienChezNous (VEBCN)
+ 									 Indexation des tarifs pour l'exercice 2026
+ 									  Réalisation : Mongi Zaghdoudi - Juin 2025
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 								  	                BASE FINALE SERVICE CLIENTS	 							 */

/* Calcul du nouveau tarif mensuel pour chaque assuré */
proc sql;
create table tarif as
select  a.*
		,b.tranche_age
		,round(b.ttc_tranche_age_mois,.01) as ttc_mois
		,round(b.ttc_tranche_age_annee,.01) as ttc_annee
from base a
left join mutualisation b
on a.tranche_age_26=b.tranche_age
;
quit;
run;