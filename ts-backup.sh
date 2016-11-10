#!/usr/bin/env bash
set -e # exit with nonzero exit code if anything fails

# initial scrip from: http://sandbox.tiddlyspace.com/_/b6909b19-ecfb-4b31-a782-48d22d6abf5f
# has too many dependencies

# author: Mario Pietsch
# Version: 0.2.0
# License: CC-BY-NC-SA

# Usage:
#   $ ./tiddlyspace_backup my-username

host="http://tiddlyspace.com"

username="${1:?}"
shift

echo "Important:
	The user name and password will be transfered in plain text!
	Use this sript on your trusted home network only !!!!!!!

	A new <UserName> subdirectory will be created. 
	This allows you to download content for different users!

	Use [Ctrl]-C to stop the script at any time!"


printf "\nEnter the TiddlySpace password:"
read -s password

# mingw doesn't know jq command, so use sed instead extract the names
# sed 's;"name": ";\'$'\n;g' | sed 's;".*;;g' | sed 's;\[{;;g'

spaces=`curl -u "$username:$password" "http://$username.tiddlyspace.com/spaces?mine=1" | sed 's;"name": ";\'$'\n;g' | sed 's;".*;;g' | sed 's;\[{;;g'` 

cd `dirname $0`

# some variable definitions
output="${username}/data"
logfile="spaces-${username}.log"

printf "\n---> Those Spaces are prepared to be downloaded:\n"

for space in $spaces; do
	echo "http://${space}.tiddlyspace.com"
done

# create a log file, that can be used to move the stuff to the internet archive.org
# see: https://archive.org/web/  ... Save Page Now input area!!
rm -f "${logfile}" # 2> /dev/null

for space in $spaces; do
	echo "http://${space}.tiddlyspace.com" >> $logfile
done
# --- end log

printf "\nThe download process may need several minutes.\n"

read -r -p "Do you want to continue [Y/n]? " confirm
case $confirm in
    [yY][eE][sS]|[yY]) 
        #do_something
		#echo yes
		echo ""
        ;;
    *)
        #do_something_else
		exit
        ;;
esac

# create data dir, if it doesn't exist
mkdir -p ${output}

# test empty space
#for space in dboxgallery; do


for space in $spaces; do

	# get public recipe only, since private does a redirect.
	uri="$host/recipes/${space}_public.txt"

	echo ""
	echo "---> Get info for: $space"
	echo ""


	curl -u "$username:$password" "$uri" > "${output}/${space}_public.recipe.txt"

	for mode in "public" "private"; do
		# get data 
		uri="$host/bags/${space}_${mode}/tiddlers.json?fat=1"
		out="${output}/${space}_${mode}.json"
		curl -u "$username:$password" "$uri" > "${output}/${space}_${mode}.json" 

		# if there is no data, so the json file size is 0 don't load the html file!
		if [ -s ${out} ] 
		then 
			if [ "$(head -n 1 $out)" = "[]" ]
			then
				echo ""
				echo "---> $out - JSON is empty. HTML file download skipped!"
				echo ""
			else
				# get the html file
				uri="$host/recipes/${space}_${mode}/tiddlers.wiki"

				echo ""
				echo "Download wiki: $uri"
				echo ""
				
				curl -u "$username:$password" "$uri" > "${output}/${space}_${mode}.html" 
			fi
		fi
	done
done
