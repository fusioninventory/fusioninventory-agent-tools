#!/bin/sh

#Goes into the agent directory
cd /opt/fusioninventory-agent

#Runs the agent as root (using sudo)
sudo ./fusioninventory-agent $@
