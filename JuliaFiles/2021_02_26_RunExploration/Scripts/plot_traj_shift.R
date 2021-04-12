library(stringr)

visualize_metric_fun <- function(observed_traj, simulation_traj,
                                 qoi_current, model_current, mapCR_current,
                                 input_paras = NA) {
  require(dplyr)
  obs_current <- observed_traj %>% filter(qoi == qoi_current, model == model_current, mapCR == mapCR_current)
  sim_current <- simulation_traj %>% filter(qoi == qoi_current, model == model_current, mapCR == mapCR_current)
  met_current <- metrics_table %>% filter(qoi == qoi_current, model == model_current, mapCR == mapCR_current)

  yrange <- range(c(obs_current$value, sim_current$value)) + c(-1, 1)

  if (qoi_current == "Np") {
    yrange <- c(0, 200)
  }
  xrange <- range(c(obs_current$t, sim_current$t)) + c(-1, 1)
  plot(obs_current$t, obs_current$value,
    type = "l", xlim = xrange,
    ylim = yrange, xlab = "", ylab = "", lwd = 1.5,
    main = paste(
      model_current, mapCR_current, qoi_current,
      ", Min. RMSE = ", round(min(met_current$metric), 1)
    )
    ## main = paste(model_current, mapCR_current, qoi_current,
    ##              ', Min. MSE =', round(min(met_current$value), 1),
    ##              ', shift =', round(min(met_current$shift), 1))
  )
  ## for(k in 1:max(sim_current$run)){
  for (k in met_current$run) {
    met_k <- met_current %>% filter(run == k)
    temp <- sim_current %>% filter(run == k)
    lines(temp$t, temp$value, col = "light blue")
    time_shift_intervals <- range(temp$t - met_k$shift)
    orig_interval <- range(temp$t)
    lower <- max(orig_interval[1], time_shift_intervals[1])
    upper <- min(orig_interval[2], time_shift_intervals[2])
    lines(temp$t[lower:upper], temp$value[lower:upper + met_k$shift], col = "blue")
    abline(v = max(temp$t) * met_k$Tmax, col = "red", lwd = 2)
    abline(v = max(temp$t) * met_k$Tmin, col = "red", lwd = 2)
  }
}

r <- "output/metrics_tables_(.*).csv"
metrics_paths <- Sys.glob(file.path("output/metrics_tables_*.csv"))

for (path in metrics_paths) {
  metric_name <- str_match(path, r)[1, 2]
  print(paste("Plotting trajectories for", metric_name))
  plot_path <- paste("output/traj_shifted_", metric_name, ".pdf", sep = "")

  simulation_traj <- read.csv("output/simulation_traj.csv")
  observed_traj <- read.csv("output/observed_traj.csv")
  metrics_table <- read.csv(path)
  qoi_list <- unique(observed_traj$qoi)
  model_list <- unique(observed_traj$model)
  mapCR_list <- unique(observed_traj$mapCR)
  pdf(plot_path, width = 8, height = 8)
  for (mapCR_current in mapCR_list) {
    for (model_current in model_list) {
      par(mfrow = c(4, 1), mar = c(2, 3, 2, 1))
      for (qoi_current in qoi_list) {
        visualize_metric_fun(observed_traj, simulation_traj, qoi_current, model_current, mapCR_current)
      }
    }
  }
  dev.off()
}
