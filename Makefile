all: sandbox.html

%.Rmd: %.R
	Rscript -e "knitr::spin('$<', FALSE, format='Rmd')"

%.html: %.Rmd
	Rscript -e "knitr::knit2html('$<')"
