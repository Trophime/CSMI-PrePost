#!/bin/bash

#set -x

usage(){
   echo ""
   echo "Description:"
   echo "                Build and Install web docs"
   echo ""
   echo "Usage:"
   echo "                startweb.sh [ <option> ] ... ]"
   echo ""
   echo "Options:"
   echo "-s <srcdir>     Specify the source directory (if VScode detected set by default)."
   echo "-d              Enable debug"
   echo ""
   echo "-h              Prints this help information"
   echo ""
   exit 1
}

#########################################################
## parse parameters
##########################################################
while getopts "hs:d" option ; do
   case $option in
       h ) usage ;;
       s ) SRCDIR=$OPTARG ;;
       d ) DEBUG=1 ;;
       ? ) usage ;;
   esac
done
# shift to have the good number of other args
shift $((OPTIND - 1))


: ${DEBUG:=0}

if [ "${TERM_PROGRAM}" = "vscode" ]; then
   echo "**** VScode detected: overwrite main directories definition ****"
   SRCDIR=/workspaces/CSMI-PrePosts
fi

# check if SRCDIR  exists
if [ -z ${SRCDIR} ]; then
   echo "SRCDIR is undefined"
   exit 1
fi

if [ ! -d ${SRCDIR} ]; then
   echo "SRCDIR=${SRCDIR} is not defined"
   exit 1
fi

sudo apt install python-is-python3 python3-venv

# install npm and antora
cd ~
curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh
sudo bash /tmp/nodesource_setup.sh
sudo apt install nodejs
node -v


sudo npm install

# Install Python dependencies
python -m venv --system-site-packages .venv
source .venv/bin/activate
pip install -r requirements.txt

# install live-server
sudo npm i -g live-server

# do it in docs
cd ${SRCDIR}/docs
npx antora --stacktrace generate --cache-dir cache --redirect-facility disabled --clean site-dev.yml > ../Antora.log 2>&1

# get VERSION from main mqs CMakeLists.txt
VERSION="0.1.0"
echo "************************************************************"
echo "Starting WEB server on port 8080"

npm list -g live-server > /dev/null
IsInstalled=$?
if [ ! $IsInstalled ]; then
   sudo npm i -g live-server
fi

if [ "${TERM_PROGRAM}" = "vscode" ]; then 
   echo "To access the docs:"
   echo "Tape F1 and Forward port 8080"
fi
nohup live-server --wait=1000 ./public > output.log &
   
# get PID
WEBPID=$(pgrep /usr/local/bin/live-server)
   
echo "To view the docs; run Firefox in private mode and load localhost:8080/mqs/${VERSION}"
echo "If you make change to the docs, do not forget to rerun:"
echo "antora --stacktrace generate --cache-dir cache --redirect-facility disabled --clean site-dev.yml > ../Antora.log 2>&1"
echo "Check ../Antora.log for ERRORS and WARNINGS"
echo "To stop the server: kill $WEBPID"
echo "************************************************************"

