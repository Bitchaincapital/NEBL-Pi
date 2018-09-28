#!/bin/bash
#NEBL-Pi Installer v0.5.0 for Neblio Core v1.5.2

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
echo "Pass -x to disable QuickSync"
echo ""
echo "You can safely ignore all warnings during the compilation process, but if you"
echo "run into any errors, please report them to info@nebl.io"
echo "================================================================================"

USAGE="$0 [-d | -q | -c | -dqc]"

NEBLIODIR=~/neblpi-source
DEST_DIR=~/Desktop/
NEBLIOD=false
NEBLIOQT=false
COMPILE=false
JESSIE=false
QUICKSYNC=true

# check if we have a Desktop, if not, use home dir
if [ ! -d "$DEST_DIR" ]; then
    DEST_DIR=~/
fi

# check if we have ~/.neblio
if [ ! -d "~/.neblio" ]; then
    mkdir ~/.neblio
fi

# check if we are running on Raspbian Jessie
if grep -q jessie "/etc/os-release"; then
    echo "Jessie detected, following Jessie compile and install routine"
    JESSIE=true
    COMPILE=true
fi

while getopts ':dqcx' opt
do
    case $opt in
        c) echo "Will compile all from source"
           COMPILE=true;;
        d) echo "Will Install nebliod"
	       NEBLIOD=true;;
        q) echo "Will Install neblio-qt"
	       NEBLIOQT=true;;
        x) echo "Disabling Quick Sync and using traditional sync"
           QUICKSYNC=false;;
        \?) echo "ERROR: Invalid option: $USAGE"
        echo "-c            Compile all from source"
	    echo "-d            Install nebliod (default false)"
	    echo "-q            Install neblio-qt (default false)"
	    echo "-dq           Install both"
        echo "-x            Disable QuickSync"
            exit 1;;
    esac
done

# get sudo
if [ "$COMPILE" = true ]; then
    sudo whoami
fi

if [ "$QUICKSYNC" = true ]; then
    echo "Will use QuickSync"
fi

# update and install dependencies
if [ "$COMPILE" = true ]; then
    sudo apt-get update -y
    sudo apt-get install build-essential -y
    sudo apt-get install libboost-all-dev -y
    sudo apt-get install libdb++-dev -y
    sudo apt-get install libminiupnpc-dev -y
    sudo apt-get install libqrencode-dev -y
    sudo apt-get install libcurl4-openssl-dev -y
    if [ "$JESSIE" = true ]; then
        sudo apt-get install libssl-dev -y
    else
        sudo aptitude install libssl1.0-dev -y
    fi
    if [ "$NEBLIOQT" = true ]; then
        sudo apt-get install qt5-default -y
        sudo apt-get install qt5-qmake -y
        sudo apt-get install qtbase5-dev-tools -y
        sudo apt-get install qttools5-dev-tools -y
    fi
fi

if [ "$COMPILE" = true ]; then
    # delete our src folder and then remake it
    sudo rm -rf $NEBLIODIR
    mkdir $NEBLIODIR
    cd $NEBLIODIR

    # clone our repo, then create some necessary directories
    git clone -b v1.5.2-temp-branch https://github.com/NeblioTeam/neblio
    cd neblio/wallet
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
        make "STATIC=1" -B -w -f makefile.unix
        strip nebliod
        cp ./nebliod $DEST_DIR
    else
        cd $DEST_DIR
	wget https://github.com/NeblioTeam/neblio/releases/download/v1.5.2/NEBL-Pi-raspbian-nebliod---2018-09-19
        mv NEBL-Pi-raspbian-nebliod---2018-09-19 nebliod
        sudo chmod 775 nebliod
    fi
    if [ ! -f ~/.neblio/neblio.conf ]; then
        echo rpcuser=$USER >> ~/.neblio/neblio.conf
        RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        echo rpcpassword=$RPCPASSWORD >> ~/.neblio/neblio.conf
        echo rpcallowip=127.0.0.1 >> ~/.neblio/neblio.conf
    fi
fi
cd ..
if [ "$NEBLIOQT" = true ]; then
    if [ "$COMPILE" = true ]; then
        wget 'https://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.bz2'
        tar -xvf qrencode-3.4.4.tar.bz2 
        cd qrencode-3.4.4/
        ./configure --enable-static --disable-shared --without-tools --disable-dependency-tracking
        sudo make install
	cd ..
        qmake "USE_UPNP=1" "USE_QRCODE=1" "RELEASE=1" neblio-wallet.pro
        make -B -w
        cp ./wallet/neblio-qt $DEST_DIR
    else
        cd $DEST_DIR
        wget https://github.com/NeblioTeam/neblio/releases/download/v1.5.2/NEBL-Pi-raspbian-neblio-qt---2018-09-19
        mv NEBL-Pi-raspbian-neblio-qt---2018-09-19 neblio-qt
        sudo chmod 775 neblio-qt
    fi
fi

if [ "$QUICKSYNC" = true ]; then
    echo "Installing Docker for QuickSync"
    curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
	
    echo "Running the Neblio QuickSync container to copy the Neblio Blockchain"
    sudo docker pull neblioteam/neblio-quicksync-rpi
    sudo docker run -i --rm --name neblio-quicksync-rpi -v $HOME/.neblio:/root/.neblio neblioteam/neblio-quicksync-rpi
fi

if [ "$NEBLIOQT" = true ]; then
    if [ -d "~/Desktop" ]; then
        echo ""
        echo "Starting neblio-qt"
        sleep 5
        nohup $DEST_DIR/neblio-qt > /dev/null &
        sleep 5
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
read -rsn1 -p"Press any key to close this window";echo
