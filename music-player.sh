#!/bin/bash

#==== FIXES ====
#TODO - if possible, pause
#TODO - fix bug with delete not working when asking for index

#==== FEATURES ====
#TODO - add (r)ename option (enter new name: mv $MUSIC_DIR/MUSIC_LIST(SONG_INDEX $MUSIC_DIR/new name)
#TODO - get_duration function (possibly show duration on main screen, update it in loop - SECONDS)
#TODO - consider putting caffeinate in setup 
#TODO - add h for help/or tutorial
#TODO - Use recursive search and find all music files on computer -> music_list
	# Should be an option not default behavior, probably intensive
#TODO - add minigames to mp3 player
	#(1) "rate songs", at the end it displays your favorite song and the ratings you gave
	#(2) somehow find tempo of song and display animation correspondingly (using $SECONDS)
	#(3) random animation
	# eesh, no bloat pls
#TODO - show metadata option (afinfo)
#TODO - integrate all options from mpg123 into linux version
#TODO - arrowkeys for next/back


# ========== GLOBAL VARIABLES ==========
#MUSIC_DIR - Directory with music files (either default or specified with $1)
#NUM_SONGS - number of songs in $MUSIC_DIR
#MUSIC_LIST - array of songs in $MUSIC_DIR
#REQUESTED_INDEX - either SHUFFLE or number between 0 - NUM_SONGS, used as parameter for play_song (processed into SONG_INDEX)
#SONG_INDEX - random or specified number between 0 - NUM_SONGS, used as index to access song file from MUSIC_LIST
#EXTENSIONS - file extensions *.mp3, *.wav, etc (feel free to modify, preserving current format)
# ========== /GLOBAL VARIABLES ==========


# ========== HELPER FUNCTIONS ==========

#theme function
make_colorful() {
	#tput setab 4
	#tput setaf 7
	:
}

clearscreen() {
	clear && printf '\e[3J'
}

ctrl_c() {
	#unbold
	tput sgr0
	stop_song
	clearscreen 
	exit 0
}

pkg_installed() {
	man "$1" &> /dev/null
	local man_status=$? #if the man page exists status will be 0, else 1

	installed=$(which "$1")

	if [ $man_status -eq 0 ] || [ -n "$installed" ]; then
		return 0
	else
		return 1
	fi
}

is_not_base_10() {
	local first_char="${1:0:1}"
	local num_digits=$(printf "$1" | wc -m) #wc -m counts chars

	#if input has a prefix of 0 but continues, it is signifying a number in another base system
	if [ "$first_char" = 0 ] && [ "$num_digits" != 1 ]; then
		return 0 #successfully not base 10
	else
		return 1
	fi
}

is_not_digit() {

	local re='^[0-9]+$'

	if ! [[ "$1" =~ $re ]] || is_not_base_10 "$1"; then # $1 is not a digit, return error code 0 (sucess)
   		return 0
   	fi

   	return 1 # $1 is a digit, return error code 1 (failure)
}

#Ceiling + 1 using bc
float_to_int() {
	local var=$(echo "$1/1 + 2" | bc)
	echo "$var"
}

#Convert input from a real number to an integer (POSIX-compliant)
float_to_int2() {
	awk 'BEGIN{for (i=1; i<ARGC;i++)
	printf "%.0f\n", ARGV[i]}' "$@"
}

bold() {
	tput bold
}

unbold() {
	tput sgr0
	make_colorful
}

stop_song() {
	#killall mpg123 &> /dev/null
	killall ffplay &> /dev/null
	clearscreen
}

#Finds number of songs in directory (MUSIC_DIR)
num_songs() {
	ls -l "$MUSIC_DIR"/$EXTENSIONS 2> /dev/null | wc -l
	#Note: the command "2> /dev/null" redirects error messages, but leaves regular output
}

is_invalid_index() {
	if is_not_digit "$1" || [ "$1" -gt "$NUM_SONGS" ] || [ "$1" -lt 0 ]; then
		return 0
	fi		
	return 1
}

not_replay() {
	#if this is the first song, or if the current song is already recorded in history
	if [ "${#HISTORY[@]}" -eq 0 ] || [ "$SONG_INDEX" != "${HISTORY[${#HISTORY[@]}-1]}" ]; then
		return 0
	fi
	return 1
}
# ========== /HELPER FUNCTIONS ==========

