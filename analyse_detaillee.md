# 📑 Analyse Approfondie des Résultats : Trafic Télécom Milano

Ce document présente une interprétation scientifique des résultats obtenus lors de l'analyse des séries temporelles du trafic internet de Milan.

---

## 1. Analyse de la Série Temporelle et Exploration (EDA)

### 📈 Graphique de la Série Complète (`01_serie_complete.png`)
*   **Observation** : On observe une oscillation régulière. Chaque pic correspond à une journée.
*   **Tendance** : Une légère pente ascendante est visible (ajoutée lors de la simulation), simulant la croissance naturelle de l'utilisation du réseau.
*   **Interprétation** : La série n'est pas "stationnaire en moyenne" car elle monte globalement. Elle nécessite une transformation avant modélisation.

### 📦 Boxplots par Heure et Jour (`04_boxplots.png`)
*   **Par Heure** : Les boxplots montrent un creux profond entre 2h et 5h du matin (sommeil) et un plateau élevé entre 10h et 22h.
*   **Par Jour** : On remarque une légère baisse d'activité le samedi et le dimanche (effet weekend simulé), ce qui indique une saisonnalité hebdomadaire en plus de la quotidienne.

---

## 2. Décomposition STL (`02_decomposition_stl.png`)

La décomposition sépare la série en trois blocs :
1.  **Trend (Tendance)** : Elle est lisse et croissante. Elle capte l'évolution de fond.
2.  **Seasonal (Saisonnalité)** : Elle est parfaitement régulière à 24h. C'est le signal le plus fort du dataset.
3.  **Remainder (Résidus)** : C'est le bruit aléatoire. Si ce bruit contient des pics isolés, ce sont des anomalies (ex: un événement spécial à Milan).

---

## 3. Stationnarité et Corrélation

### 📊 ACF et PACF (`03_acf_pacf.png`)
*   **ACF (Autocorrelation Function)** : On voit des pics significatifs tous les lags de 24 (24, 48, 72...). Cela confirme mathématiquement la saisonnalité journalière. La décroissance lente confirme la non-stationnarité.
*   **PACF (Partial ACF)** : Le premier pic très élevé suggère un fort lien avec l'heure précédente (Auto-Régressif d'ordre 1).

### ⚖️ Tests Statistiques
*   **ADF (Augmented Dickey-Fuller)** : Si p-value > 0.05, la série a une racine unitaire. Ici, la différenciation est nécessaire pour "aplatir" la série.
*   **KPSS** : Ce test confirme souvent l'inverse du test ADF. Si la stat est supérieure au seuil critique, la série doit être différenciée.

---

## 4. Interprétation des Modèles

### 🤖 Modèle ARIMA (Non-Saisonnier)
*   **Choix** : Utilisé comme "Baseline" (point de comparaison).
*   **Limitation** : Sans composante saisonnière, il prédit souvent une ligne droite qui suit la tendance, mais il rate les vagues jour/nuit. Son erreur (MAPE) est généralement élevée.

### 🤖 Modèle SARIMA (Saisonnier)
*   **Choix** : C'est le modèle le plus adapté aux données avec cycles fixes.
*   **Fonctionnement** : Il combine l'ARIMA classique avec des paramètres saisonniers $(P,D,Q)_{24}$.
*   **Performance** : Il capture les cycles avec précision. C'est souvent celui qui a le meilleur AIC car il "comprend" la structure des données.

### 🤖 Modèle ETS (Error, Trend, Seasonality)
*   **Choix** : Modèle de lissage exponentiel.
*   **Avantage** : Très efficace pour les prévisions à court terme. Il donne plus de poids aux observations récentes.
*   **Interprétation** : Si le trafic change brusquement de niveau, l'ETS s'adaptera plus vite qu'un SARIMA.

---

## 5. Diagnostic des Résidus (`06_diagnostics.png`)

Pour valider un modèle, on regarde ses erreurs (résidus) :
*   **Test de Ljung-Box** : On cherche une p-value > 0.05. Cela signifie que les erreurs sont purement aléatoires (Bruit Blanc).
*   **Histogramme** : Doit ressembler à une cloche (Loi Normale). Si les erreurs sont normalement distribuées, le modèle est fiable.

---

## 6. Évaluation et Prévisions (`07_previsions.png` & `08_comparaison.png`)

### Métriques d'erreur
*   **RMSE (Root Mean Squared Error)** : Nous donne l'erreur moyenne dans l'unité du trafic. Plus il est bas, mieux c'est.
*   **MAPE (Mean Absolute Percentage Error)** : C'est le juge de paix.
    *   **< 5%** : Exceptionnel.
    *   **5-15%** : Très bon.
    *   **> 25%** : Modèle à revoir.

### Conclusion du choix
Le graphique de comparaison (`08_comparaison.png`) montre quel modèle colle le mieux à la courbe verte (le réel). Dans ce projet, le **SARIMA** et l'**ETS** se battent souvent pour la première place grâce à leur gestion de la saisonnalité de 24h.

---
*Ce document sert de support à l'interprétation des résultats générés par le script `analyse_series_temporelles.R`.*
