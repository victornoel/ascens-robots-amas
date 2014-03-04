library(ggplot2)

metrics <- list("secured", "discovered", "explored")
parameters <- list("algorithm", "nbBots", "nbVictims", "map", "rbRange")

pattern <- "^run.*csv$"
pattern <- "^run.*maze3.*csv"
pattern <- "^run.*maze3.*nbVictims.35.*csv"

data <- data.frame(stringsAsFactors = F)
for(file in list.files(pattern=pattern)) {
	print(paste0("reading file ",file))
	ndata = read.table(file, header=T, sep=";", stringsAsFactors = F, colClasses=c('numeric','numeric','numeric','numeric','character','character','character','character','character'))
	data <- rbind(data, ndata)
}

# geom_line(aes(x=step, y=secured, colour=nbBots)) + scale_colour_hue() + facet_grid(rbRange ~ nbVictims)
# p + stat_summary(aes(x=nbBots, y=explored), fun.y = "max", geom="point") + facet_grid(rbRange ~ nbVictims)
# p + geom_step(aes(x=step, y=secured, colour=algorithm)) + facet_grid(nbBots ~ rbRange, labeller = label_both) + labs(title="35 Victims, Maze 3")
# p + geom_step(aes(x=step, y=secured, colour=rbRange)) + facet_grid(nbBots ~ nbVictims, labeller = label_both) + labs(title="Maze 3") 

parametersValues <- list()
for(parameter in parameters) {
	parametersValues[[parameter]] <- unique(data[[parameter]])
}

for(m in metrics) {
	# no need to generate for map
	for(p in parameters) {
		paramsWithoutThisOne <- parameters[parameters != p]
		paramsValues <- parametersValues[names(parametersValues) %in% paramsWithoutThisOne]
		# cartesian product
		possibilities <- expand.grid(paramsValues, stringsAsFactors = F)
		for(i in 1:nrow(possibilities)) {
			# this is all the data with the parameters fixed and p varying
			fixedParams <- possibilities[i,]
			title <- paste0(names(fixedParams), ": ", fixedParams, collapse=' ')
			pdata <- merge(data,fixedParams)
			# TODO check that pdata is not empty?
			if (nrow(pdata) > 0) {
				plot <- ggplot(pdata) +
					geom_step(aes_string(x="step", y=m, colour=p)) +
					scale_colour_hue() +
					xlab('Steps') +
					ylab(m) +
					ggtitle(title)
				name <- paste0(m,"-",p, "-", paste0(names(fixedParams), ".", fixedParams, collapse='_'),".pdf")
				print(paste0("printing ", name))
				ggsave(filename=file.path("pdf", name), plot=plot)
			}
		}
	}
}
