args <- commandArgs(trailingOnly = TRUE)

library(ggplot2)
library(scales)

ifname = args[1]
ifname.exact = args[2]

bias = FALSE
if (length(args) > 2 && args[3] == "-bias") {
    bias = TRUE
}

PERCENT_ERROR_Y_LABEL = "Estimated percent error (95% confidence interval)"
OBSERVED_ERROR_Y_LABEL = "Observed percent error"
PERCENT_ERROR_X_LABEL = "Guess number"
LEGENED_LABEL = "Outside Confidence Interval"
OFNAME_ESTIMATE = 'monte_carlo_error_estimate.pdf'
OFNAME_OBSERVED = 'monte_carlo_observed_error.pdf'
COLNAMES = c("pwd", "prob", "guess.number", "var", "sample.size", "std.error",
             "percent.std.error")
COLNAMES_EXACT = c("pwd", "prob", "guess.number")

add_scales <- function (p) {
    p <- p + scale_x_log10(breaks = 10^seq(0,26, 3),
                           labels = trans_format("log10", math_format(10^.x)))
    p <- p + xlab(PERCENT_ERROR_X_LABEL)
    p <- p + theme_bw()
    p
}

estimates <- read.delim(ifname, sep = "\t", quote = NULL)
estimates[7] <- (estimates[6] / estimates[3])
colnames(estimates) <- COLNAMES
if (bias) {
    print("biasing estimates by one")
    estimates$guess.number <- estimates$guess.number + 1
}
estimates <- estimates[!duplicated(estimates$pwd), ]
p <- ggplot(estimates, aes(guess.number, percent.std.error))
p <- p + geom_point()
p <- add_scales(p)
p <- p + scale_y_continuous(labels = percent, limits = c(0, .5))
p <- p + ylab(PERCENT_ERROR_Y_LABEL)
ggsave(filename = OFNAME_ESTIMATE, plot = p)

actual <- read.delim(ifname.exact, sep = "\t", quote = NULL)
if (length(colnames(actual)) == 3) {
    print("Using 3 column input")
    colnames(actual) <- COLNAMES_EXACT
} else {
    print("Using 2 column input")
    colnames(actual) <- c("pwd", "guess.number")
}
print(head(actual))
actual <- actual[!duplicated(actual$pwd), ]
total <- merge(estimates, actual, by = "pwd", all=FALSE)

print("total")
print(nrow(total))
print("estimates")
print(nrow(estimates))
print("actual")
print(nrow(actual))

bothvalues <- total[total$guess.number.y > 0, ]
bothvalues$actual.percent.error <- (abs(
    bothvalues$guess.number.y - bothvalues$guess.number.x) /
    bothvalues$guess.number.y)
bothvalues$outside.interval <- ifelse(abs(
    bothvalues$guess.number.y - bothvalues$guess.number.x) <
    bothvalues$std.error, 0, 1)
p <- ggplot(bothvalues,
            aes(x = guess.number.x,
                y = actual.percent.error,
                colour = factor(outside.interval)))
p <- p + geom_point()
p <- add_scales(p)
p <- p + scale_color_discrete(LEGENED_LABEL)
p <- p + scale_y_continuous(labels = percent, limits = c(0, 1))
p <- p + ylab(OBSERVED_ERROR_Y_LABEL)
ggsave(filename = OFNAME_OBSERVED, plot = p)

print("percent outside interval")
print(sum(bothvalues$outside.interval) / nrow(bothvalues))
print("numb outside interval")
print(sum(bothvalues$outside.interval))
print("total number with both values defined")
print(nrow(bothvalues))

print("Examples of passwords outside interval")
outside <- bothvalues[bothvalues$outside.interval == 1, ]
print(head(outside[sample(nrow(outside)), ], 20))
print("max percent error")
print(max(outside$actual.percent.error))
