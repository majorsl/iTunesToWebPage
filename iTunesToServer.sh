#!/bin/sh
# Version 2.0.3
# Script to share what is playing with iTunes to a Web Page. Companion script is iTunes
# to web. Assumes you have password-less SSH Keys setup between your client(s) & server!
#
# 1. It assumes your iTunes library is in the default location. If not, modify the path on
# line 27.
# 2. Adjust lines 64 & 65 for where the counterpart script is on your web-server.
# 3. Use a launchd script to run this at user login: ~/LaunchAgents

# oldinfo/info is the last data sent, if it does not match that triggers the upload to the server.
oldinfo="empty"
filemod="empty"

while :
do

# iTunes Open Status true/false
itunes=`osascript -e 'tell application "System Events" to set iTunesIsRunning to (name of processes) contains "iTunes"'`
echo "**diagnostic loop** iTunes Open:" $itunes

	# Get/check iTunes state.
	if [ "$itunes" = "true" ]; then
		state=`osascript -e 'tell application "System Events" to if ((name of processes) contains "iTunes") then do shell script ("osascript -e " & quoted form of ("tell application \"iTunes\" to player state as string"))'`
		#-> this is the old way I was doing it, but it would open iTunes if it was closed. Above will check if it is running first. state=`osascript -e 'tell application "iTunes" to player state as string'`
		sleep 10
		filemod=`stat -f '%m' ~/Music/iTunes/iTunes\ Library.itl`
		echo "**file modification $filemod**"

		# When playing: sed statement for smart quotes because a standard ' will confuse BASH in the literal string. Also checking file modification to avoid osascript polling & opening iTunes soon after a recent quit.
		if [ "$state" = "playing" ]; then
			if [ "$filemod" != "$oldfilemod" ]; then
				artist=`osascript -e 'tell application "System Events" to if ((name of processes) contains "iTunes") then do shell script ("osascript -e " & quoted form of ("tell application \"iTunes\" to artist of current track as string"))' | sed s/\'/"\\&"\#8217\;/g`
				track=`osascript -e 'tell application "System Events" to if ((name of processes) contains "iTunes") then do shell script ("osascript -e " & quoted form of ("tell application \"iTunes\" to name of current track as string"))' | sed s/\'/"\\&"\#8217\;/g`
				album=`osascript -e 'tell application "System Events" to if ((name of processes) contains "iTunes") then do shell script ("osascript -e " & quoted form of ("tell application \"iTunes\" to album of current track as string"))' | sed s/\'/"\\&"\#8217\;/g`
				rating=`osascript -e 'tell application "System Events" to if ((name of processes) contains "iTunes") then do shell script ("osascript -e " & quoted form of ("tell application \"iTunes\" to rating of current track as string"))'`

			itunesstring="$album\n$artist\n$rating\n$track"
			info="$artist$track$album"
			echo "**diagnostic track info-playing $state $artist $track $album $rating**"
			fi
			oldfilemod="$filemod"
			
		# When not playing.
		else
			itunesstring="empty\nempty\n0\nempty"
			echo "**diagnostic iTunes stopped**"
			info="empty"
			filemod="empty"
		fi
		
	# iTunes is not Open. Write not running data the same as if stopped/paused.
	else
		sleep 10
		itunesstring="empty\nempty\n0\nempty"
		echo "**diagnostic iTunes not Open**"
		info="empty"
		filemod="empty"
	fi

	# Write data if new.
	if [ "$oldinfo" != "$info" ]; then
		echo "**diagnostic send to server**"
		ssh -o ServerAliveCountMax=2 -o ConnectTimeout=30 server.themajorshome.com "printf '%b\n' '$itunesstring' > ~/Sites/tunes/itunesstring.txt"
		ssh -o ServerAliveCountMax=2 -o ConnectTimeout=30 server.themajorshome.com '~/Scripts/GitHub/iTunesToWebPage/./iTunesToWeb.sh'
		oldinfo="$info"
	fi

done
