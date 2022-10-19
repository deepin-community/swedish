SHELL=/bin/bash
BINFILES:=svenska.datalista svenska.aff diverse/COPYING diverse/copyright diverse/swedish.html diverse/svenska.html diverse/Makefile
VERSION:=$(shell cat diverse/version)

include konfigfil

xjdatalistor=$(wildcard [A-Z]*.[jJ]/*.data)
xjordlistor=$(wildcard [A-Z]*.[jJ]/*.ord)
xndatalistor=$(wildcard [A-Z]*.[nN]/*.data)
xnordlistor=$(wildcard [A-Z]*.[nN]/*.ord)
ordlistor=$(wildcard [A-Z]*.[jn]/*[ad0])
jlistor:=$(sort $(basename $(xjdatalistor) $(xjordlistor)))
nlistor:=$(sort $(basename $(xndatalistor) $(xnordlistor)))
jdatalistor:=$(addsuffix .data,$(jlistor))
jordlistor:=$(addsuffix .ord,$(jlistor))
ndatalistor:=$(addsuffix .data,$(nlistor))
nordlistor:=$(addsuffix .ord,$(nlistor))
jsynclistor:=$(addsuffix .sync,$(jlistor))
nsynclistor:=$(addsuffix .sync,$(nlistor))

all: svenska.aff svenska.hash

svenska.hash: svenska.aff svenska.datalista
	buildhash svenska.datalista svenska.aff svenska.hash

svenska.aff:
	cat affixfil/head.code affixfil/suffix.code > svenska.aff
	-[ -f affixfil/suffix2.code ] && cat affixfil/suffix2.code >> svenska.aff
	-[ -f affixfil/sammans.code ] && cat affixfil/sammans.code >> svenska.aff
	-[ -f affixfil/prefix.code ] && cat affixfil/prefix.code >> svenska.aff
	-[ -f affixfil/prefix2.code ] && cat affixfil/prefix2.code >> svenska.aff

.PHONY: all uppdatera_affix

konfigfil:
	ispell -vv | grep LIBDIR > konfigfil

uppdatera_affix: allord
	rm -f $(xjdatalistor) $(xndatalistor) svenska.aff diverse/gtmp.aff
	$(MAKE) svenska.aff	

diverse/gtmp.aff:
	sed 's/compoundwords.*/compoundwords off/' < affixfil/head.code > diverse/gtmp.aff
	cat affixfil/suffix.code affixfil/fakesammans.code >> diverse/gtmp.aff
	chmod a-w diverse/gtmp.aff


svenska.datalista: svenska.aff goranj.data gorann.data
	< goranj.data sed 's/\/.*//' | sed 's/$$/\/S/' > goranJ.data
	cat goran[jJ].data | sort -f | icombine svenska.aff > gorana.data
	cat gorana.data gorann.data | sort -f > svenska.datalista
	rm goran[aJ].data

goranj.data: diverse/gtmp.aff $(jsynclistor)
	cat $(xjdatalistor) $(xjordlistor) | munchlist -l diverse/gtmp.aff -v > goranj.data

gorann.data: diverse/gtmp.aff $(nsynclistor)
	cat $(xndatalistor) $(xnordlistor) | munchlist -l diverse/gtmp.aff -v > gorann.data

svenska.ordlista:  $(jsynclistor) $(nsynclistor) diverse/gtmp.hash
	export LC_ALL=sv_SE ; \
	cat $(ordlistor) | ispell -d diverse/gtmp -e | \
	sed s/\ /$$'\\\n'/g | grep -v zqx | \
	perl -e 'use locale; print sort <>' | uniq > svenska.ordlista

diverse/gtmp.hash: diverse/gtmp.aff diverse/dummy.ord
	buildhash diverse/dummy.ord diverse/gtmp.aff diverse/gtmp.hash

.PHONY: allsync alldata allord

allsync: $(jsynclistor) $(nsynclistor)

alldata: $(addsuffix .d, $(jlistor) $(nlistor) )

allord: $(addsuffix .o, $(jlistor) $(nlistor) )

.PHONY: clean realclean distclean install bindist

install: svenska.hash svenska.aff
	install -o root -g root -m 0644 svenska.hash $(DESTDIR)/$(LIBDIR)/svenska.hash
	install -o root -g root -m 0644 svenska.aff $(DESTDIR)/$(LIBDIR)/svenska.aff

clean:
	rm -f svenska.datalista.stat svenska.datalista.cnt diverse/dummy.ord.stat diverse/dummy.ord.cnt *~ */*~

realclean: clean
	rm -f svenska.aff svenska.hash svenska.datalista goranj.data gorann.data diverse/gtmp.hash $(VERSION).tar.gz svenska.ordlista build

distclean: realclean alldata
	rm -f $(jordlistor) $(jsynclistor) $(nordlistor) $(nsynclistor) konfigfil diverse/gtmp.aff

bindist: $(BINFILES)
	rm -fr $(VERSION) $(VERSION).tar.gz
	mkdir $(VERSION)
	ln $(BINFILES) $(VERSION)
	tar -zcf $(VERSION).tar.gz $(VERSION)
	rm -fr $(VERSION)

%.sync: %.data %.ord
	@[ "$?" != "$^" ] || (echo "Både $@ och $*.ord har ändrats - en av dem måste raderas. Stopp." ; exit 1 )
	[ "$?" == "$<" ] && $(MAKE) $*.d2o || $(MAKE) $*.o2d

%.sync: %.data
	touch $@

%.sync: %.ord
	touch $@

%.sync:
	@echo "Varken $*.ord eller $*.data existerar. Stopp."

%.o2d: %.ord diverse/gtmp.aff
	munchlist -l diverse/gtmp.aff -v $< > $*.data ; touch $*.sync

%.d2o: %.data diverse/gtmp.hash
	ispell -d diverse/gtmp -e < $< | sed s/\ /$$'\\\n'/g | sort -u > $*.ord ; touch $*.sync

%.o: %.ord
	-[ -f $*.data ] && [ ! -f $*.sync ] && ( echo "Filen $*.sync finns ej" ; exit 1 )
	-[ $*.data -nt $*.sync ] && $(MAKE) $*.sync

%.o: %.data
	$(MAKE) $*.d2o

%.d: %.data
	-[ -f $*.ord ] && [ ! -f $*.sync ] && ( echo "Filen $*.sync finns ej" ; exit 1 )
	-[ $*.ord -nt $*.sync ] && $(MAKE) $*.sync

%.d: %.ord
	$(MAKE) $*.o2d
