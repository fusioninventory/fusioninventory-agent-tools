#!/bin/bash
# Requirement:
# Git 1.5
# Bash

ROOTDIR="$PWD"
#MODULES="deploy:2.0.4 network:1.0.2 esx:2.2.1"
MODULES=""
GITBASEDIR="git://github.com/fusinv"
BASETARBALLSDIR="$PWD/base-tarballs"
PATCHESDIR="$PWD/agent-lib-bundle/lib"
PREBUILTDIR="$PWD/prebuilt"
TMP="$PWD/tmp"
MACOSXBASE="$PWD/osx/FusionInventory-Agent.pkg.tar.gz"
WINDOWSBASE="$PWD/windows"
FILESDIR="$PWD/files"

#PERL_VERSION="5.12.1"
# The last stable release
AGENT_VERSION="2.2.7"
AGENT_VERSION_PACKAGE="4"
FLAVOR="devel/obs-2.2.x"
#FLAVOR="stable"
#set -e

if [ -z $TMP ]; then
    echo Please set correct value for TMP
fi

if [ ! -d $PATCHESDIR ]; then
    git clone git+ssh://forge.fusioninventory.org/git/fusioninventory/agent-lib-bundle.git
fi

gitCheckout () {
	ref=$1

        git fetch
	git checkout master
	git branch -D work
	git checkout -b work $ref
	git reset --hard
        git clean -fdx

}

