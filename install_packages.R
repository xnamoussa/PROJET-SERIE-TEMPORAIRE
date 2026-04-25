# ============================================================
# Installation des packages nécessaires pour le projet
# Séries Temporelles - SMS/Call/Internet Milan
# ============================================================

packages_needed <- c(
  "forecast",     # Modèles ARIMA, SARIMA, auto.arima
  "urca",         # Test KPSS de stationnarité
  "shinydashboard", # Interface dashboard Shiny
  "shiny",        # Application web interactive
  "plotly",       # Graphiques interactifs
  "ggplot2",      # Visualisation
  "dplyr",        # Manipulation de données
  "lubridate",    # Manipulation de dates
  "DT",           # Tables interactives
  "tseries",      # Test ADF
  "data.table",   # Lecture rapide de gros fichiers
  "scales",       # Formatage des axes
  "highcharter",  # Graphiques avancés
  "viridis",      # Palettes de couleurs
  "gridExtra"     # Grilles de graphiques
)

# Installer uniquement les packages manquants
installed <- installed.packages()[, "Package"]
to_install <- packages_needed[!packages_needed %in% installed]

if (length(to_install) > 0) {
  cat("Installation de", length(to_install), "package(s) :\n")
  cat(paste(" -", to_install, collapse = "\n"), "\n\n")
  install.packages(to_install, repos = "https://cloud.r-project.org", dependencies = TRUE)
} else {
  cat("Tous les packages sont déjà installés.\n")
}

# Vérification
cat("\n=== Vérification des packages ===\n")
for (pkg in packages_needed) {
  status <- if (require(pkg, character.only = TRUE, quietly = TRUE)) "OK" else "ERREUR"
  cat(sprintf("  %-20s : %s\n", pkg, status))
}
cat("\nInstallation terminée avec succès!\n")

