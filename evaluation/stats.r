library(ggplot2)
library(reshape2)

metrics <- c("secured", "discovered", "explored")
algorithms <- c("amas", "disperse", "levy")

for(metric in metrics) {
	data <- data.frame()
	for(algorithm in algorithms) {
		ndata = read.table(paste(algorithm,"-",metric,".csv",sep=""), header=T, sep=";")
		data <- rbind(data, ndata)
	}
	ggplot(data) +
		geom_line(aes(x=step, y=metric, colour=algorithm)) +
 		xlab('Steps') +
		ylab(metric)

	ggsave(paste(metric, ".pdf", sep=""))

}
