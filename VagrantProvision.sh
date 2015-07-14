#!/bin/bash

if [ -e /vagrant ]; then VHOME="/home/vagrant"; else VHOME=$HOME; fi
if [ ! -e $VHOME/.osis-converters ]; then mkdir $VHOME/.osis-converters; fi
if [ ! -e $VHOME/.osis-converters/src ]; then mkdir $VHOME/.osis-converters/src; fi

sudo apt-get update

sudo apt-get install -y libtool
sudo apt-get install -y autoconf
sudo apt-get install -y make
sudo apt-get install -y pkg-config
sudo apt-get install -y build-essential
sudo apt-get install -y libicu-dev
sudo apt-get install -y unzip
sudo apt-get install -y cpanminus
sudo apt-get install -y subversion
sudo apt-get install -y git
sudo apt-get install -y zip
sudo apt-get install -y swig

sudo apt-get install -y default-jre
sudo apt-get install -y libsaxonb-java
sudo apt-get install -y libxml2-dev
sudo apt-get install -y libxml2-utils
sudo apt-get install -y liblzma-dev

# XML::LibXML
sudo cpanm XML::LibXML
sudo cpanm HTML::Entities

# Calibre
if [ ! `which calibre` ]; then
  sudo apt-get install xdg-utils imagemagick python-imaging python-mechanize python-lxml python-dateutil python-cssutils python-beautifulsoup python-dnspython python-poppler libpodofo-utils libwmf-bin python-chm
  wget -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"
  calibre-customize –b /vagrant/eBooks/OSIS-Input
fi

# GoBible Creator
if [ ! -e  $VHOME/.osis-converters/GoBibleCreator.245 ]; then
  cd $VHOME/.osis-converters
  wget https://gobible.googlecode.com/files/GoBibleCreator.245.zip
  unzip GoBibleCreator.245.zip
  rm GoBibleCreator.245.zip
fi

# Repotemplate
if [ ! -e $VHOME/.osis-converters/src/repotemplate ]; then
  cd $VHOME/.osis-converters/src
  if [ ! -e ~/.ssh ]; then mkdir ~/.ssh; fi
  ssh-keyscan crosswire.org >> ~/.ssh/known_hosts
  # currently even repotemplate read requires ssh credentials, so this 
  # may not work unless the host machine's ssh agent is configured to
  # access repotemplate. If this fails, you can obtain repotemplate/bin
  # somehow and place it in a directory in the host, then add to paths.pl:
  # $REPOTEMPLATE_BIN = "host-path/to/repotemplate/bin";
  if [ -e /vagrant ]; then
    # this sudo is needed for the Vagrantfile ssh.forward_agent work-around to work
    sudo git clone -b ja_devel gitosis@crosswire.org:repotemplate
  else
    git clone -b ja_devel gitosis@crosswire.org:repotemplate
  fi
else
  cd $VHOME/.osis-converters/src/repotemplate
  git checkout ja_devel
  git pull
fi

# SWORD Tools
# CLucene
if [ ! `which osis2mod` ]; then
  if [ ! -e $VHOME/.osis-converters/src/clucene-core-0.9.21b ]; then
    cd $VHOME/.osis-converters/src
    wget http://sourceforge.net/projects/clucene/files/clucene-core-stable/0.9.21b/clucene-core-0.9.21b.tar.bz2/download
    tar -xf download 
    rm download
    cd clucene-core-0.9.21b
    ./configure --disable-multithreading
    sudo make install
    sudo ldconfig
  fi

  # SWORD engine
  swordRev=3375
  if [ ! -e $VHOME/.osis-converters/src/sword-svn ]; then
    cd $VHOME/.osis-converters/src
    svn checkout -r $swordRev http://crosswire.org/svn/sword/trunk sword-svn
    cd sword-svn
    # modify Makefile to compile and install emptyvss
    sed -i -r -e "s|stepdump step2vpl gbfidx modwrite addvs emptyvss|stepdump step2vpl gbfidx modwrite addvs|" ./utilities/Makefile.am
    sed -i -r -e "s|^bin_PROGRAMS = |bin_PROGRAMS = emptyvss |" ./utilities/Makefile.am
    ./autogen.sh
    ./configure
    sudo make install
    
    # Perl bindings
    cd $VHOME/.osis-converters/src/sword-svn/bindings/swig/package
    libtoolize --force
    ./autogen.sh
    ./configure
    make perlswig
    make perl_make
    cd perl
    sudo make install
    sudo ldconfig
  fi
fi