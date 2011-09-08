MODULES=\
	ThreadScope_Tour\
	ThreadScope_Tour/Install\
	ThreadScope_Tour/Run\
	ThreadScope_Tour/Statistics\

all: all-wiki all-html

all-wiki: $(patsubst %, %.wiki, $(MODULES))

all-html: $(patsubst %, %.html, $(MODULES))

%.wiki : %.md
	pandoc -f markdown -t mediawiki $< -o $@

%.html : %.md
	pandoc -f markdown -t html $< -o $@
