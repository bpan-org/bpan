site: index.html

open: index.html
	chromium-browser $<

clean:
	rm -fr body.html index.html

index.html: head.html body.html foot.html
	cat $+ > $@
	rm -f body.html

%.html: %.md
	showdown makehtml -i $< -o $@
	@#showdown makehtml --disableForced4SpacesIndentedSublists -i $< -o $@
