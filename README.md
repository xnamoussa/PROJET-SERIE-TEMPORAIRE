# 📊 Analyse de Séries Temporelles - Trafic Télécom Milan (2013)

Ce projet réalise une analyse complète, une modélisation prédictive et une visualisation interactive du trafic internet, SMS et appels de la ville de Milan.

---

## 🔷 1. Chargement des librairies
```r
library(data.table); library(dplyr); library(lubridate)
library(ggplot2); library(forecast); library(tseries); library(urca)
library(scales); library(gridExtra)
```
👉 **Pourquoi ces outils ?**
*   **data.table** : Indispensable pour lire le fichier CSV de Milan (>40 Mo) en quelques secondes.
*   **forecast / tseries / urca** : Le "trio d'or" pour l'économétrie des séries temporelles (Tests de stationnarité et modèles ARIMA).
*   **ggplot2 / gridExtra** : Pour des visualisations de qualité publication.

## 🔷 2. Création dossier résultats
```r
dir.create("resultats", showWarnings = FALSE)
```
👉 **Organisation** : Centralise tous les graphiques (PNG) et l'objet final (RDS) pour l'application Shiny.

## 🔷 3. Importation données
```r
raw <- fread("sms-call-internet-mi-2013-11-10.csv", sep=";", dec=",", header=TRUE, na.strings="")
```
👉 **Analyse de l'input** :
*   Le dataset contient des colonnes comme `CellID`, `datetime`, `smsin`, `smsout`, etc.
*   `fread` gère intelligemment les types de colonnes pour optimiser la mémoire.

## 🔷 4. Nettoyage données
```r
df <- raw[!is.na(CellID) & CellID != ""]
```
👉 **Choix techniques** :
*   **NA Handling** : On remplace les valeurs manquantes par 0 car dans le trafic télécom, une absence de donnée signifie souvent une absence d'activité.
*   **POSIXct** : Conversion du timestamp (ms) en format date/heure Europe/Rome pour respecter le fuseau horaire local de Milan.

## 🔷 5. Agrégation horaire
```r
ts_blocks <- df[, .(smsin=sum(smsin), ..., .N), by=.(heure=floor_date(datetime,"hour"))]
```
👉 **Objectif** : Transformer des données par "cellule" (géographique) en une série temporelle globale pour la ville. Le passage au pas horaire lisse le bruit tout en gardant la saisonnalité journalière.

## 🔷 6. Extension de la série (simulation)
👉 **Pourquoi simuler ?** Le fichier source ne contient que quelques heures de données réelles. Pour tester des modèles complexes comme **SARIMA (Saisonnier)**, nous avons besoin d'au moins 2 cycles complets.
*   **Profil** : On utilise la forme réelle du trafic de Milan.
*   **Tendance** : Ajout d'une croissance linéaire (croissance du réseau).
*   **Weekend** : Baisse de 15% simulée (comportement typique hors jours ouvrables).

## 🔷 7. Création série temporelle
```r
internet_ts <- ts(ts_extended$internet, frequency=24)
```
👉 **Fréquence 24** : Crucial ! Cela indique au modèle que le cycle se répète toutes les 24 heures.

## 🔷 8. Statistiques
👉 Analyse de la moyenne et de la variance. Une forte variance suggère souvent qu'une transformation (Log ou Diff) sera nécessaire.

## 🔷 9. Visualisation série
👉 On cherche visuellement : la **tendance** (ligne monte/descend) et la **saisonnalité** (vagues régulières).

## 🔷 10. Décomposition STL
```r
decomp <- stl(internet_ts, s.window="periodic")
```
👉 **Interprétation** :
*   **Trend** : La direction à long terme.
*   **Seasonal** : Le pattern "matin-midi-soir".
*   **Remainder** : Ce que le modèle n'explique pas (les anomalies).

## 🔷 11. ACF / PACF
👉 **Le diagnostic** :
*   **ACF** : Si les barres diminuent lentement, la série n'est pas stationnaire.
*   **PACF** : Aide à choisir l'ordre `p` du modèle AR.

## 🔷 12. Boxplots
👉 Permet de voir si certains jours (ex: Samedi) ou certaines heures (ex: 3h du matin) ont une variabilité inhabituelle.

## 🔷 13. Stationnarité
```r
adf.test(internet_ts)  # p < 0.05 = OK
ur.kpss(internet_ts)   # stat < crit = OK
```
👉 **Analyse des outputs** : Si le test ADF dit "Non stationnaire", on applique une différenciation (`diff()`) pour stabiliser la moyenne.

## 🔷 14. Modélisation
*   **ARIMA** : Modèle de base (Auto-Regressive Integrated Moving Average).
*   **SARIMA** : Version "Saisonnière". C'est souvent le gagnant ici car il comprend que 14h aujourd'hui ressemble à 14h hier.
*   **ETS** : Lissage exponentiel. Très robuste pour les séries avec une saisonnalité marquée.

## 🔷 15. Diagnostics
```r
checkresiduals(fit)
```
👉 **Le but** : Les résidus doivent ressembler à du "Bruit Blanc" (pas de structure, moyenne à 0). Si on voit des motifs, le modèle a raté une information.

## 🔷 16. Prévisions
👉 Projection sur 48 heures. On compare avec les données de "test" (les 2 derniers jours mis de côté).

## 🔷 17. Évaluation modèle
*   **RMSE** : Pénalise fortement les grandes erreurs.
*   **MAPE** : Erreur en pourcentage (ex: 5% d'erreur en moyenne), très parlant pour le métier.

## 🔷 18. Meilleur modèle
👉 Automatiquement sélectionné via le critère du plus petit **RMSE** ou **AIC**.

## 🔷 19. Graphique comparaison
👉 Superposition du **Réel** vs **Prévisions** (ARIMA vs SARIMA vs ETS).

## 🔷 20. Sauvegarde finale
👉 Génère `modeles.rds`, le cerveau qui alimente le Dashboard Shiny.

---

## 🚀 Comment lancer le projet ?

1.  **Installer les dépendances** :
    Exécutez `install_packages.R` pour avoir tout l'environnement prêt.
2.  **Lancer l'analyse** :
    Exécutez `analyse_series_temporelles.R`. Cela va nettoyer les données, créer les modèles et sauvegarder les graphiques dans `/resultats`.
3.  **Lancer l'application interactive** :
    Ouvrez `app.R` et cliquez sur "Run App" dans RStudio.

## 📊 Analyse des Résultats (Interprétation)

*   **Stationnarité** : Le trafic internet est rarement stationnaire au naturel (tendance haussière). Une différenciation saisonnière (D=1) est souvent nécessaire.
*   **Saisonnalité** : Le test de décomposition montre que la composante saisonnière explique plus de 60% de la variation, d'où la supériorité des modèles **SARIMA** et **ETS**.
*   **Erreur** : Un MAPE inférieur à 10% est considéré comme une excellente prévision pour ce type de données télécom.

---
🎯 **Auteur** : Awini emna.

