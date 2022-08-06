love2d_url = https://github.com/love2d/love/releases/download/11.4/love-11.4-x86_64.AppImage
love2d_bin = download/love2d.appimage

download: $(love2d_bin)

test: $(love2d_bin)
	$(love2d_bin) .

clean:
	rm -f $(love2d_bin)

$(love2d_bin):
	mkdir -p $(dir $@)
	wget $(love2d_url) -O $@
	chmod +x $@



.PHONY: test
