
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+ 									Mutuelle fictive VousEtesBienChezNous (VEBCN)
+ 									 Indexation des tarifs pour l'exercice 2026
+ 									  Réalisation : Mongi Zaghdoudi - Juin 2025
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 								  	                       EXPORTS	 							             */

%let path_export=Z:\20250607 Indexation - mutuelle vebcn\3.outdata\;

/* Export de la table avec adresse pour publipostage */
proc export data=tarif
outfile = "&path_export.base_reporting.csv"
dbms=csv
replace;
dlm=';';
run;
