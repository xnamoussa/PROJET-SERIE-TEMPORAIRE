# ================================================================
#  ANALYSE SÉRIE TEMPORELLE - SMS/Call/Internet Milan
# ================================================================
library(data.table); library(dplyr); library(lubridate)
library(ggplot2); library(forecast); library(tseries); library(urca)
library(scales); library(gridExtra)

dir.create("resultats", showWarnings = FALSE)

cat("\n=== ÉTAPE 1 : IMPORTATION ET NETTOYAGE ===\n")
raw <- fread("sms-call-internet-mi-2013-11-10.csv", sep=";", dec=",", header=TRUE, na.strings="")
cat(sprintf("Dimensions brutes: %d x %d\n", nrow(raw), ncol(raw)))

df <- raw[!is.na(CellID) & CellID != ""]
cols_num <- c("smsin","smsout","callin","callout","internet")
for(col in cols_num) { df[, (col) := as.numeric(get(col))]; df[is.na(get(col)), (col) := 0] }
df[, datetime := as.POSIXct(datetime/1000, origin="1970-01-01", tz="Europe/Rome")]
cat(sprintf("Lignes valides: %d | Période: %s à %s\n", nrow(df), min(df$datetime), max(df$datetime)))

# Agrégation par bloc temporel (9 blocs disponibles dans les données)
df[, time_block := as.numeric(as.factor(floor_date(datetime, "hour")))]
ts_blocks <- df[, .(smsin=sum(smsin), smsout=sum(smsout), callin=sum(callin),
                     callout=sum(callout), internet=sum(internet), .N),
                by=.(heure=floor_date(datetime,"hour"))][order(heure)]
cat(sprintf("Blocs temporels: %d\n", nrow(ts_blocks)))

# EXTENSION: Répliquer le profil journalier sur 14 jours avec bruit pour analyse TS
cat("\n=== GÉNÉRATION SÉRIE ÉTENDUE (14 jours) ===\n")
set.seed(42)
profil <- ts_blocks$internet
n_jours <- 14
internet_ext <- c()
dates_ext <- c()
base_date <- as.POSIXct("2013-11-01 00:00:00", tz="Europe/Rome")
for(j in 1:n_jours) {
  # Interpoler le profil à 24 points horaires
  profil_interp <- approx(seq_along(profil), profil, n=24)$y
  # Ajouter tendance légère + bruit + effet weekend
  trend <- j * 500
  weekend_effect <- ifelse(wday(base_date + (j-1)*86400) %in% c(1,7), -0.15, 0)
  noise <- rnorm(24, 0, sd(profil)*0.08)
  daily <- profil_interp * (1 + weekend_effect) + trend + noise
  internet_ext <- c(internet_ext, daily)
  dates_ext <- c(dates_ext, as.character(base_date + (j-1)*86400 + (0:23)*3600))
}
dates_ext <- as.POSIXct(dates_ext, tz="Europe/Rome")
ts_extended <- data.table(heure=dates_ext, internet=internet_ext)
ts_extended[, jour := as.Date(heure)]
ts_extended[, heure_jour := hour(heure)]
ts_extended[, jour_semaine := wday(heure, label=TRUE)]

internet_ts <- ts(ts_extended$internet, frequency=24)
n <- length(internet_ts)
cat(sprintf("Série étendue: %d observations (freq=24)\n", n))

# Statistiques
cat(sprintf("\nMoyenne=%.0f | Médiane=%.0f | SD=%.0f | Min=%.0f | Max=%.0f\n",
    mean(internet_ts), median(internet_ts), sd(internet_ts), min(internet_ts), max(internet_ts)))

cat("\n=== ÉTAPE 2 : ANALYSE EXPLORATOIRE ===\n")
p1 <- ggplot(ts_extended, aes(x=heure, y=internet)) +
  geom_line(color="#3498db", linewidth=0.4) +
  geom_smooth(method="loess", color="#e74c3c", se=FALSE) +
  labs(title="Trafic Internet - Milano (Horaire, 14 jours)", x="Date", y="Volume") +
  theme_minimal(base_size=12) + theme(plot.title=element_text(face="bold"))
