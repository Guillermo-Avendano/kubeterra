#!/bin/bash
#Execute the script in following way -  bash ./prepare_scripts.sh $USER
set -Eeuo pipefail
sudo apt-get -y update
sudo apt-get -y upgrade
#install dos2unix
sudo apt-get install dos2unix
parent_directory=`echo $(cd .. && pwd)`
current_directory=`echo $(pwd)`
current_user=$1
#set permission
cd $parent_directory
sudo chown -R "$current_user:$current_user" ${current_directory}
sudo chmod -R 777 ${current_directory}
cd $current_directory
#execute dos2unix
find . -name "*.yaml" -exec dos2unix {} \;
find . -name "*.sh" -exec dos2unix {} \;
dos2unix .env