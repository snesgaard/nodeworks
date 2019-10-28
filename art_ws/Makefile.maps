src=$(wildcard src/*.tmx)
lua=$(addprefix ./build/, $(notdir $(src:.tmx=.lua)))

all: create_build_dirs $(lua)

build/%.lua: src/%.tmx
	@tiled --export-map "lua" $< $@

create_build_dirs:
	@mkdir -p build

clean:
	@rm -rf build
