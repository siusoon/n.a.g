#!/bin/bash
# Inotify-based file sync with multiple processing modes.
# Used commands: date, find, inotifywait (inotify-tools), ls, rm, rsync, tail, wc
# Try ifs.sh -h for help.
# Pipe output to a logfile: ifs.sh [PARAMS] >> $LOGFILE 2>&1
# GCB, 20.08.2018

STAMP="19.2.9-12cdb"
SCRIPTNAME="${0##*/}"

##################################
# Configuration of default values
##################################

#
# Shared configuration variables
#

# The script mode (supported values: rotated, dated).
defSCRIPTMODE="rotated"
# The source directory (which is watched for filesystem changes).
defDIRECTORYSRC="/var/www/nag_05_b1_gal-rpi/thumb/"
# The destination directory (which will be filled with selected files).
defDIRECTORYDST="/var/www/nag_05_b1_gal-rpi/gallery/thumbs/"
# The path to the (temporary) filtered file sync list (prefer /tmp, might be tmpfs).
defFILELIST="/tmp/ifslist"

#
# dated configuration variables
#

# The date from which files are selected.
defDATESTART="2019-02-01"
# The date to which files are selected.
defDATEEND="2021-04-01"

#
# rotated configuration variables
#

# The archive directory (which will be filled with outdated files from the destination directory).
defDIRECTORYARC="/var/www/nag_05_b1_gal-rpi/gallery/archive/"
# The maximum number of images in the target directory before moving the oldest files into the archive directory.
defROTATELIMIT=2769

##############
# Help output
##############

if [[ "$*" == *"-h"* ]]; then
	echo "$SCRIPTNAME - Inotify-based file sync with multiple processing modes"

	echo -e "\nThe original purpose of this script was to to sync files with a modification\ndate matching a specific range from one folder (from now on called source\ndirectory) to a different folder (from now on called target directory)."
	echo -e "\nWhen surpassing the end of defined date range, the script would terminate itself\nto avoid unwanted synchronization runs."
	echo -e "\nThis behavior is now represented in the mode called dated."
	echo -e "\nThe new default is the mode called rotated. In this mode files still are synced\nfrom the source directory to the target directory, but there is no date limit."
	echo -e "\nInstead there is a limit on the number of images in the target directory.\nIf the next sync would result in an exceedance of this limit, the oldest files\nin the target directory are moved into an archive directory."
	echo -e "\nPlease note that remote source directories are not supported at all and remote\ntarget directories need to have a non-interactive ssh access configured."

	echo -e "\n\nFlags:\n"
	echo "-h                Print this help output and exit"

	echo -e "\n\nMode parameter (before all others):\n"
	echo "Mode              Switch between dated and rotated"
	echo "  default: $defSCRIPTMODE"

	echo -e "\n\nParameters (dated mode, in this order):\n"
	echo "Source path       The path of the source directory"
	echo "   default: $defDIRECTORYSRC"
	echo "Target path       The path of the target directory"
	echo "   default: $defDIRECTORYDST"
	echo "Daterange start   The date from which files are selected"
	echo "   default: $defDATESTART"
	echo "Daterange end     The date to which files are selected"
	echo "   default: $defDATEEND"
	echo "File list path    The path to the (temporary) filtered file list"
	echo "   default: $defFILELIST"

	echo -e "\n\nExamples:"
	echo -e "\nSync files from directory /tmp/source/ to the local directory /tmp/target/ dated\nfrom the 21st of August, 2018 to the 22nd of August, 2018, using /tmp/ifslist as\nfile list:\n"
	echo "\$ $SCRIPTNAME dated /tmp/source/ /tmp/target/ 2018-08-21 2018-08-22 /tmp/ifslist"
	echo -e "\nSync files from directory /tmp/source/ to the remote directory /tmp/target/ of\nhost anduin using the user greylin dated from the 3rd of October, 2018 to the\n17th of October, 2018, using the default value of the file list:\n"
	echo "\$ $SCRIPTNAME dated /tmp/source/ greylin@anduin:/tmp/target/ 2018-10-03 2018-10-17"

	echo -e "\n\nParameters (rotated mode, in this order):\n"
	echo "Source path       The path of the source directory"
	echo "   default: $defDIRECTORYSRC"
	echo "Target path       The path of the target directory"
	echo "   default: $defDIRECTORYDST"
	echo "Archive path      The path of the archive directory"
	echo "   default: $defDIRECTORYARC"
	echo "Rotation limit    The maximum number of images in the target directory"
	echo "   default: $defROTATELIMIT"
	echo "File list path    The path to the (temporary) filtered file list"
	echo "   default: $defFILELIST"

	echo -e "\n\nExamples:"
	echo -e "\nSync files from directory /tmp/source/ to the local directory /tmp/target/ with\na maximum amount of 1000 images in the target directory, before starting to move\nthe oldest files into the archive directory /tmp/archive/, using /tmp/ifslist as\nfile list:\n"
	echo "\$ $SCRIPTNAME rotated /tmp/source/ /tmp/target/ /tmp/archive/ 1000 /tmp/ifslist"
	# echo -e "\nSync files from directory /tmp/source/ to the remote directory /tmp/target/ of\nhost anduin using the user greylin dated from the 3rd of October, 2018 to the\n17th of October, 2018, using the default value of the file list:\n"
	# echo "\$ $SCRIPTNAME rotated /tmp/source/ greylin@anduin:/tmp/target/ 2018-10-03 2018-10-17"

	exit 0
