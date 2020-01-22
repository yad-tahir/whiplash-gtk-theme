#!/bin/bash

echo 'Run emerge to install required packages...'

sudo emerge --ask --verbose dev-ruby/sass media-gfx/inkscape media-gfx/optipng
