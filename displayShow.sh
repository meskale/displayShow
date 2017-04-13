#!/bin/bash

while ! grep -qs '/mnt/ecranAtelier' /proc/mounts;
do
sleep 1
done



RUN=true
HOME=/home/pi/displayShow

HOSTNAME=$( hostname )
SRCFOLDER=/mnt/ecranAtelier
ROOTFOLDER=/mnt/ecranAtelier
getShowFile()
{
	if ls $ROOTFOLDER/$HOSTNAME ; then
		if ls $ROOTFOLDER/$HOSTNAME/*.odp -t >/dev/null 2>&1  ;then
		        OLDSHOWFILE=$SHOWFILE	
			SRCFOLDER=$ROOTFOLDER/$HOSTNAME
			SHOWFILE=$(basename `ls $SRCFOLDER/*.odp -t | head -1` )
		else
			SRCFOLDER=$ROOTFOLDER
			SHOWFILE=$(basename `ls $SRCFOLDER/*.odp -t | head -1` )
		fi

	else
		SRCFOLDER=$ROOTFOLDER
		SHOWFILE=$(basename `ls $SRCFOLDER/*.odp -t | head -1`  )
	fi
	
}


handle_sigterm()
{
	RUN=false

	stopShow		
	rm /tmp/$SHOWFILE
	echo " Arrêt "  
	exit 0
}

startShow()
{
	libreoffice --show  --norestore /tmp/$SHOWFILE &	
}

stopShow()
{
	if  pidof soffice.bin ; then
		kill -TERM $(pidof soffice.bin)
		rm /tmp/.~lock.$SHOWFILE\#
	fi
}

trap 'handle_sigterm' TERM INT 


getShowFile
echo "show file to load $SHOWFILE"

while $RUN  
do
	if ls $SRCFOLDER/.*.odp\# > /dev/null 2>&1 ; then
		echo "source file locked...skip diff" 
	else
		getShowFile		
		if diff $SRCFOLDER/$SHOWFILE /tmp/$SHOWFILE ;then

			if ! pidof soffice.bin > /dev/null 2>&1 ;then
				startShow
			fi
		else
			echo "show file differ from src... copying... "  
			rm /tmp/$OLDSHOWFILE
			if  pidof soffice.bin ; then
				stopShow
			fi
			cp $SRCFOLDER/$SHOWFILE /tmp
		  	if ! pidof soffice.bin ;then
				startShow
			fi
			sleep 5
		fi
	fi


sleep 1		
done



exit 0
