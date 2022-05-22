#!/usr/bin/env bash

./mender-artifact write module-image 	\
-T		single-file 					\
-t		raspberrypi4 					\
-n		singlefile-test7 					\
-f 		./example.py					\
-s 		./ArtifactInstall_Leave_01_User_Confirmation-abc.sh \
-f 		dest_dir						\
-f		filename 						\
-o		singlefile.mender