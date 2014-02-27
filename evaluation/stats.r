library(ggplot2)

metrics <- list("secured", "discovered", "explored")
parameters <- list("algorithm", "nbBots", "nbVictims", "map")

data <- data.frame(stringsAsFactors = F)
for(file in list.files(pattern="^run.*csv$")) {
	print(paste0("reading file ",file))
	ndata = read.table(file, header=T, sep=";", stringsAsFactors = F, colClasses=c('numeric','numeric','numeric','numeric','character','character','character','character'))
	data <- rbind(data, ndata)
}

parametersValues <- list()
for(parameter in parameters) {
	parametersValues[[parameter]] <- unique(data[[parameter]])
}

for(m in metrics) {
	# no need to generate for map
	for(p in parameters[parameters != "map"]) {
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