# ========== MAIN FUNCTIONS ==========
setup() {
	trap ctrl_c INT #if the user enters ctrl -c, allow me to do cleanup first

	#If the number of args > 1, exit
	if [ "$#" -gt 1 ]; then
		bold; echo "Check your arguments! Only provide an [optional] path to your music directory."; unbold
		exit 1 
	#If the number of args = 1, that arg must be a path to your music files
	elif [ "$#" -eq 1 ]; then
		#Set MUSIC_DIR to user-specified path to audio files
		MUSIC_DIR="$1"
	fi

	#cd throws error and exits if improper path
	cd "$MUSIC_DIR" || exit

	#Get the number of songs in the specified directory, make sure it isn't 0
	NUM_SONGS=$(num_songs)
	if [ "$NUM_SONGS" -eq 0 ]; then
		bold; echo "Found no songs in specified directory!"; unbold
		exit 1
	fi

	#----
	#THE FOLLOWING ARE SOLUTIONS TO GLOBS NOT EXPANDING
	#PREVIOUS: EXTENSIONS="*.mp3 *.pcm *.wav *.aac *.ogg *.m4a *.aif *.flac"

	#SOLUTION 1
	EXTENSIONS=()
	ext_list=("*.mp3" "*.pcm" "*.wav" "*.aac" "*.ogg" "*.m4a" "*.aif" "*.flac")
	for ext in "${ext_list[@]}"
	do
		if ls ./$ext &> /dev/null; then #files exist
   			EXTENSIONS="$EXTENSIONS $ext"
   		fi
	done

	#SOLUTION 2 (bash only)
	#shopt -s nullglob

	#----

	#Create array of all audio files in MUSIC_DIR
	MUSIC_LIST=( $EXTENSIONS )
	
	#Will store all songs which have been played in current session
	HISTORY=()

	make_colorful
	clearscreen
}

#List files/indexes for user and allow them to scroll through in less
show_songs() {
	#NF - Last field (File name), NR - Row number, less -S turns off word fold
	bold; find "$MUSIC_DIR"/${ext_list[@]} 2> /dev/null | awk -F'/' '{print "["NR-1"]\t" $NF}' | less -S; unbold
}


#Set REQUESTED_INDEX to the previous song played
queue_previous() {
	#pop last element of the history array
	REQUESTED_INDEX="${HISTORY[${#HISTORY[@]}-1]}"
}

#Download song, update number of songs, update array of songs
download_song() {
	if pkg_installed "youtube-dl" && pkg_installed "ffmpeg"; then
		bold; read -r -p "Enter URL: " URL && cd "$MUSIC_DIR"; unbold
		youtube-dl --extract-audio --audio-format mp3 --output "%(title)s.%(ext)s" "$URL" 2> /dev/null && NUM_SONGS=$(num_songs) && MUSIC_LIST=( $EXTENSIONS )
		
		local status=$? #if song downloaded successfully, status is 0
		if [ $status = 0 ]; then
			bold; echo "Success! Check your $MUSIC_DIR folder for the file."; unbold; read -t 3
			clearscreen
		else
			tput setaf 1; printf "ERROR"; tput sgr0; make_colorful
			echo ": $URL is not a valid URL."
			read -t 5
			clearscreen
		fi

	else
		bold; echo "You must have youtube-dl and ffmpeg installed to use this feature. Install using your desired package manager then try again."; unbold; read -t 4
	fi
}

show_pick_song_options() {
	print_ascii_art
	bold; echo "(q)uit, (l)ibrary"; unbold
	bold; printf "|"; unbold; printf "| Play Song #: "
}

#Sets REQUESTED_INDEX to user specified song index
pick_song() {
	local index #used to store potential index for next song
	stty sane #fixes strange bug with delete key not being picked up
	show_pick_song_options

	while :; do
		#read -n 1 makes keys get read right away
		local char
		read -r -n 1 char

		#quit
		if [[ "$char" = "q" ]]; then
			show_music_player && return
		#show songs
		elif [[ "$char" = "l" ]]; then
			show_songs
			index=""
			show_pick_song_options
		#User pressed enter, assess their index
		elif [[ "$char" = "" ]]; then
			if is_invalid_index "$index"; then
				bold; echo "Index is invalid."; unbold;
				index="" #reset index
				read -t 1
				show_pick_song_options
				continue #try again
			#Index is valid, submit it
			else
				REQUESTED_INDEX="$index"
				return
			fi
		#User is still typing the index
	   	else
	   		index="$index$char" # append input
	   	fi
	done
}

toggle_repeat_mode() {
	clearscreen
	print_ascii_art
	bold; echo "(q)uit, (d)isable repeat mode"; unbold

	local choice="timeout"

	while :; do
		REQUESTED_INDEX="$SONG_INDEX" #current playing song's index

		read -n 1 -s -t $(($INT_DURATION - $SECONDS)) choice #if the song ends, we'll enter the choice="timeout" procedure
		if [ "$choice" = "q" ]; then
			ctrl_c
		elif [ "$choice" = "d" ]; then
			REQUESTED_INDEX="SHUFFLE" #repeat mode off, go back to shuffle
			return
		elif [ "$choice" = "timeout" ]; then
			SECONDS=0 #reset seconds count before playing next song
			clearscreen
			play_song "$REQUESTED_INDEX"
			bold; echo "(q)uit, (d)isable repeat mode"; unbold
		else
			choice="timeout"
		fi
	done
}

show_music_player() {
	print_ascii_art
	show_options "$INT_DURATION" "1"
}