fi

###############################################
# Parameter evaluation/configuration overrides
###############################################

SCRIPTMODE=${1:-"$defSCRIPTMODE"}
DIRECTORYSRC=${2:-"$defDIRECTORYSRC"}
DIRECTORYDST=${3:-"$defDIRECTORYDST"}
if [[ "$SCRIPTMODE" == "rotated" ]]; then
	DIRECTORYARC=${4:-"$defDIRECTORYARC"}
	ROTATELIMIT=${5:-"$defROTATELIMIT"}
	FILELIST=${6:-"$defFILELIST"}
elif [[  "$SCRIPTMODE" == "dated" ]]; then
	DATESTART=${4:-"$defDATESTART"}
	DATEEND=${5:-"$defDATEEND"}
	FILELIST=${6:-"$defFILELIST"}
else
	echo "critical: Unsupported script mode. Please read the help output ($SCRIPTNAME -h)."

	exit 1
fi

############
# Functions
############

is_command_available_critical() {
	local COMMANDNAME=$1
	hash "$COMMANDNAME" 2>/dev/null || { echo >&2 "critical: Missing command $COMMANDNAME! Aborting ..."; exit 1; }
}

stamp_out() {
	local DATEFMT=$(date +"%F %T.%N")
	echo "$DATEFMT: $*"
}

start_dated() {
	echo " with this date range: $DATESTART - $DATEEND"
	echo "Watching directory '$DIRECTORYSRC', syncing to '$DIRECTORYDST', file list path: '$FILELIST'"

	stamp_out "Starting initial synchronization ..."
	sync_dirs_filtered

	for (( ; ; ))
	do
		# Bail out if we surpassed $DATEEND.
		DATECUR=$(date +"%F")
		if [[ "$DATECUR" > "$DATEEND" ]]; then
			echo "The current date is $DATECUR, we are supposed to monitor until $DATEEND. Time to say goodbye!"
			exit 0
		fi

		# Wait for close_write events up to 14.400 seconds (4 hours), then perform a rsync run anyway.
		inotifywait -qq -e close_write -t 14400 "$DIRECTORYSRC"

		stamp_out "Starting synchronization run ..."
		sync_dirs_filtered
	done
}

start_rotated() {
	echo " with a limit of $ROTATELIMIT images before rotation"
	echo "Watching directory '$DIRECTORYSRC', syncing to '$DIRECTORYDST', archiving to '$DIRECTORYARC', file list path: '$FILELIST'"

	stamp_out "Starting initial synchronization ..."
	sync_dirs_rotated

	# Run until infinity.
	for (( ; ; ))
	do
		# Wait for close_write events up to 14.400 seconds (4 hours), then perform a rsync run anyway.
		inotifywait -qq -e close_write -t 14400 "$DIRECTORYSRC"

		stamp_out "Starting synchronization run ..."
		sync_dirs_rotated
	done
}

