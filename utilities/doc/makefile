
manName=sixdesk

all: $(manName).pdf

clean:
	rm -f $(manName).blg $(manName).bbl $(manName).toc $(manName).out $(manName).aux $(manName).log $(manName).lot *~

cleanall:
	make clean
	rm -f $(manName).pdf

$(manName).pdf: *.tex
	pdflatex $(manName).tex
	pdflatex $(manName).tex
