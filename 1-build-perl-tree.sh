#!/bin/sh
# A script to prepare a installation of Perl + FusionInventory Agent for
# Unix/Linux
# This in order to be able to provide an installation for system without
# Perl >= 5.8

set -e

ROOT="$PWD/.."
MAKE="make"
TMP="$PWD/tmp"
FILEDIR="$PWD/files"
PERL_PREFIX="$TMP/perl"
BUILDDIR="$TMP/build"
BASETARBALLSDIR="$PWD/base-tarballs"
MODULES="XML::NamespaceSupport Class::Inspector Digest::MD5 Net::IP File::ShareDir File::Copy::Recursive Net::IP Proc::Daemon Proc::PID::File Digest::MD5 File::Copy File::Path File::Temp Net::NBName Parallel::ForkManager XML::SAX XML::Simple UNIVERSAL::require"
FINALDIR=$PWD
NO_CLEANUP=0
OLD_PATH=$PATH
NO_PERL_REBUILD=0
INTERNAL_SSL=1

buildDmidecode () {
    cd $TMP
    gunzip < $FILEDIR/dmidecode-$DMIDECODE_VERSION.tar.gz | tar xvf -
    cd dmidecode-$DMIDECODE_VERSION
    $MAKE
    cp dmidecode $PERL_PREFIX/bin
    cd $TMP
}


installMod () {
    modName=$1
    distName=$2
    args=$3

    if [ -z "$distName" ]; then
        distName=`echo $modName|sed 's,::,-,g'`
    fi
    archive=`ls $FILEDIR/$distName*.tar.gz`
    if [ "`uname`" = "HP-UX" ]
    then
        $PERL_PREFIX/bin/perl $CPANM --skip-installed --notest $archive $args
    else
        $PERL_PREFIX/bin/perl $CPANM --skip-installed $archive $args
    fi
    $PERL_PREFIX/bin/perl -M$modName -e1
}

cleanUp () {
    rm -rf $BUILDDIR $TMP/openssl $TMP/perl $TMP/Compress::Zlib

}

buildPerl () {

    cd $TMP
    if [ ! -f $FILEDIR/perl-$PERLVERSION.tar.gz ]; then
    echo $FILEDIR/perl-$PERLVERSION.tar.gz
        echo "Please run ./download-perl-dependencies.sh first to retrieve the dependencies"
        exit
    fi

    cd $BUILDDIR
    gunzip < $FILEDIR/perl-$PERLVERSION.tar.gz | tar xvf -
    cd perl-$PERLVERSION
    
    # AIX
    #./Configure -Dusethreads -Dusenm -des -Dinstallprefix=$PERL_PREFIX -Dsiteprefix=$PERL_PREFIX -Dprefix=$PERL_PREFIX
    #./Configure -Dusethreads -Dcc="gcc" -des -Dinstallprefix=$PERL_PREFIX -Dsiteprefix=$PERL_PREFIX -Dprefix=$PERL_PREFIX

    if [ "`uname`" = "HP-UX" ]
    then
        set +o errexit
        rm -f pod/perldelta.pod
        ./Configure -Duserelocatableinc -Dusethreads -des -Dcc="gcc" -Dinstallprefix=$PERL_PREFIX -Dsiteprefix=$PERL_PREFIX -Dprefix=$PERL_PREFIX
	until $MAKE
	do
	    rm -f pod/perldelta.pod
	done
	rm -f pod/perldelta.pod
	set -o errexit
        $MAKE install
    else
        ./Configure -Duserelocatableinc -Dusethreads -des -Dcc="gcc" -Dinstallprefix=$PERL_PREFIX -Dsiteprefix=$PERL_PREFIX -Dprefix=$PERL_PREFIX
        $MAKE
        $MAKE install
    fi
    

}