installBase () {
	tarball=`basename $1`
        perllibdir=$2
	flavor=$3
	echo $tarball

	[ -d $TMP/fusioninventory-agent ] && rm -Rf $TMP/fusioninventory-agent
	[ -d $TMP/perl ] && rm -Rf $TMP/perl
	
	[ -d $TMP ] || mkdir $TMP

	mkdir $TMP/fusioninventory-agent
	
	cd $TMP
	echo tar xf $BASETARBALLSDIR/$tarball
	tar xf $BASETARBALLSDIR/$tarball
	
	mv $TMP/perl $TMP/fusioninventory-agent
	
	# Purge some files we don't need
	chmod -fR u+w *
	find . -name '*.pod' -exec rm {} \;
	rm -Rf $TMP/fusioninventory-agent/perl/man
	mv $TMP/fusioninventory-agent/perl/bin $TMP/fusioninventory-agent/perl/bin.tmp
	mkdir $TMP/fusioninventory-agent/perl/bin
	
        if [ ! "`echo $tarball | grep windows`"  = "" ]; then
            mv $TMP/fusioninventory-agent/perl/bin.tmp/perl.exe $TMP/fusioninventory-agent/perl/bin
            mv $TMP/fusioninventory-agent/perl/bin.tmp/*.dll $TMP/fusioninventory-agent/perl/bin
            cp $WINDOWSBASE/dmidecode.exe $TMP/fusioninventory-agent/perl/bin
            cp $WINDOWSBASE/hdparm.exe $TMP/fusioninventory-agent/perl/bin
        else
            mv $TMP/fusioninventory-agent/perl/bin.tmp/perl $TMP/fusioninventory-agent/perl/bin
        	# Install the agent
            if [ -f $TMP/fusioninventory-agent/perl/bin.tmp/dmidecode ]; then
               mv $TMP/fusioninventory-agent/perl/bin.tmp/dmidecode  $TMP/fusioninventory-agent/perl/bin
            fi
	    cat >> $TMP/fusioninventory-agent/fusioninventory-agent << EOF
#!/bin/sh
# Try to detect lib directory with the XS files
# since we build with thread support, this should be, err
# hum, well "safe".
MYPWD=\`dirname \$0\`

# Get an absolute path if needed
[ "\$MYPWD" = "." ] && MYPWD=\`pwd\`

if [ ! -f "\$MYPWD/perl/agent/FusionInventory/Agent/Task/Inventory/Input/Virtualization/VmWareDesktop.pm" ]; then
  echo "Your installation is not complete. It's very likely you used a non GNU tar to"
  echo "extract the agent distribution."
  echo "POSIX tar are not able to extract tarball with path length > 100 characters."
  echo ""
  echo " -- PLEASE use GNU tar! --"
  exit 1
fi



XSDIR=\`ls -d \$MYPWD/perl/lib/5.12.1/*-thread-*\`
XSDIR=\$XSDIR:\`ls -d \$MYPWD/perl/lib/site_perl/5.12.1/*-thread-*\`

# For memconf
PATH=\$MYPWD/perl/bin:\$PATH
PERL5LIB="\$MYPWD/perl/agent:\$MYPWD/perl/lib/5.12.1:\$MYPWD/perl/lib/site_perl/5.12.1:\$XSDIR"

# should use unset instead
PERLLIB=""

export PATH
export PERL5LIB
export PERLLIB

echo \$MYPWD
cd \$MYPWD
exec \$MYPWD/perl/bin/perl -e "

@INC = split(/:/,\\\$ENV{PERL5LIB});
require \"\$MYPWD/perl/bin/fusioninventory-agent\";


" -- --conf-file=./agent.cfg \$*
EOF
	    cat >> $TMP/fusioninventory-agent/fusioninventory-injector << EOF
#!/bin/sh
# Try to detect lib directory with the XS files
# since we build with thread support, this should be, err
# hum, well "safe".
MYPWD=\`dirname \$0\`

# Get an absolute path if needed
[ "\$MYPWD" = "." ] && MYPWD=\`pwd\`

if [ ! -f "\$MYPWD/perl/agent/FusionInventory/Agent/Task/Inventory/Input/Virtualization/VmWareDesktop.pm" ]; then
  echo "Your installation is not complete. It's very likely you used a non GNU tar to"
  echo "extract the agent distribution."
  echo "POSIX tar are not able to extract tarball with path length > 100 characters."
  echo ""
  echo " -- PLEASE use GNU tar! --"
  exit 1
fi



XSDIR=\`ls -d \$MYPWD/perl/lib/5.12.1/*-thread-*\`
XSDIR=\$XSDIR:\`ls -d \$MYPWD/perl/lib/site_perl/5.12.1/*-thread-*\`

# For memconf
PATH=\$MYPWD/perl/bin:\$PATH
PERL5LIB="\$MYPWD/perl/agent:\$MYPWD/perl/lib/5.12.1:\$MYPWD/perl/lib/site_perl/5.12.1:\$XSDIR"

# should use unset instead
PERLLIB=""

export PATH
export PERL5LIB
export PERLLIB

cd \$MYPWD
exec \$MYPWD/perl/bin/perl \$MYPWD/perl/bin/fusioninventory-injector \$*
EOF




	    cat >> $TMP/fusioninventory-agent/fusioninventory-esx << EOF
#!/bin/sh
# Try to detect lib directory with the XS files
# since we build with thread support, this should be, err
# hum, well "safe".
MYPWD=\`dirname \$0\`

# Get an absolute path if needed
[ "\$MYPWD" = "." ] && MYPWD=\`pwd\`

if [ ! -f "\$MYPWD/perl/agent/FusionInventory/Agent/Task/Inventory/Input/Virtualization/VmWareDesktop.pm" ]; then
  echo "Your installation is not complete. It's very likely you used a non GNU tar to"
  echo "extract the agent distribution."
  echo "POSIX tar are not able to extract tarball with path length > 100 characters."
  echo ""
  echo " -- PLEASE use GNU tar! --"
  exit 1
fi


XSDIR=\`ls -d \$MYPWD/perl/lib/5.12.1/*-thread-*\`
XSDIR=\$XSDIR:\`ls -d \$MYPWD/perl/lib/site_perl/5.12.1/*-thread-*\`

# For memconf
PATH=\$MYPWD/perl/bin:\$PATH
PERL5LIB="\$MYPWD/perl/agent:\$MYPWD/perl/lib/5.12.1:\$MYPWD/perl/lib/site_perl/5.12.1:\$XSDIR"

# should use unset instead
PERLLIB=""

export PATH
export PERL5LIB
export PERLLIB

echo \$MYPWD
cd \$MYPWD
exec \$MYPWD/perl/bin/perl -e "

@INC = split(/:/,\\\$ENV{PERL5LIB});
require \"\$MYPWD/perl/bin/fusioninventory-esx\";


" -- \$*
EOF

	    chmod +x $TMP/fusioninventory-agent/fusioninventory-agent
	    chmod +x $TMP/fusioninventory-agent/fusioninventory-injector
	    chmod +x $TMP/fusioninventory-agent/fusioninventory-esx

	    cp $ROOTDIR/fusioninventory-injector $TMP/fusioninventory-agent/perl/bin
        fi
	rm -Rf $TMP/fusioninventory-agent/perl/bin.tmp
        cp -Rf $PATCHESDIR/* $perllibdir

	if [ "$flavor" = "devel/2.1.x+new_mods" ]; then
		echo "flavor: devel/2.1.x+new_mods"
	        if [ ! "`echo $tarball | grep windows`"  = "" ]; then
			cp $ROOTDIR/fusinvform/* $TMP/fusioninventory-agent/perl/bin
		fi
	fi
}
installModulesFromGit () {
	flavor=$1
        perllibdir=$2

	[ ! -d $TMP/git ] && mkdir $TMP/git

        for tmp in $MODULES; do
		module=`echo $tmp|sed s,:.*,,`
		version=`echo $tmp|sed s,.*:,,`
                echo "$module / $version"
		if [ ! -d $TMP/git/$module ]; then
	            git clone $GITBASEDIR/fusioninventory-agent-task-$module.git $TMP/git/$module
		fi

        echo $TMP/git/$module
	currentDir=$PWD
        cd $TMP/git/$module

        pwd

	if [ "$flavor" = "stable" ]; then
		gitCheckout $version
	else
               gitCheckout master
	    fi

        cp -R $TMP/git/$module/lib/* $perllibdir/
        echo "$TMP/git/$module/fusioninventory-*"
	cp -v $TMP/git/$module/fusioninventory-* $TMP/fusioninventory-agent/perl/bin
        gitCheckout master
        cd $currentDir

        done


}

installAgentFromGit () {
    flavor=$1
    perllibdir=$2
    finalversion=$3

    if [ ! -d $TMP/git/agent ]; then
        mkdir $TMP/git

	git clone $GITBASEDIR/fusioninventory-agent.git $TMP/git/agent
    fi


    currentDir=$PWD
    cd $TMP/git/agent

    pwd
    if [ "$flavor" = "stable" ]; then
         gitCheckout $AGENT_VERSION
    else
         gitCheckout origin/`echo $flavor | sed 's,devel/,,'`
    fi
    [ -f tools/refresh-doc.sh ] && sh tools/refresh-doc.sh
    cd $currentDir

    cp -v $TMP/git/agent/README* $TMP/fusioninventory-agent
    cp $TMP/git/agent/etc/agent.cfg $TMP/fusioninventory-agent

    cp $TMP/git/agent/fusioninventory-agent $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent
    cp $TMP/git/agent/fusioninventory-win32-service $TMP/fusioninventory-agent/perl/bin
    cp $TMP/git/agent/memconf $TMP/fusioninventory-agent/perl/bin
    chmod +x $TMP/fusioninventory-agent/perl/bin/memconf
    cp -R $TMP/git/agent/share $TMP/fusioninventory-agent
    curl http://pciids.sourceforge.net/v2.2/pci.ids.bz2 | bunzip2 > $TMP/fusioninventory-agent/share/pci.ids
    cp -R $TMP/git/agent/lib/FusionInventory $perllibdir

    sed -i "s,\(VERSION *= *'\).*',\1$finalversion'," $perllibdir/FusionInventory/Agent.pm
#    patch  $perllibdir/FusionInventory/Agent.pm < /srv/fusioninventory/agent-tools/0001-preserve-the-current-location-in-daemon-mode.patch
#    if [ "$flavor" = "stable" ]; then
#      patch  $perllibdir/FusionInventory/Agent/Task/Inventory/Input/Win32/Networks.pm < /srv/fusioninventory/agent-tools/0001-fix-the-network-inventory-on-Windows.patch
#      patch  $perllibdir/FusionInventory/Agent/Tools/Win32.pm < /srv/fusioninventory/agent-tools/0001-fix-force-UTF-8-encoding-on-WMI-output.patch
#    fi
}


processTarball () {
	flavor=$1
	tarball=$2
	date=`date +%Y%m%d-%H%M`
	os=`basename $tarball|sed 's,.tar$,,'`

#        if [ -L $tarball ]; then
#            dest=`readlink $tarball|sed 's,.tar$,,'`
#            ln -sf $dest $PREBUILTDIR/$flavor/$os
#            continue
#        fi
	
	if [ "$flavor" = "stable" ]; then
		finalversion="$AGENT_VERSION-$AGENT_VERSION_PACKAGE"
        else
		finalversion="$AGENT_VERSION+`echo $flavor| sed 's,devel/,dev-,'`-$date"
	fi
	finalname=fusioninventory-agent_${os}_${finalversion}

        echo $PREBUILTDIR/$flavor/$os/.$finalname.done
            echo "Processing $finalname"
        if [ ! -f $PREBUILTDIR/$flavor/$os/.$finalname.done ]; then
            echo "Processing $finalname"

            if [ ! "`echo $tarball | grep windows`"  = "" ]; then
                perllibdir="$TMP/fusioninventory-agent/perl/lib/"
            else
                perllibdir="$TMP/fusioninventory-agent/perl/lib/site_perl/5.12.*/"
            fi

            # Copy the agent files
	    installBase $tarball $perllibdir $flavor
	    mkdir -p $TMP/fusioninventory-agent/perl/agent
	    installAgentFromGit $flavor $TMP/fusioninventory-agent/perl/agent $finalversion
	    installModulesFromGit $flavor $TMP/fusioninventory-agent/perl/agent

            [ -d $TMP/$finalname ] && rm -Rf $TMP/$finalname
            [ -d $PREBUILTDIR/$flavor/$os.tmp ] && rm -Rf $PREBUILTDIR/$flavor/$os.tmp

            echo $finalname
            cd $TMP

            sed -i 's,daemon=.*,daemon=0,' $TMP/fusioninventory-agent/agent.cfg
            sed -i 's,daemon-no-fork=.*,daemon-no-fork=0,' $TMP/fusioninventory-agent/agent.cfg
            sed -i 's,logfile=.*,logfile=agent.log,' $TMP/fusioninventory-agent/agent.cfg
            sed -i 's,logfile-maxsize=.*,logfile-maxsize=5,' $TMP/fusioninventory-agent/agent.cfg
            sed -i 's,#* share-dir=./share,share-dir=./share,' $TMP/fusioninventory-agent/agent.cfg
            sed -i 's,#* basevardir=./var,basevardir=./var,' $TMP/fusioninventory-agent/agent.cfg

            if [ ! "`echo $os|grep windows`" = "" ]; then
		sed -i "s,use lib '../lib';,use lib '../lib'; use lib '../agent';," $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent
                sed -i 's,./etc,../../etc,' $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent
                sed -i 's,./var,../../var,' $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent
                sed -i 's,./share,../../share,' $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent
                sed -i 's,./lib,../agent,' $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent
                sed -i 's,/../../lib,/../agent,' $TMP/fusioninventory-agent/perl/bin/fusioninventory-win32-service

#Ensure we are in the correct directory
                cat > $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent.tmp << EOF
BEGIN {
    use File::Spec;
    use File::Basename;
    
    my \$directory = dirname(File::Spec->rel2abs( __FILE__ ));
    # on Win2k, Windows do not chdir to the bin directory
    # we need to do it by ourself
    chdir(\$directory);
}
EOF
                cat $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent >> $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent.tmp
                mv $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent.tmp $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent

            else
                sed -i 's,./lib,./perl/agent,' $TMP/fusioninventory-agent/perl/bin/fusioninventory-agent
            fi
            mv $TMP/fusioninventory-agent $finalname

            [ -d $PREBUILTDIR/$flavor/$os.tmp ] && rm -Rf $PREBUILTDIR/$flavor/$os.tmp
            mkdir -p $PREBUILTDIR/$flavor/$os.tmp

            if [ ! "`echo $os|grep windows`" = "" ]; then
                    mkWinInstaller $TMP/$finalname $PREBUILTDIR/$flavor/$os.tmp/$finalname.exe $PREBUILTDIR/$flavor/$os.tmp/$finalname-nsis-files.tar.gz $PREBUILTDIR/$flavor/$os.tmp/$finalname-nsis-files.zip $finalversion
                    echo "<h2>The $finalname-nsis-files.tar.gz is only useful if you want to generate a new installer yourself with NSIS.<h2>" > $PREBUILTDIR/$flavor/$os.tmp/README.html
            else
                mkTarball $TMP/$finalname $PREBUILTDIR/$flavor/$os.tmp/$finalname.tar.gz
                mkZip $TMP/$finalname $PREBUILTDIR/$flavor/$os.tmp/$finalname.zip
                if [ ! "`echo $os|grep macosx`" = "" ]; then
                    mkMacOSXPkg $TMP/$finalname $PREBUILTDIR/$flavor/$os.tmp/$finalname.pkg.tar.gz $finalname
                fi
            fi

            if [ ! "`echo $flavor|grep devel`" = "" ]; then
                [ -d $PREBUILTDIR/$flavor/$os ] && rm -Rf $PREBUILTDIR/$flavor/$os
            fi
            [ ! -d $PREBUILTDIR/$flavor/$os ] && mkdir $PREBUILTDIR/$flavor/$os
            mv $PREBUILTDIR/$flavor/$os.tmp/* $PREBUILTDIR/$flavor/$os
            rm -Rf $PREBUILTDIR/$flavor/$os.tmp
            rm -Rf $TMP/$finalname
            touch "$PREBUILTDIR/$flavor/$os/.$finalname.done"
        fi
}

mkTarball () {
    dir=$1
    file=$2

    cd $TMP
    tar czf tarball.tar.gz `basename $dir`
    mv $TMP/tarball.tar.gz $file
}

mkZip () {
    dir=$1
    file=$2

    cd $TMP
    zip -qr tmp.zip `basename $dir`
    mv $TMP/tmp.zip $file
}



mkMacOSXPkg () {
    dir=$1
    file=$2
    agentfilename=$3

    tmpMacOSX=$TMP/macosx
    rm -Rf $tmpMacOSX
    mkdir -p $tmpMacOSX

    oldDir=$PWD
    cd $tmpMacOSX
    #Create the opt/ directory
    mkdir opt
    #Untar FusionInventory application
    tar xzf $MACOSXBASE 
    #Rename agent's directory
    echo dir : $dir
    cp -R $dir opt/fusioninventory-agent
    #Create an archive in the format used by Mac OS X
    pax -w -x cpio -f Archive.pax opt
    gzip Archive.pax
    #Copy pax.gz file into the pkg
    tar xzf $MACOSXBASE
    cp -Rf Archive.pax.gz FusionInventory-Agent.pkg/Contents/
    #Copy needed extra files in the pkg
    cp -Rf ../../osx/resources/* FusionInventory-Agent.pkg/Contents/Resources/
    
    #Copy agent configuration file into the pkg 
    cp $TMP/$agentfilename/agent.cfg FusionInventory-Agent.pkg/Contents/Resources/
    
    sed -i 's,daemon=0,daemon=1,' FusionInventory-Agent.pkg/Contents/Resources/agent.cfg
    sed -i 's,rpc-trust-localhost=0,rpc-trust-localhost=1,' FusionInventory-Agent.pkg/Contents/Resources/agent.cfg
    sed -i 's,wait=,wait=30,' FusionInventory-Agent.pkg/Contents/Resources/agent.cfg
    sed -i 's,agent.log,/var/log/fusioninventory-agent.log,' FusionInventory-Agent.pkg/Contents/Resources/agent.cfg
    #Remove opt directory, not needed anymore 
    rm -Rf opt
    tar czf tmp.tar.gz FusionInventory-Agent.pkg
    mv tmp.tar.gz $file
#Clean
    rm -Rf FusionInventory-Agent.pkg
    cd $oldDir

}

mkWinInstaller() {
    dir=$1
    file=$2
    nsisFilesTgz=$3
    nsisFilesZip=$4
    finalversion=$5

    tmpwindir="fusioninventory-nsis-$finalversion"
    rm -Rf $tmpwindir
    mkdir -p $tmpwindir
    cp -R $WINDOWSBASE $tmpwindir/nsis
    cp -R $dir $tmpwindir/files
    rm $tmpwindir/files/agent.cfg

    # Only keep the README.html for Windows
    rm -f $tmpwindir/files/README
    cp $ROOTDIR/LICENSE $tmpwindir/files/LICENSE.rtf

    mv $tmpwindir/nsis/FusionInventory_reg_XPUI.nsi $tmpwindir/nsis/FusionInventory.nsi
    sed -i "s,%%FINALVERSION%%,$finalversion," $tmpwindir/nsis/FusionInventory.nsi

    tar cfz $tmpwindir.tar.gz $tmpwindir
    zip -qr $tmpwindir.zip $tmpwindir

    makensis $tmpwindir/nsis/FusionInventory.nsi

    mv $tmpwindir/FusionInventory.exe $file
    mv $tmpwindir.tar.gz $nsisFilesTgz 
    mv $tmpwindir.zip $nsisFilesZip 

    rm -Rf $tmpwindir
}


createBaseTarball () {
    [ -d "$TMP/fusioninventory-agent-base" ] && rm -R "$TMP/fusioninventory-agent-base"

    mkdir -p "$TMP/fusioninventory-agent-base"

    cp -Rf $FILESDIR "$TMP/fusioninventory-agent-base"

    cd $TMP
    cp "$ROOTDIR/1-build-perl-tree.sh" "$TMP/fusioninventory-agent-base"
#    cp "$ROOTDIR/2-merge-fusinv-with-perl-tree.sh" "$TMP/fusioninventory-agent-base"

    tar cfz fusioninventory-agent-base.tar.gz fusioninventory-agent-base

    [ -d "$PREBUILTDIR/base" ] || mkdir "$PREBUILTDIR/base"

    mv $TMP/fusioninventory-agent-base.tar.gz "$PREBUILTDIR/base"

    cat > "$PREBUILTDIR/base/README" << EOF
You need this archive only if you want to create you own perl distribution of the Perl.

 - 1-build-perl-tree.sh allow you to build your Perl distribution and the dependencies used by FusionInventory
 - you may want to rename the generated tarball to match the OS name, eg: fedora12-i386.tar
 - You will then have to send the archive to us (goneri@rulezlan.org) , we will integrate the distribution on
   http://prebuilt.fusioninventory.org/stable/ 

File will be generated in "base-tarballs".

Please contact us on the mailing list if you've question or patches regarding these scripts.
 → http://fusioninventory.org/wordpress/contact/
EOF


    rm -R $TMP/fusioninventory-agent-base
}

if [ ! -d $BASETARBALLSDIR ]; then
    echo "No base-tarball directory found in $BASETARBALLSDIR"
    echo "run ./1-build-perl-tree.sh first"
    exit 1
fi

if [ ! -f $TARBALL ]; then
    echo "Can't find $TARBALL"
    exit 1
fi


if [ -n "$1" ]; then
    for flavor in $FLAVOR; do
        processTarball $flavor base-tarballs/$1
    done
    exit 0
fi

#for flavor in stable devel; do
for flavor in $FLAVOR; do
    for tarball in `ls $BASETARBALLSDIR/*.tar`; do
        echo "$flavor $tarball"
        processTarball $flavor $tarball
    done
done
createBaseTarball
