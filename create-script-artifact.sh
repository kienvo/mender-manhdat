#!/usr/bin/env bash

./mender-artifact write module-image 	\
-T		script -t raspberrypi4			\
-n		script-test1 					\
-f		./example.py 					\
-o		script-test.mender
