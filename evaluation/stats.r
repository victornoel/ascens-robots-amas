library(ggplot2)

maps <- c(
	"maze1",
	"maze2",
	"maze3",
	"maze5"
	)

algorithms <- c(
		#"amasE",
		"amasEV",
		"disperse",
		"levy"
		)

victims <- c("maze1" = 16, "maze2" = 16, "maze3" = 35, "maze5" = 16)

saveSVG <- function(plot, map, name) {
	fn <- file.path("pdf", paste0(map,"-",name,".svg"))
	print(paste0("saving to ",fn))
	ggsave(filename=fn, plot=plot, width=12, height=10)
}




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
	
	secureds <- data[!duplicated(data[,!(names(data) %in% c("step", "explored", "discovered"))]),]
	discovereds <- data[!duplicated(data[,!(names(data) %in% c("step", "explored", "secured"))]),]
	exploreds <- data[!duplicated(data[,!(names(data) %in% c("step", "secured", "discovered"))]),]

	# this keep only the lines about the time to secure max victims
	# TODO: differentiate the case with all victim saved, and the cases with min(max(victimssaved))
	#secureds2 <- secureds[!duplicated(secureds[,!(names(secureds) %in% c("step","explored","discovered","secured"))], fromLast=T),]
	#ggplot(secureds2[secureds2$algorithm != "levy",], aes(x=nbBots,y=step, linetype=algorithm, colour=rbRange)) + geom_line()

	p <- ggplot(data, aes(x=step)) +
		xlab("Steps") +
		facet_grid(nbBots ~ rbRange, labeller = label_both, scales="fixed") +
		ggtitle(map) +
		theme(aspect.ratio=1) +
		theme_bw()
	
	np <- p +
		geom_point(data = secureds, aes(y=secured, shape=algorithm)) +
		geom_line(data = secureds, aes(y=secured, shape=algorithm)) +
		scale_shape_manual(values=c(9,1,0)) +
		ylab("Victims") +
		ylim(0, victims[[map]])

	saveSVG(np, map, "victims")
	
	np <- p +
		geom_line(data = exploreds, aes(y=explored, linetype=algorithm)) +
		scale_linetype_manual(values=c("solid","dashed", "dotted")) +
		ylab("Explored (%)") +
		ylim(0, 100)

	saveSVG(np, map, "explored")
}
