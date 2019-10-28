#!/bin/bash

path=$1

if [ -z "$path" ]
  then
    echo "No arguments supplied"
fi

src_dir=$(dirname $0)
src_make_map=$src_dir/Makefile.maps
dst_make_map=$path/maps/Makefile

src_make_char=$src_dir/Makefile.sprite
dst_make_char=$path/characters/Makefile

src_make_tile=$src_dir/Makefile.tiles
dst_make_tile=$path/tiles/Makefile

src_make_master=$src_dir/Makefile.master
dst_make_master=$path/Makefile

mkdir -p $(dirname $dst_make_char)
mkdir -p $(dirname $dst_make_tile)
mkdir -p $(dirname $dst_make_map)

ln -sr $src_make_map $dst_make_map
ln -sr $src_make_tile $dst_make_tile
ln -sr $src_make_char $dst_make_char
ln -sr $src_make_master $dst_make_master

ln -sr $src_dir/texatlas.py $path/texatlas.py
ln -sr $src_dir/im_stack.py $path/im_stack.py

mkdir -p $path/characters/sprites
mkdir -p $path/maps/src
mkdir -p $path/maps/tileset
mkdir -p $path/tiles/sprites