print_ascii_art() {
	clearscreen
	#formatting (optimized for 80 by 24 terminal window)
	tput rmam #disables line wrap
	echo " _______________________________"
	echo "| \___===____________________()_\ "
	echo "| |                              |"
	echo "| |   _________________________  |"
	echo "| |  |                        |  |"
	echo "| |  |                        |  |"
	echo "| |  |${MUSIC_LIST[$SONG_INDEX]}  "
	echo "| |  |                        |  |"
	echo "| |  |________________________|  |"
	echo "| |                              |"
	echo "| |                              |"
	echo "| |              @@@@            |"
	echo "| |           @@@ ❤︎❤︎ @@@         |"
	echo "| |          @@@@@@@@@@@@        |"
	echo "| |         @<<@@@()@@@>>@       |"
	echo "| |          @@@@@@@@@@@@        |"
	echo "| |           @@@ ||>@@@         |"
	echo "| |              @@@@            |"
	echo "| |                              |"
	echo " \|______________________________|"
	tput smam #re-enables line wrap
}

#Prints formatting, plays random song, defines a global variable with duration of current song
play_song() {
	if [ "$1" = "SHUFFLE" ]; then
		SONG_INDEX=$(($RANDOM % $NUM_SONGS)) #Get random index in range of NUM_SONGS
	else
		SONG_INDEX="$1"
		REQUESTED_INDEX="SHUFFLE" #resets for next time
	fi

	print_ascii_art

	#Duration of current song in seconds (global variable)
	FLOAT_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$MUSIC_DIR"/"${MUSIC_LIST[$SONG_INDEX]}")

	#Play song file (process runs in the background)
	#mpg123 -q --no-gapless -D 0.5 --no-seekbuffer "$MUSIC_DIR"/"${MUSIC_LIST[$SONG_INDEX]}" &
	ffplay -nodisp -loglevel panic "$MUSIC_DIR"/"${MUSIC_LIST[$SONG_INDEX]}" &

	#if not replaying last song, add currently playing song to history (at the end of the array)
	if not_replay; then
		HISTORY=( "${HISTORY[@]}" "$SONG_INDEX" )
	fi
}

#Prints options, times out after song ends so another one can play
show_options() {
	#If no option is provided before the song stops playing, then go to the next song
	#"TIMEOUT" is a default value; if $option still equals "TIMEOUT" after read, we know the user didn't input anything
	local option="TIMEOUT"

	echo "(n)ext, (b)ack, (p)ick, (l)ibrary, (q)uit, (d)ownload, (r)epeat"
	
	#we only want to set seconds to 0 when we start playing a new song ($2 will be "1" if song is already playing)
	if [ "$2" == "" ]; then
   		SECONDS=0
   	fi

	read -n 1 -s -t $(($INT_DURATION - $SECONDS)) option

	# =========== OPTIONS ===========
	#Next song; OR song duration has expired
	if [ "$option" = "n" ] || [ "$option" = "TIMEOUT" ]; then
		stop_song
	#list available songs
	elif [ "$option" = "l" ]; then
		show_songs
		show_music_player
	#ask user to pick a song
	elif [ "$option" = "p" ]; then
		pick_song #Sets REQUESTED_INDEX to valid index
		stop_song
		clearscreen
	#play previous song
	elif [ "$option" = "b" ]; then
		#Remove current song from history (unless there's only 1 song in history)
		if [ "${#HISTORY[@]}" -gt  1 ]; then
			unset 'HISTORY[${#HISTORY[@]}-1]'
		fi
		queue_previous
		stop_song
	#FOR DEBUGGING - show history
	elif [ "$option" = "h" ]; then
		echo "Length: ${#HISTORY[@]}"
		printf '%s ' "${HISTORY[@]}"
		read -t 5
		show_music_player
	#quit
	elif [ "$option" = "q" ]; then
		ctrl_c
	#download song from url
	elif [ "$option" = "d" ]; then
		download_song
		show_music_player
	#Invalid input; show options again and do nothing
	elif [ "$option" = "r" ]; then
		toggle_repeat_mode #holds user in this function until they exit repeat mode
		clearscreen
		print_ascii_art
		show_options "$(($INT_DURATION - $SECONDS))" "1" #don't reset elapsed time
	else
		show_music_player
	fi
	# =========== /OPTIONS ===========
}
# ========== /MAIN FUNCTIONS ==========


#The script will start executing here
EXTENSIONS="*.mp3 *.pcm *.wav *.aac *.ogg *.m4a *.aif *.flac"
MUSIC_DIR=~/Downloads #default directory of audio files
setup "$@" #pass arguments to script into function

#Value is changed by show_options, pick_song, or queue_previous
#Value is reset to SHUFFLE by play_song whenever a new song is played
REQUESTED_INDEX="SHUFFLE" #Begin by shuffling music

# ============ MAIN EXECUTION LOOP ============ #
while :;
do	
	play_song "$REQUESTED_INDEX"
	INT_DURATION=$(float_to_int "$FLOAT_DURATION")
	#Show options for INT_DURATION seconds (entirety of song)
	show_options "$INT_DURATION"
done