sync_dirs_filtered() {
	# Create a filtered file list with relative paths for given date range.
	find "$DIRECTORYSRC" -type f -newermt "$DATESTART" ! -newermt "$DATEEND 23:59:59" -printf '%P\n' > "$FILELIST"

	# -a    archive mode; equals -rlptgoD (no -H,-A,-X)
	#   -r  recurse into directories
	#   -l  copy symlinks as symlinks
	#   -p  preserve permissions
	#   -t  preserve modification times
	#   -g  preserve group
	#   -o  preserve owner
	#   -D  same as --devices --specials
	#       --devices   preserve device files
	#       --specials  preserve special files
	# --files-from=FILE   read list of source-files names from FILE
	# First a dry run is performed to create an usable output of transferred files,
	# using these additional parameters:
	# -n                perform a trial run with no changes made
	# --progress        show progress during transfer
	rsync -ptn --files-from="$FILELIST" --progress "$DIRECTORYSRC" "$DIRECTORYDST"
	rsync -pt --files-from="$FILELIST" "$DIRECTORYSRC" "$DIRECTORYDST"

	rm "$FILELIST"

	stamp_out "Synchronization run is finished! See above for transferred files."
}

sync_dirs_rotated() {
	# Create a filtered file list with relative paths for the last 4 hours.
	find "$DIRECTORYSRC" -type f -newermt "`date -d "4 hour ago" +"%Y-%m-%d %H:%M:%S"`" -printf '%P\n' > "$FILELIST"

	rsync -ptn --files-from="$FILELIST" --progress "$DIRECTORYSRC" "$DIRECTORYDST"
	rsync -pt --files-from="$FILELIST" "$DIRECTORYSRC" "$DIRECTORYDST"

	rm "$FILELIST"

	DSTLIST=`ls -At "$DIRECTORYDST"`
	DSTCOUNT=`echo "$DSTLIST" | wc -l`
	if [[ $DSTCOUNT -gt $ROTATELIMIT ]]; then
		EXCCOUNT=$(($DSTCOUNT - $ROTATELIMIT))

		stamp_out "Limit exceeded by $EXCCOUNT, moving files into the archive directory:"
		echo "$DSTLIST" | tail -n $EXCCOUNT > "$FILELIST"

		rsync -ptn --files-from="$FILELIST" --progress "$DIRECTORYDST" "$DIRECTORYARC"
		rsync -pt --files-from="$FILELIST" --remove-source-files "$DIRECTORYDST" "$DIRECTORYARC"

		rm "$FILELIST"
	fi

	stamp_out "Synchronization run is finished! See above for transferred and/or moved files."
}

################
# Sanity checks
################

# Does the source directory exist?
if [[ ! -d "$DIRECTORYSRC" ]]; then
	echo "critical: The source directory ($DIRECTORYSRC) does not exist! Aborting ..."
	exit 1
fi

# Does the destination directory exist (skipped in case of a remote directory)?
if [[ "$DIRECTORYDST" != *":"* ]]; then
	if [[ ! -d "$DIRECTORYDST" ]]; then
		echo "critical: The destination directory ($DIRECTORYDST) does not exist! Aborting ..."
		exit 1
	fi
fi

# Is $DATEEND greater or equal $DATESTART?
if [[ "$DATESTART" > "$DATEEND" ]]; then
	# We use the fact that dates in the YYYY-MM-DD format are compared
	# chronological, that's why we don't parse them with date.
	echo "critical: The beginning of the date range ($DATESTART) is greater than the end ($DATEEND)! Aborting ..."
	exit 1
fi

# Do we have all needed tools to go on?
is_command_available_critical date
is_command_available_critical find
is_command_available_critical inotifywait
is_command_available_critical ls
is_command_available_critical rm
is_command_available_critical rsync
is_command_available_critical tail
is_command_available_critical wc

####################
# The actual script
####################

echo "$SCRIPTNAME v$STAMP initialized!"

printf "Running in mode '$SCRIPTMODE'"

if [[ "$SCRIPTMODE" == "rotated" ]]; then
	start_rotated
elif [[  "$SCRIPTMODE" == "dated" ]]; then
	start_dated
else
	echo "critical: Very late discovery of unsupported script mode. Please read the help output ($SCRIPTNAME -h)."

	exit 1
fi
