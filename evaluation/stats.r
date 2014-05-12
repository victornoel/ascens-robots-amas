library(ggplot2)

# can be edited
maps <- c(
	"maze1",
	"maze2",
	"maze3",
	"maze5"
	)

# can be edited
algorithms <- c(
		"amasE",
		"amasEV",
		"disperse",
		"levy"
		)

victims <- c("maze1" = 16, "maze2" = 16, "maze3" = 35, "maze5" = 16)
metrics <- c("secured", "discovered", "explored")

for(map in maps) {
	data <- data.frame()
	for(algo in algorithms) {
		
		pattern <- paste0("^run_map.",map,"_algorithm.",algo,"_.*_nbVictims.",victims[[map]],"_.*csv$")
		for(file in list.files(pattern=pattern)) {
			print(paste0("reading file ",file))
			ndata <- read.table(file, header=T, sep=";")
			data <- rbind(data, ndata)
		}
	}
	data$rbRange <- ordered(data$rbRange)
	data$nbVictims <- ordered(data$nbVictims)
	data$nbBots <- ordered(data$nbBots)
	for(metric in metrics) {
		p <- ggplot(data, aes(x=step, colour=algorithm)) +
			facet_grid(nbBots ~ rbRange, labeller = label_both, scales="fixed") +
			ggtitle(map) +
			theme(aspect.ratio=1) +
			geom_step(aes_string(y=metric), direction="hv", size=0.3) +
			ylab(metric)
		fn <- file.path("pdf", paste0(map,"-",metric,".svg"))
		print(paste0("saving to ",fn))
		ggsave(filename=fn, plot=p, width=10, height=8)
	}
}
