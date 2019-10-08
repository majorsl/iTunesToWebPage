#!/usr/bin/env bash
# Version 3.0
# Script to share what is playing with Music to a Web Page. Companion script is iTunes
# to web. Assumes you have password-less SSH Keys setup between your client(s) & server!
#
# Use a launchd script to run this at user login: ~/LaunchAgents
#
# --Options--
# Server to send data to.
server="server.themajorshome.com"
# Path on server where to save data file.
serverdata="/Users/majorsl/Sites/tunes"
# Path on server where counterpart iTunesToWeb script is located.
serverscript="/Users/majorsl/Scripts/GitHub/iTunesToWebPage"
# --End Options--

# oldinfo/info is the last data sent, if it does not match that triggers the upload to the server.
oldinfo="empty"

while :
do

# Music Open Status true / false
if pgrep -x "Music"; then itunes="true"; else itunes="false"; fi
echo "**diagnostic loop** Music Open:" $itunes

	# Get/check Music state.
	if [ "$itunes" = "true" ]; then
		state=$(if pgrep -x -q "Music"; then osascript -e 'tell application "Music" to player state as string'; fi)
		sleep 10

		# When playing: sed statement for smart quotes because a standard ' will confuse BASH in the literal string. Also checking file modification to avoid osascript polling & opening Music soon after a recent quit.
		if [ "$state" = "playing" ]; then
			if pgrep -x "Music"; then
				artist=$(osascript -e 'tell application "Music" to artist of current track as string' | sed s/\'/"\\&"\#8217\;/g)
				album=$(osascript -e 'tell application "Music" to album of current track as string' | sed s/\'/"\\&"\#8217\;/g)
				track=$(osascript -e 'tell application "Music" to name of current track as string' | sed s/\'/"\\&"\#8217\;/g)
				rating=$(osascript -e 'tell application "Music" to rating of current track as string')
			itunesstring="$album\\n$artist\\n$rating\\n$track"
			info="$artist$track$album"
			echo "**diagnostic track info-playing $state $artist $track $album $rating**"
			fi			

		# When not playing.
		else
			itunesstring="empty\\nempty\\n0\\nempty"
			echo "**diagnostic Music stopped**"
			info="empty"
		fi
		
	# Music is not Open. Send not running data the same as if stopped/paused.
	else
		sleep 10
		itunesstring="empty\\nempty\\n0\\nempty"
		echo "**diagnostic Music not Open**"
		info="empty"
	fi

	# Send data if new.
	if [ "$oldinfo" != "$info" ]; then
		echo "**diagnostic send to server**"
		ssh -o ServerAliveCountMax=2 -o ConnectTimeout=30 $server "printf '%b\\n' '$itunesstring' > $serverdata/itunesstring.txt"
		ssh -o ServerAliveCountMax=2 -o ConnectTimeout=30 $server "$serverscript/./iTunesToWeb.sh"
		oldinfo="$info"
	fi

done