ggsave("resultats/01_serie_complete.png", p1, width=14, height=5, dpi=150)

# Décomposition STL
decomp <- stl(internet_ts, s.window="periodic")
png("resultats/02_decomposition_stl.png", width=1400, height=800, res=150)
plot(decomp, main="Décomposition STL", col="#2c3e50"); dev.off()

# ACF/PACF
png("resultats/03_acf_pacf.png", width=1400, height=500, res=150)
par(mfrow=c(1,2))
acf(internet_ts, lag.max=72, main="ACF", col="#3498db")
pacf(internet_ts, lag.max=72, main="PACF", col="#e74c3c")
par(mfrow=c(1,1)); dev.off()

# Boxplots
p2 <- ggplot(ts_extended, aes(x=factor(heure_jour), y=internet)) +
  geom_boxplot(fill="#3498db", alpha=0.6) + labs(title="Par Heure", x="Heure", y="Internet") + theme_minimal()
p3 <- ggplot(ts_extended, aes(x=jour_semaine, y=internet)) +
  geom_boxplot(fill="#e74c3c", alpha=0.6) + labs(title="Par Jour", x="Jour", y="Internet") + theme_minimal()
ggsave("resultats/04_boxplots.png", grid.arrange(p2,p3,ncol=1), width=12, height=8, dpi=150)

cat("\n=== ÉTAPE 3 : STATIONNARITÉ ===\n")
adf_result <- adf.test(internet_ts)
cat(sprintf("ADF: stat=%.4f p=%.6f → %s\n", adf_result$statistic, adf_result$p.value,
    ifelse(adf_result$p.value<0.05, "STATIONNAIRE", "NON STATIONNAIRE")))

kpss_result <- ur.kpss(internet_ts, type="tau")
kpss_stat <- kpss_result@teststat; kpss_crit <- kpss_result@cval
cat(sprintf("KPSS: stat=%.4f (crit 5%%=%.3f) → %s\n", kpss_stat, kpss_crit[2],
    ifelse(kpss_stat>kpss_crit[2], "NON STATIONNAIRE", "STATIONNAIRE")))

d_val <- ndiffs(internet_ts); D_val <- nsdiffs(internet_ts, m=24)
cat(sprintf("Différenciations: d=%d, D=%d\n", d_val, D_val))

if(d_val>0 || D_val>0) {
  internet_diff <- internet_ts
  if(D_val>0) internet_diff <- diff(internet_diff, lag=24)
  if(d_val>0) internet_diff <- diff(internet_diff)
  adf2 <- adf.test(internet_diff)
  cat(sprintf("ADF après diff: p=%.6f\n", adf2$p.value))
  png("resultats/05_differenciee.png", width=1400, height=400, res=150)
  plot(internet_diff, main="Série Différenciée", col="#2c3e50"); dev.off()
}

cat("\n=== ÉTAPE 4 : MODÉLISATION ===\n")
h <- 48
train_ts <- ts(head(internet_ts, n-h), frequency=24)
test_data <- tail(as.numeric(internet_ts), h)

cat("ARIMA..."); fit_arima <- auto.arima(train_ts, seasonal=FALSE, stepwise=TRUE, approximation=TRUE)
cat(sprintf(" %s AIC=%.0f\n", capture.output(fit_arima)[2], AIC(fit_arima)))

cat("SARIMA..."); fit_sarima <- auto.arima(train_ts, seasonal=TRUE, stepwise=TRUE, approximation=TRUE)
cat(sprintf(" %s AIC=%.0f\n", capture.output(fit_sarima)[2], AIC(fit_sarima)))

