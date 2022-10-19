include konfigfil

all: svenska.hash

konfigfil:
	ispell -vv | grep LIBDIR > konfigfil

install: svenska.hash svenska.aff
	install -o root -g root -m 0644 svenska.hash $(LIBDIR)
	install -o root -g root -m 0644 svenska.aff $(LIBDIR)

svenska.hash: svenska.aff svenska.datalista
	buildhash svenska.datalista svenska.aff svenska.hash

clean:
	rm -f konfigfil svenska.datalista.stat svenska.hash svenska.datalista.cnt *~

