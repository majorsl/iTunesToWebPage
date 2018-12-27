#!/usr/bin/env bash
# Version 2.1
# Script to share what is playing with iTunes to a Web Page. Companion script is
# iTunesToServer.
#
# This script takes the feed from the client and formats it for the blog (currently
# WordPress) side. The client side script is what evokes this, there is no need for a
# launchd entry on your server.
#
# The last line of this script is where you can modify your output.
#
# Set Other Options Here:

# Path to the directory where the companion uploads its data:
maindata="/Users/majorsl/Sites/tunes/"

# Path to the directory where the html file is sent for publishing:
htmldata="/Users/majorsl/Library/Containers/nz.co.pixeleyes.AutoMounter/Data/Mounts/synology/SMB/web/tunes/"

# Star rating symbols to use. 5 star rating, if you use an inverse that will display as
# the "unfilled" stars. You may also leave it empty by just using "" for starinverse.
star="&#9733;"
starinverse="&#9734;"

# Directory of Album Artwork. Must be a .jpg and in "Artist Name - Album Name" format and
# match the artist & album name in your iTunes exactly!
# Example filename: Gin Blossoms - Outside Looking In.jpg
artwork="/Users/majorsl/Library/Containers/nz.co.pixeleyes.AutoMounter/Data/Mounts/synology/SMB/web/tunes/Artwork/"

# url path to the artwork:
urlartwork="https://www.themajorshome.com/tunes/Artwork/"

# Where to put a text file listing missing album art.
missing="/Users/majorsl/Downloads/missingartwork.txt"

# End of Options

cd $maindata || exit

rating=""

IFS=$'\n'

# Array: 0=album 1=artist 2=rating 3=track  Will I need to sanitize with sed "s/\&#39;/\'/" at some point?
tune=($(cat itunesstring.txt))
unset IFS

# Cleanup of filenames for artwork file links e.g. smartquotes currently.
album=$(echo "${tune[0]}" | sed s/\&\#8217\;/\'/g)
artist=$(echo "${tune[1]}" | sed s/\&\#8217\;/\'/g)

if [ "${tune[3]}" = "empty" ]; then
	> "$htmldata"itunesblog.html
	exit
fi

# Assemble star rating.
xloop="0"
starnumber=$((${tune[2]} / 20))
starnumberinv=$((5 - starnumber))

while [ "$xloop" -lt "$starnumber" ]; do
rating="$star""$rating"
xloop=$((xloop+1))
done
xloop=0
while [ "$xloop" -lt "$starnumberinv" ]; do
rating="$rating""$starinverse"
xloop=$((xloop+1))
done

if [ "$starnumber" = "0" ]; then
	rating=""
elif [ "$starnumber" -gt "0" ]; then
	rating=' I rate it <span style="font-size: 120%;">'$rating'</span>.'
fi

# Does the artwork exist?
if [ ! -f "$artwork$artist - $album.jpg" ]; then
    #No? Better tell someone by slapping a txt file on the server desktop and set a generic!
    echo "$artist - $album.jpg" >> $missing
    album="noart"
    artist="noart"
fi

#String for Wordpress Blog
echo '<h3 class="widget-title">Currently Listening To</h3>"'${tune[3]}'" by '${tune[1]}' from the album <i>'${tune[0]}'</i>.'$rating'<br><img src="'$urlartwork''$artist' - '$album'.jpg" alt="" width="300" border="0">' > "$htmldata"itunesblog.html
