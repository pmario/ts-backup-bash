#!/usr/bin/env bash
set -o nounset
set -o errexit
set -e # exit with nonzero exit code if anything fails

# Usage:
#   $ ./tiddlyspace_backup my-username

ARG0=$(basename $0 .sh)
ARG0DIR=$(dirname $0)
[ $ARG0DIR == "." ] && ARG0DIR=$PWD

HOST="http://tiddlyspace.com"

FILE_ALL_SPACES="all-spaces.txt"
FILE_MY_SPACES="my-spaces.txt"

BAG_TYPES="public private"
SEARCH=""

username=""
password=""

createMySpaces=0
useInputFile=0


version () {
	echo
	echo "$ARG0, TiddlySpace Backup Script, Version 0.3.0"
	echo "Copyright (C) Mario Pietsch 2016"
	echo "License CC-BY-NC-SA https://creativecommons.org/licenses/by-nc-sa/3.0/"
	echo
}

usage() {
	echo
#	version
	echo Usage:$'\t'$ARG0 UserName [Options]
}

help() {
	usage
	echo
	echo "Options:"
	echo
	echo $'\t'-s .. Search string to create my-spaces.txt
	echo $'\t'-o .. Output filename. default: my-spaces.txt
	echo $'\t'-i .. Use FileName you created with -o parameter, as input to download public spaces
	echo
	echo $'\t'-v .. Version
	echo $'\t'-h .. This Help

	exit 0;
}

# check if there are no arguments at all
if (($# == 0)); then
	help
	exit
fi

# check if argument is first parameter
if [[ ! $@ =~ ^\-.+ ]]; then
	username="${1:?}"
	shift
	#echo "${username}: i was here"
else
	echo "first parameter needs to be the UserName"
fi

while getopts ":s:i:o:hv" flag ; do
	case "$flag" in
	(s) SEARCH="$OPTARG"
		createMySpaces=1
	;;
	(o) FILE_MY_SPACES="$OPTARG"
	;;
	(i) FILE_MY_SPACES="$OPTARG"
		useInputFile=1
	;;
	(h) help; exit 0;;
	(v) version; exit 0;;
	\?) echo
		echo "Invalid (-${OPTARG}) option"
		help;;
	: ) echo
		echo "Missing argument for -${OPTARG}"
		help;;
    (*) echo
		help;;
	esac
done
shift $(expr $OPTIND - 1)


if [[ $createMySpaces == 0 && $useInputFile == 0 ]]; then
	echo "Important:
	The user name and password will be transfered in plain text!
	Use this sript on your trusted home network only !!!!!!!

	A new <UserName> subdirectory will be created. 
	This allows you to download content for different users!

	Use [Ctrl]-C to stop the script at any time!"
	echo

	printf "\nUser: ${username}"
	printf "\nEnter the TiddlySpace password:"
	read -s password
else
	echo "Important:
	If all-spaces.txt doesn't exist, it will be downloaded.
	So you are about to download a list of all TiddlySpace space names!

	Use [Ctrl]-C to stop the script at any time!"
	echo

fi

# check, if we can access spaces?mine=1 or if we should use all-spaces.txt to create a download list.
if [[ $createMySpaces == 0 && $useInputFile == 0 ]]; then
	#printf "\nget spaces\n"
	spaces=`curl -u "$username:$password" "http://$username.tiddlyspace.com/spaces?mine=1" | sed 's;"name": ";\'$'\n;g' | sed 's;".*;;g' | sed 's;\[{;;g'`
elif [[ $useInputFile == 1 ]]; then
	spaces=$(<$FILE_MY_SPACES)
	BAG_TYPES="public"
else
	#printf "\nget ALL spaces\n"

	if [[ -f $FILE_ALL_SPACES && $createMySpaces == 1 ]]; then
		printf "\n\n${FILE_ALL_SPACES} exists. It will be reused, to create ${FILE_MY_SPACES}!\n\n"
		read -r -p "Are you ready [y/N]?" confirm
		case $confirm in
		[yY][eE][sS]|[yY]) echo "";;
			*) exit;;
		esac
	else
		printf "\nThe script will download a list of all space names. This can take 30+ seconds.\nFiles named: all-spaces.txt and ${FILE_MY_SPACES} will be created.\n\n"

		read -r -p "Do you want to continue [y/N]? " confirm
		case $confirm in
			[yY][eE][sS]|[yY]) echo "";;
			*) exit;;
		esac

		curl -u "$username:$password" "http://tiddlyspace.com/recipes.txt" > all-spaces.txt
	fi
	# remove _public postfix and remove _private lines completely
	cat $FILE_ALL_SPACES | grep -i ${SEARCH} | sed 's;_public;;g' | sed '/_private/d' > $FILE_MY_SPACES
	spaces=$(<$FILE_MY_SPACES)
	BAG_TYPES="public"
fi

# calculate number of spaces
noSpaces=$(wc -w <<< $spaces)

cd `dirname $0`

# some variable definitions
output="${username}/data"
logfile="spaces-${username}.log"

printf "\n---> Those ${noSpaces} Spaces are prepared to be downloaded:\n\n"

for space in $spaces; do
	echo "  ${space}"
done

# create a log file, that can be used to move the stuff to the internet archive.org
# see: https://archive.org/web/  ... Save Page Now input area!!
rm -f "${logfile}" # 2> /dev/null

for space in $spaces; do
	echo "http://${space}.tiddlyspace.com" >> $logfile
done
# --- end log

printf "\nDownloading many spaces may need a long time. You selected: ${noSpaces} spaces."
printf "\nThe data directory will be: ${output}\n\n"

read -r -p "Do you want to continue [y/N]? " confirm
case $confirm in
    [yY][eE][sS]|[yY]) echo "" ;;
    *)	exit;;
esac

# create data dir, if it doesn't exist
mkdir -p ${output}

# test empty space
#for space in dboxgallery; do

for space in $spaces; do

	# get public recipe only, since private does a redirect.
	uri="$HOST/recipes/${space}_public.txt"

	echo ""
	echo "---> Get info for: $space"
	echo ""

	curl -u "$username:$password" "$uri" > "${output}/${space}_public.recipe.txt"

	for mode in $BAG_TYPES; do
		# get data 
		uri="$HOST/bags/${space}_${mode}/tiddlers.json?fat=1"
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
				uri="$HOST/recipes/${space}_${mode}/tiddlers.wiki"

				echo ""
				echo "Download wiki: $uri"
				echo ""
				
				curl -u "$username:$password" "$uri" > "${output}/${space}_${mode}.html" 
			fi
		fi
	done
done