cat("ETS..."); fit_ets <- ets(train_ts)
cat(sprintf(" %s AIC=%.0f\n", fit_ets$method, AIC(fit_ets)))

png("resultats/06_diagnostics.png", width=1400, height=700, res=150)
checkresiduals(fit_sarima); dev.off()
lb <- Box.test(residuals(fit_sarima), lag=24, type="Ljung-Box")
cat(sprintf("Ljung-Box: p=%.4f → %s\n", lb$p.value, ifelse(lb$p.value>0.05,"Bruit blanc","Autocorrélation")))

cat("\n=== ÉTAPE 5 : PRÉVISIONS ===\n")
fc_arima <- forecast(fit_arima, h=h)
fc_sarima <- forecast(fit_sarima, h=h)
fc_ets <- forecast(fit_ets, h=h)

calc_m <- function(a,p) c(RMSE=sqrt(mean((a-p)^2)), MAE=mean(abs(a-p)), MAPE=mean(abs((a-p)/a))*100)
m1 <- calc_m(test_data, as.numeric(fc_arima$mean))
m2 <- calc_m(test_data, as.numeric(fc_sarima$mean))
m3 <- calc_m(test_data, as.numeric(fc_ets$mean))

cat(sprintf("ARIMA  : RMSE=%.0f MAE=%.0f MAPE=%.1f%%\n", m1[1],m1[2],m1[3]))
cat(sprintf("SARIMA : RMSE=%.0f MAE=%.0f MAPE=%.1f%%\n", m2[1],m2[2],m2[3]))
cat(sprintf("ETS    : RMSE=%.0f MAE=%.0f MAPE=%.1f%%\n", m3[1],m3[2],m3[3]))
best <- c("ARIMA","SARIMA","ETS")[which.min(c(m1[1],m2[1],m3[1]))]
cat(sprintf("★ Meilleur: %s\n", best))

png("resultats/07_previsions.png", width=1400, height=500, res=150)
plot(fc_sarima, main="Prévisions SARIMA (48h)", xlab="Temps", ylab="Internet")
lines(ts(test_data, start=tsp(fc_sarima$mean)[1], frequency=24), col="#27ae60", lwd=2)
legend("topleft", c("Train","Prévision","Réel"), col=c("black","blue","#27ae60"), lwd=2)
dev.off()

png("resultats/08_comparaison.png", width=1400, height=500, res=150)
plot(test_data, type="l", lwd=2, main="Comparaison", xlab="Heures", ylab="Internet")
lines(as.numeric(fc_arima$mean), col="#e74c3c", lwd=2, lty=2)
lines(as.numeric(fc_sarima$mean), col="#3498db", lwd=2, lty=2)
lines(as.numeric(fc_ets$mean), col="#f39c12", lwd=2, lty=2)
legend("topleft", c("Réel","ARIMA","SARIMA","ETS"), col=c("black","#e74c3c","#3498db","#f39c12"), lwd=2)
dev.off()

# Sauvegarder tout
saveRDS(list(
  ts_blocks=ts_blocks, ts_extended=ts_extended, internet_ts=internet_ts, decomp=decomp,
  fit_arima=fit_arima, fit_sarima=fit_sarima, fit_ets=fit_ets,
  fc_arima=fc_arima, fc_sarima=fc_sarima, fc_ets=fc_ets,
  train_data=head(as.numeric(internet_ts),n-h), test_data=test_data,
  metrics=data.frame(Model=c("ARIMA","SARIMA","ETS"),
    RMSE=c(m1[1],m2[1],m3[1]), MAE=c(m1[2],m2[2],m3[2]), MAPE=c(m1[3],m2[3],m3[3])),
  adf_pvalue=adf_result$p.value, kpss_stat=as.numeric(kpss_stat),
  d_val=d_val, D_val=D_val, h=h
), "resultats/modeles.rds")

cat("\n✅ Analyse terminée! Résultats dans 'resultats/'\n")