buildOpenSSL () {

    cd $TMP
    if [ ! -f $FILEDIR/openssl-0.9.8n.tar.gz ]; then
        echo "Please run ./download-perl-dependencies.sh first to retrieve"
        echo "the dependencies"
        exit
    fi

    cd $BUILDDIR
    gunzip < $FILEDIR/openssl-0.9.8n.tar.gz | tar xvf -
    cd openssl-0.9.8n
    ./config no-shared --prefix=$TMP/openssl
    $MAKE depend
    $MAKE install
    # hack for Crypt::SSLeay
    mkdir $TMP/openssl/include/openssl/openssl
    cp $TMP/openssl/include/openssl/*.h $TMP/openssl/include/openssl/openssl

}
if [ ! -f '1-build-perl-tree.sh' ]; then
    echo "Please run the script in the root directory"
    exit 1
fi
if [ "`uname`" = "SunOS" ]; then
    if [ "`make -v|grep GNU`" = "" ]; then
        echo "make command must be GNU make on Solaris"
        echo "You can create a symlink to /usr/sfw/bin/gmake"
        exit
    fi
    if [ "`ar -V|grep GNU`" = "" ]; then
        echo "ar command should be GNU ar on Solaris"
        echo "You can create a symlink to /usr/sfw/bin/gar"
        exit
    fi
fi

PERLVERSION="5.12.1"

# Clean up
if [ "$NO_CLEANUP" = "0" ]; then
    cleanUp
fi

[ -d $TMP ] || mkdir $TMP
[ -d $BUILDDIR ] || mkdir $BUILDDIR
[ -d $BASETARBALLSDIR ] || mkdir $BASETARBALLSDIR

if [ ! -d $BUILDDIR ]; then
  echo "$BUILDDIR dir is missing"
fi



if [ "$NO_PERL_REBUILD" = "0" ]; then
    buildPerl
fi

[ -f "/etc/redhat-release" ] && INTERNAL_SSL=0
[ -f "/etc/centos-release" ] && INTERNAL_SSL=0
[ -f "/etc/apt/sources.list" ] && INTERNAL_SSL=0

if [ "$INTERNAL_SSL" = "1" ]; then
    buildOpenSSL
fi

cd $BUILDDIR
gunzip < $FILEDIR/Crypt-SSLeay-0.57.tar.gz | tar xvf -
cd Crypt-SSLeay-0.57
if [ "$INTERNAL_SSL" = "1" ]; then
  PERL_MM_USE_DEFAULT=1 $PERL_PREFIX/bin/perl Makefile.PL --default --static --lib=$TMP/openssl
else
  PERL_MM_USE_DEFAULT=1 $PERL_PREFIX/bin/perl Makefile.PL --default
fi
$MAKE install

cd $BUILDDIR
echo $PWD
archive=`ls $FILEDIR/App-cpanminus-*.tar.gz`
echo $archive
gunzip < $archive | tar xvf -
CPANM=$BUILDDIR/App-cpanminus-1.0004/bin/cpanm

if [ "`uname`" = "HP-UX" ]
then
    echo "HP-UX tar cannot handle *.tar.gz files."
    echo "Creating our own version of tar as $BUILDDIR/tar"
    ORIG_TAR=`which tar`
    cat <<EOT >$BUILDDIR/tar
#!/usr/dt/bin/dtksh

if [[ -n "\$1" && -n "\$2" && "\$1" == *z* && ( "\$1" == *x* || "\$1" == *t* ) ]]
then
  tmpARGS=\${1//z/}
  gzip -dc \$2 | $ORIG_TAR \$tmpARGS -
else
  $ORIG_TAR "\$@"
fi
EOT
    chmod 700 $BUILDDIR/tar
    export PATH=$BUILDDIR:$PATH
fi

if [ -f "/usr/include/cups/cups.h" ]; then
   INSTALL_CUPS=1
   if [ "`uname`" = "Darwin" ]; then 
      CUPS_VERSION=`cups-config --version`
      echo "Found cups $CUPS_VERSION"
      TARGET_VERSION=1.2.0

read c_major c_minor c_rev << EOF
`echo ${CUPS_VERSION} | tr "." " "`
EOF

read n_major n_minor n_rev << EOF
`echo ${TARGET_VERSION} | tr "." " "`
EOF

     if [ $c_major -le $n_major ] && [ $c_minor -le $n_minor ]; then
         echo "Cannot install Net::CUPS because CUPS version is too old on Mac OS X < 10.5 !"
         INSTALL_CUPS=0
      fi
   fi 

   if [ "$INSTALL_CUPS" = "1" ]; then
      echo "Install Net::CUPS"
      installMod "Net::CUPS"
   fi
fi

installMod "URI"
installMod "HTML::Tagset"
installMod "HTML::Parser"
installMod "LWP" "libwww-perl"
installMod "Compress::Raw::Zlib"
installMod "Compress::Raw::Bzip2"
installMod "Compress::Zlib" "IO-Compress"

# Tree dependencies not pulled by cpanm
for modName in $MODULES; do
    installMod $modName
done

#Restoring PATH
PATH=$OLD_PATH

cd $TMP
TARBALLNAME=` $PERL_PREFIX/bin/perl -MConfig -e'print $Config{osname}."_".$Config{archname}."_".$Config{osvers}.".tar"'`
tar cf $FINALDIR/$TARBALLNAME perl

mv $FINALDIR/$TARBALLNAME $BASETARBALLSDIR
