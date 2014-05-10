library(ggplot2)

maps <- list("maze1", "maze2", "maze3", "maze5")

for(m in maps) {
	pattern <- paste0("^run.*",m,".*csv$")
	data <- data.frame()
	for(file in list.files(pattern=pattern)) {
		print(paste0("reading file ",file))
		ndata = read.table(file, header=T, sep=";")
		data <- rbind(data, ndata[ndata$step < 5000,])
	}
	data$rbRange <- ordered(data$rbRange)
	data$nbVictims <- ordered(data$nbVictims)
	p <- ggplot(data,aes(x=step, colour=algorithm, linetype=rbRange)) +
		scale_colour_hue(name="Algorithm") +
		scale_linetype(name="RB Range") +
		facet_grid(nbVictims ~ nbBots, labeller = label_both, scales="free_y") +
		ggtitle(m) +
		theme(aspect.ratio=1)
	rp <- p +
		geom_step(aes(y=secured), direction="vh") +
		#geom_point(aes(y=discovered)) +
		ylab("victims")
	ggsave(filename=file.path("pdf", paste0(m,"-victims.pdf")), plot=rp, scale=2, paper="a4r")
	rp <- p +
		geom_step(aes(y=explored), direction="vh") +
		ylim(0,100)
	ggsave(filename=file.path("pdf", paste0(m,"-explored.pdf")), plot=rp, scale=2, paper="a4r")
}
