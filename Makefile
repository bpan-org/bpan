DOC = doc/test-tap.md
MAN1 = man/man1/bpan.1

all:

clean:
	rm -fr build index

doc: $(MAN1)

man/man1/%.1: doc/%.md
	ronn --roff < $< > $@
