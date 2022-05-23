#!/usr/bin/env bash

./mender-artifact write module-image 	\
-T		single-file 					\
-t		raspberrypi4 					\
-n		singlefile-blink4					\
-f 		./example.py					\
-s 		./ArtifactInstall_Leave_01_User_Confirmation-abc.sh \
-s 		./ArtifactInstall_Enter_01_User_Confirmation-abc.sh \
-f 		dest_dir						\
-f		filename 						\
-o		singlefile.mender