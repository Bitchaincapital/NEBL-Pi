#!/bin/bash
#NEBL-Pi Installer v0.1

echo "================================================================================"
echo "=================== Welcome to the Ofiicial NEBL-Pi Installer =================="
echo "This script will install all necessary dependencies to run or compile nebliod"
echo "and/or neblio-qt, download the binaries or source code, and then optionally"
echo "compile nebliod, neblio-qt or both. nebliod and/or neblio-qt will be copied to"
echo "your Desktop when done."
echo ""
echo "Note that even on a new Raspberry Pi 3, the compile process can take 30 minutes"
echo "or more for nebliod and over 45 minutes for neblio-qt."
echo ""
echo "Pass -c to compile from source"
echo "Pass -d to install nebliod"
echo "Pass -q to install neblio-qt"
echo "Pass -dq to install both"
echo ""
echo "You can safely ignore all warnings during the compilation process, but if you"
echo "run into any errors, please report them to info@nebl.io"
echo "================================================================================"

USAGE="$0 [-d | -q | -dq]"

NEBLIODIR=~/neblpi-source
DEST_DIR=~/Desktop/
NEBLIOD=false
NEBLIOQT=false
COMPILE=false

# check if we have a Desktop, if not, use home dir
if [ ! -d "$DEST_DIR" ]; then
    DEST_DIR=~/
fi

while getopts ':dqc' opt
do
    case $opt in
        c) echo "Will compile all from source"
           COMPILE=true;;
        d) echo "Will Install nebliod"
	       NEBLIOD=true;;
        q) echo "Will Install neblio-qt"
	       NEBLIOQT=true;;
        \?) echo "ERROR: Invalid option: $USAGE"
        echo "-c            Compile all from source"
	    echo "-d            Install nebliod (default false)"
	    echo "-q            Install neblio-qt (default false)"
	    echo "-dq           Install both"
            exit 1;;
    esac
done

# update and install dependencies
sudo apt-get update
sudo apt-get install build-essential -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install libdb++-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libqrencode-dev -y
if [ "$NEBLIOQT" = true ]; then
    sudo apt-get install qt5-default -y
    sudo apt-get install qt5-qmake -y
    sudo apt-get install qtbase5-dev-tools -y
    sudo apt-get install qttools5-dev-tools -y
fi
sudo aptitude install libssl1.0-dev -y
sudo apt-get install wget

if [ "$COMPILE" = true ]; then
    # delete our src folder and then remake it
    sudo rm -rf $NEBLIODIR
    mkdir $NEBLIODIR
    cd $NEBLIODIR

    # make sure git is installed and clone our repo, then create some necessary directories
    sudo apt-get install git
    git clone https://github.com/NeblioTeam/neblio
    cd neblio/src
    mkdir obj
    cd obj
    mkdir zerocoin
    cd ..
    cd leveldb
    chmod 755 *
    cd ..
fi

# start our build
if [ "$NEBLIOD" = true ]; then
    if [ "$COMPILE" = true ]; then
        make -B -w -f makefile.unix
        strip nebliod
        cp ./nebliod $DEST_DIR
    else
        cd $DEST_DIR
        wget https://github.com/NeblioTeam/neblio/releases/download/v1.2/NEBL-Pi-raspbian-nebliod---2017-11-21
        mv NEBL-Pi-raspbian-nebliod---2017-11-21 nebliod
        sudo chmod 775 nebliod
    fi
fi
cd ..
if [ "$NEBLIOQT" = true ]; then
    if [ "$COMPILE" = true ]; then
        qmake "USE_UPNP=1" "USE_QRCODE=1" neblio-qt.pro
        make -B -w
        cp ./neblio-qt $DEST_DIR
    else
        cd $DEST_DIR
        wget https://github.com/NeblioTeam/neblio/releases/download/v1.2/NEBL-Pi-raspbian-neblio-qt---2017-11-21
        mv NEBL-Pi-raspbian-neblio-qt---2017-11-21 neblio-qt
        sudo chmod 775 neblio-qt
    fi
fi
echo ""
echo "================================================================================"
echo "========================== NEBL-Pi Installer Finished =========================="
echo ""
echo "If there were no errors during download or compilation nebliod and/or neblio-qt"
echo "should now be on your desktop (if you are using a CLI-only version of Raspbian"
echo "without a desktop the binaries have been copied to your home directory instead)."
echo "Enjoy!"
echo ""
echo "================================================================================"
