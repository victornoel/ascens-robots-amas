library(ggplot2)

maps <- list("maze1","maze2","maze3","maze5")
nbVict <- list("8", "16", "35")

for(m in maps) {
	pattern <- paste0("^run.*",m,".*csv$")
	data <- data.frame(stringsAsFactors = F)
	for(file in list.files(pattern=pattern)) {
		print(paste0("reading file ",file))
		ndata = read.table(file, header=T, sep=";", stringsAsFactors = F, colClasses=c('numeric','numeric','numeric','numeric','character','character','character','character','character'))
		data <- rbind(data, ndata)
	}
	for(nb in nbVict) {
		d <- data[data$nbVictims == nb,]
		if (nrow(d) == 0) break
		p <- ggplot(d,aes(x=step))
		rp <- p +
			geom_step(aes(y=secured, colour=algorithm, linetype="Secured")) +
			geom_step(aes(y=discovered, colour=algorithm, linetype="Discovered")) +
			scale_linetype_manual("Victims", 
						values = c("Secured" = "solid", "Discovered" = "dashed")) +
			facet_grid(nbBots ~ rbRange, labeller = label_both) +
			labs(title=paste(nb, "Victims,",m), y="victims")
		ggsave(filename=file.path("pdf", paste0(m,"-",nb,"-victims.pdf")), plot=rp)
		rp <- p +
			geom_step(aes(y=explored, colour=algorithm)) +
			ylim(0,100) +
			facet_grid(nbBots ~ rbRange, labeller = label_both) +
			labs(title=paste(nb, "Victims,",m))
		ggsave(filename=file.path("pdf", paste0(m,"-",nb,"-explored.pdf")), plot=rp)
	}
}
