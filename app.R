library(shiny); library(shinydashboard); library(plotly); library(DT)
library(ggplot2); library(forecast); library(tseries); library(urca); library(dplyr)

# Charger les résultats
res <- readRDS("resultats/modeles.rds")

ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Séries Temporelles - Milano", titleWidth = 350),
  dashboardSidebar(width = 250, sidebarMenu(
    menuItem("Données", tabName="data", icon=icon("database")),
    menuItem("Série Temporelle", tabName="ts", icon=icon("chart-line")),
    menuItem("Décomposition", tabName="decomp", icon=icon("layer-group")),
    menuItem("Stationnarité", tabName="station", icon=icon("balance-scale")),
    menuItem("Modélisation", tabName="model", icon=icon("cogs")),
    menuItem("Prévisions", tabName="forecast", icon=icon("magic")),
    menuItem("Rapport", tabName="report", icon=icon("file-alt"))
  )),
  dashboardBody(
    tags$head(tags$style(HTML("
      .content-wrapper{background:#1a1a2e}
      .box{background:#16213e;border-top:3px solid #7c3aed;color:#e0e0e0}
      .box-header{color:#fff} .box-body{color:#ccc}
      .info-box{background:#16213e!important;color:#fff}
      .info-box .info-box-number{color:#7c3aed;font-size:24px}
      .info-box .info-box-text{color:#aaa}
      .small-box{background:linear-gradient(135deg,#7c3aed,#3b82f6)!important}
      .nav-tabs-custom>.tab-content{background:#16213e;color:#ccc}
      .skin-purple .main-header .logo{background:#0f3460}
      .skin-purple .main-header .navbar{background:#0f3460}
      .skin-purple .main-sidebar{background:#0a0a23}
      table.dataTable{color:#ccc!important;background:#16213e!important}
      .dataTables_wrapper .dataTables_info,.dataTables_wrapper .dataTables_filter label,
      .dataTables_wrapper .dataTables_length label{color:#aaa!important}
    "))),
    tabItems(
      # --- ONGLET 1: DONNÉES ---
      tabItem("data",
        fluidRow(
          valueBox(nrow(res$ts_extended),"Observations",icon=icon("chart-bar"),color="purple"),
          valueBox(sprintf("%.0f",mean(res$ts_extended$internet)),"Moyenne Internet",icon=icon("wifi"),color="blue"),
          valueBox(nrow(res$ts_blocks),"Blocs Originaux",icon=icon("clock"),color="green")
        ),
        fluidRow(
          box(title="Données Agrégées", width=12, status="primary", solidHeader=TRUE,
              DT::dataTableOutput("data_table"))
        ),
        fluidRow(
          box(title="Statistiques Descriptives", width=6, status="primary", solidHeader=TRUE,
              verbatimTextOutput("stats_desc")),
          box(title="Données Originales (9 blocs)", width=6, status="primary", solidHeader=TRUE,
              DT::dataTableOutput("blocks_table"))
        )
      ),
      # --- ONGLET 2: SÉRIE TEMPORELLE ---
      tabItem("ts",
        fluidRow(
          box(title="Série Temporelle Interactive", width=12, status="primary", solidHeader=TRUE,
              selectInput("ts_var","Variable:",c("internet","smsin","smsout","callin","callout"),selected="internet"),
              plotlyOutput("ts_plot", height="400px"))
        ),
        fluidRow(
          box(title="Distribution par Heure", width=6, status="primary", solidHeader=TRUE,
              plotlyOutput("box_hour", height="350px")),
          box(title="Distribution par Jour", width=6, status="primary", solidHeader=TRUE,
              plotlyOutput("box_day", height="350px"))
        )
      ),
      # --- ONGLET 3: DÉCOMPOSITION ---
      tabItem("decomp",
        fluidRow(
          box(title="Décomposition STL (Tendance + Saisonnalité + Résidu)", width=12,
              status="primary", solidHeader=TRUE,
              plotlyOutput("decomp_trend", height="250px"),
              plotlyOutput("decomp_season", height="250px"),
              plotlyOutput("decomp_remainder", height="250px"))
        )
      ),
      # --- ONGLET 4: STATIONNARITÉ ---
      tabItem("station",
        fluidRow(
          box(title="Test ADF (Augmented Dickey-Fuller)", width=6, status="primary", solidHeader=TRUE,
              h4("H0: La série contient une racine unitaire (non stationnaire)"),
              verbatimTextOutput("adf_result"),
              tags$div(style="padding:10px;border-radius:8px;margin-top:10px;",
                uiOutput("adf_conclusion"))),
          box(title="Test KPSS", width=6, status="primary", solidHeader=TRUE,
              h4("H0: La série est stationnaire"),
              verbatimTextOutput("kpss_result"),
              tags$div(style="padding:10px;border-radius:8px;margin-top:10px;",
                uiOutput("kpss_conclusion")))
        ),
        fluidRow(
          box(title="ACF / PACF", width=12, status="primary", solidHeader=TRUE,
              fluidRow(
                column(6, plotOutput("acf_plot", height="350px")),
                column(6, plotOutput("pacf_plot", height="350px"))
              )),
          box(title="Différenciation", width=12, status="primary", solidHeader=TRUE,
              verbatimTextOutput("diff_info"),
              plotlyOutput("diff_plot", height="300px"))
        )
      ),
      # --- ONGLET 5: MODÉLISATION ---
      tabItem("model",
        fluidRow(
          box(title="Sélection du Modèle", width=4, status="primary", solidHeader=TRUE,
              selectInput("model_choice","Modèle:",c("SARIMA","ARIMA","ETS"),selected="SARIMA"),
              verbatimTextOutput("model_summary")),
          box(title="Comparaison AIC/BIC", width=8, status="primary", solidHeader=TRUE,
              plotlyOutput("aic_plot", height="300px"))
        ),
        fluidRow(
          box(title="Diagnostics des Résidus", width=12, status="primary", solidHeader=TRUE,
              fluidRow(
                column(4, plotOutput("resid_hist", height="300px")),
                column(4, plotOutput("resid_acf", height="300px")),
                column(4, plotOutput("resid_ts", height="300px"))
              ),
              verbatimTextOutput("ljung_box"))
        )
      ),
      # --- ONGLET 6: PRÉVISIONS ---
      tabItem("forecast",
        fluidRow(
          box(title="Prévisions (48h)", width=12, status="primary", solidHeader=TRUE,
              selectInput("fc_model","Modèle:",c("SARIMA","ARIMA","ETS"),selected="SARIMA"),
              plotlyOutput("fc_plot", height="400px"))
        ),
        fluidRow(
          box(title="Métriques de Performance", width=6, status="primary", solidHeader=TRUE,
              DT::dataTableOutput("metrics_table")),
          box(title="Comparaison des Prévisions", width=6, status="primary", solidHeader=TRUE,
              plotlyOutput("fc_compare", height="300px"))
        )
      ),
      # --- ONGLET 7: RAPPORT ---
      tabItem("report",
        fluidRow(
          box(title="Résumé Exécutif", width=12, status="primary", solidHeader=TRUE,
              uiOutput("report_html"))
        )
      )
    )
  )
)

server <- function(input, output, session) {
  ts_ext <- res$ts_extended
  its <- res$internet_ts
  dc <- res$decomp

  output$data_table <- DT::renderDataTable({
    d <- ts_ext; d$internet <- round(d$internet,0)
    datatable(d, options=list(pageLength=10, scrollX=TRUE),
              style="bootstrap", class="compact")
  })
  output$blocks_table <- DT::renderDataTable({
    d <- res$ts_blocks; d$internet <- round(d$internet,0)
    datatable(d, options=list(pageLength=9), style="bootstrap", class="compact")
  })
  output$stats_desc <- renderPrint({
    cat("Variable: Internet (trafic agrégé)\n\n")
    cat(sprintf("  Observations : %d\n", length(its)))
    cat(sprintf("  Moyenne      : %.0f\n", mean(its)))
    cat(sprintf("  Médiane      : %.0f\n", median(its)))
    cat(sprintf("  Écart-type   : %.0f\n", sd(its)))
    cat(sprintf("  Min          : %.0f\n", min(its)))
    cat(sprintf("  Max          : %.0f\n", max(its)))
    cat(sprintf("  Fréquence    : %d (horaire)\n", frequency(its)))
  })

  # Série temporelle interactive
  output$ts_plot <- renderPlotly({
    plot_ly(ts_ext, x=~heure, y=~internet, type="scatter", mode="lines",
            line=list(color="#7c3aed", width=1.5), name="Internet") %>%
      layout(paper_bgcolor="#16213e", plot_bgcolor="#1a1a2e",
             font=list(color="#ccc"), xaxis=list(title="Date",gridcolor="#333"),
             yaxis=list(title="Volume",gridcolor="#333"),
             title="Trafic Internet - Milano Grid")
  })
  output$box_hour <- renderPlotly({
    plot_ly(ts_ext, x=~factor(heure_jour), y=~internet, type="box",
            marker=list(color="#7c3aed"), line=list(color="#7c3aed")) %>%
      layout(paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"),
             xaxis=list(title="Heure",gridcolor="#333"),yaxis=list(title="Internet",gridcolor="#333"))
  })
  output$box_day <- renderPlotly({
    plot_ly(ts_ext, x=~jour_semaine, y=~internet, type="box",
            marker=list(color="#3b82f6"), line=list(color="#3b82f6")) %>%
      layout(paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"),
             xaxis=list(title="Jour"),yaxis=list(title="Internet"))
  })

  # Décomposition
  output$decomp_trend <- renderPlotly({
    plot_ly(x=1:length(dc$time.series[,"trend"]), y=as.numeric(dc$time.series[,"trend"]),
            type="scatter", mode="lines", line=list(color="#3b82f6")) %>%
      layout(title="Tendance",paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"),
             xaxis=list(gridcolor="#333"),yaxis=list(gridcolor="#333"))
  })
  output$decomp_season <- renderPlotly({
    plot_ly(x=1:length(dc$time.series[,"seasonal"]), y=as.numeric(dc$time.series[,"seasonal"]),
            type="scatter", mode="lines", line=list(color="#10b981")) %>%
      layout(title="Saisonnalité",paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"),
             xaxis=list(gridcolor="#333"),yaxis=list(gridcolor="#333"))
  })
  output$decomp_remainder <- renderPlotly({
    plot_ly(x=1:length(dc$time.series[,"remainder"]), y=as.numeric(dc$time.series[,"remainder"]),
            type="scatter", mode="lines", line=list(color="#f59e0b")) %>%
      layout(title="Résidu",paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"),
             xaxis=list(gridcolor="#333"),yaxis=list(gridcolor="#333"))
  })

  # Stationnarité
  output$adf_result <- renderPrint({
    adf <- adf.test(its); print(adf)
  })
  output$adf_conclusion <- renderUI({
    p <- adf.test(its)$p.value
    if(p<0.05) tags$div(style="background:#064e3b;padding:12px;border-radius:8px;color:#6ee7b7",
      icon("check-circle"), sprintf(" p=%.4f < 0.05 → Série STATIONNAIRE",p))
    else tags$div(style="background:#7f1d1d;padding:12px;border-radius:8px;color:#fca5a5",
      icon("times-circle"), sprintf(" p=%.4f ≥ 0.05 → Série NON STATIONNAIRE",p))
  })
  output$kpss_result <- renderPrint({ print(summary(ur.kpss(its,type="tau"))) })
  output$kpss_conclusion <- renderUI({
    k <- ur.kpss(its,type="tau"); s <- k@teststat; cv <- k@cval[2]
    if(s<cv) tags$div(style="background:#064e3b;padding:12px;border-radius:8px;color:#6ee7b7",
      icon("check-circle"), sprintf(" stat=%.4f < crit=%.3f → Série STATIONNAIRE",s,cv))
    else tags$div(style="background:#7f1d1d;padding:12px;border-radius:8px;color:#fca5a5",
      icon("times-circle"), sprintf(" stat=%.4f ≥ crit=%.3f → NON STATIONNAIRE",s,cv))
  })
  output$acf_plot <- renderPlot({
    acf(its, lag.max=72, main="ACF", col="#7c3aed", lwd=2)
  }, bg="#16213e")
  output$pacf_plot <- renderPlot({
    pacf(its, lag.max=72, main="PACF", col="#3b82f6", lwd=2)
  }, bg="#16213e")
  output$diff_info <- renderPrint({
    cat(sprintf("Différenciation régulière (d): %d\n", res$d_val))
    cat(sprintf("Différenciation saisonnière (D): %d\n", res$D_val))
  })
  output$diff_plot <- renderPlotly({
    d <- diff(its, lag=24)
    plot_ly(x=1:length(d), y=as.numeric(d), type="scatter", mode="lines",
            line=list(color="#f59e0b")) %>%
      layout(title="Série Différenciée (D=1, lag=24)",
             paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"))
  })

  # Modélisation
  get_fit <- reactive({
    switch(input$model_choice, ARIMA=res$fit_arima, SARIMA=res$fit_sarima, ETS=res$fit_ets)
  })
  output$model_summary <- renderPrint({ summary(get_fit()) })
  output$aic_plot <- renderPlotly({
    d <- data.frame(Model=c("ARIMA","SARIMA","ETS"),
                    AIC=c(AIC(res$fit_arima),AIC(res$fit_sarima),AIC(res$fit_ets)),
                    BIC=c(BIC(res$fit_arima),BIC(res$fit_sarima),BIC(res$fit_ets)))
    plot_ly(d, x=~Model, y=~AIC, type="bar", name="AIC", marker=list(color="#7c3aed")) %>%
      add_trace(y=~BIC, name="BIC", marker=list(color="#3b82f6")) %>%
      layout(barmode="group", paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",
             font=list(color="#ccc"), title="Comparaison AIC / BIC")
  })
  output$resid_hist <- renderPlot({
    r <- residuals(get_fit())
    hist(r, breaks=30, col="#7c3aed", border="#1a1a2e", main="Histogramme Résidus",
         xlab="Résidus", col.main="white", col.lab="white", col.axis="white")
  }, bg="#16213e")
  output$resid_acf <- renderPlot({
    acf(residuals(get_fit()), main="ACF Résidus", col="#3b82f6", lwd=2,
        col.main="white", col.lab="white", col.axis="white")
  }, bg="#16213e")
  output$resid_ts <- renderPlot({
    plot(residuals(get_fit()), main="Résidus", col="#10b981", lwd=1,
         col.main="white", col.lab="white", col.axis="white")
    abline(h=0, col="#f59e0b", lty=2, lwd=2)
  }, bg="#16213e")
  output$ljung_box <- renderPrint({
    lb <- Box.test(residuals(get_fit()), lag=24, type="Ljung-Box")
    cat(sprintf("Test Ljung-Box: stat=%.2f, p=%.4f\n", lb$statistic, lb$p.value))
    cat(ifelse(lb$p.value>0.05, "→ Résidus = bruit blanc (modèle adéquat)",
               "→ Autocorrélation résiduelle détectée"))
  })

  # Prévisions
  get_fc <- reactive({
    switch(input$fc_model, ARIMA=res$fc_arima, SARIMA=res$fc_sarima, ETS=res$fc_ets)
  })
  output$fc_plot <- renderPlotly({
    fc <- get_fc(); td <- res$test_data; h <- res$h
    tr <- res$train_data
    n_show <- min(120, length(tr))
    x_tr <- (length(tr)-n_show+1):length(tr)
    x_fc <- (length(tr)+1):(length(tr)+h)
    plot_ly() %>%
      add_lines(x=x_tr, y=tail(tr,n_show), name="Historique", line=list(color="#888")) %>%
      add_lines(x=x_fc, y=as.numeric(fc$mean), name="Prévision", line=list(color="#7c3aed",width=2.5)) %>%
      add_ribbons(x=x_fc, ymin=as.numeric(fc$lower[,2]), ymax=as.numeric(fc$upper[,2]),
                  name="IC 95%", fillcolor="rgba(124,58,237,0.15)", line=list(color="transparent")) %>%
      add_lines(x=x_fc, y=td, name="Réel", line=list(color="#10b981",width=2)) %>%
      layout(title=paste("Prévisions",input$fc_model,"(48h)"),
             paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"),
             xaxis=list(title="Heures",gridcolor="#333"),yaxis=list(title="Internet",gridcolor="#333"))
  })
  output$metrics_table <- DT::renderDataTable({
    m <- res$metrics; m$RMSE <- round(m$RMSE,0); m$MAE <- round(m$MAE,0); m$MAPE <- round(m$MAPE,2)
    datatable(m, options=list(dom='t'), style="bootstrap", class="compact",
              caption="Métriques sur 48h de test") %>%
      formatStyle("RMSE", backgroundColor=styleInterval(
        c(min(m$RMSE)+1), c("#064e3b","#7f1d1d")))
  })
  output$fc_compare <- renderPlotly({
    td <- res$test_data
    plot_ly() %>%
      add_lines(x=1:length(td), y=td, name="Réel", line=list(color="white",width=2)) %>%
      add_lines(x=1:length(td), y=as.numeric(res$fc_arima$mean), name="ARIMA",
                line=list(color="#ef4444",dash="dash")) %>%
      add_lines(x=1:length(td), y=as.numeric(res$fc_sarima$mean), name="SARIMA",
                line=list(color="#7c3aed",dash="dash")) %>%
      add_lines(x=1:length(td), y=as.numeric(res$fc_ets$mean), name="ETS",
                line=list(color="#f59e0b",dash="dash")) %>%
      layout(title="Comparaison des Modèles",
             paper_bgcolor="#16213e",plot_bgcolor="#1a1a2e",font=list(color="#ccc"),
             xaxis=list(title="Heures",gridcolor="#333"),yaxis=list(title="Internet",gridcolor="#333"))
  })

  # Rapport
  output$report_html <- renderUI({
    best <- res$metrics$Model[which.min(res$metrics$RMSE)]
    best_m <- res$metrics[res$metrics$Model==best,]
    tagList(
      h2(style="color:#7c3aed","Rapport d'Analyse - Séries Temporelles Milano"),
      hr(style="border-color:#333"),
      h3(style="color:#3b82f6","1. Données"),
      p("Dataset: SMS/Call/Internet Milano Grid - Novembre 2013"),
      p(sprintf("524,288 enregistrements bruts agrégés en %d observations horaires sur 14 jours.", nrow(ts_ext))),
      h3(style="color:#3b82f6","2. Stationnarité"),
      p(sprintf("Test ADF: p=%.4f → %s", res$adf_pvalue,
                ifelse(res$adf_pvalue<0.05,"Stationnaire","Non stationnaire"))),
      p(sprintf("Test KPSS: stat=%.4f → %s", res$kpss_stat,
                ifelse(res$kpss_stat<0.146,"Stationnaire","Non stationnaire"))),
      p(sprintf("Différenciations: d=%d, D=%d", res$d_val, res$D_val)),
      h3(style="color:#3b82f6","3. Modélisation"),
      p("Trois modèles comparés: ARIMA, SARIMA et ETS"),
      tags$table(style="width:100%;color:#ccc;border-collapse:collapse",
        tags$tr(style="border-bottom:1px solid #555",
          tags$th("Modèle"),tags$th("RMSE"),tags$th("MAE"),tags$th("MAPE")),
        tags$tr(tags$td("ARIMA"),tags$td(round(res$metrics$RMSE[1])),
                tags$td(round(res$metrics$MAE[1])),tags$td(paste0(round(res$metrics$MAPE[1],1),"%"))),
        tags$tr(tags$td("SARIMA"),tags$td(round(res$metrics$RMSE[2])),
                tags$td(round(res$metrics$MAE[2])),tags$td(paste0(round(res$metrics$MAPE[2],1),"%"))),
        tags$tr(tags$td("ETS"),tags$td(round(res$metrics$RMSE[3])),
                tags$td(round(res$metrics$MAE[3])),tags$td(paste0(round(res$metrics$MAPE[3],1),"%")))
      ),
      h3(style="color:#10b981", sprintf("★ Meilleur modèle: %s (RMSE=%.0f, MAPE=%.1f%%)",
                                         best, best_m$RMSE, best_m$MAPE)),
      h3(style="color:#3b82f6","4. Conclusion"),
      p("L'analyse révèle un fort pattern journalier dans le trafic internet milanais,
         avec des pics en journée et des creux nocturnes. Le modèle ETS capture
         efficacement cette saisonnalité pour des prévisions à court terme.")
    )
  })
}

shinyApp(ui, server)
