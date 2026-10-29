DECKS := $(wildcard [0-9][0-9]-*.tex)
PDFS  := $(DECKS:.tex=.pdf)

all: $(PDFS)

%.pdf: %.tex preamble.tex
	tectonic --chatter minimal $<

clean:
	rm -f $(PDFS)

.PHONY: all clean
