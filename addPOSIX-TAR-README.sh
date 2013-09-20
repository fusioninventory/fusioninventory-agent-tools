#!/bin/bash

find prebuilt/ -type d -name *hpux* -exec cp $PWD/README-tar.html {}/README.html \;
find prebuilt/ -type d -name *aix* -exec cp $PWD/README-tar.html {}/README.html \;
find prebuilt/ -type d -name *solaris* -exec cp $PWD/README-tar.html {}/README.html \;
