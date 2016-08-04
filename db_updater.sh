#!/usr/bin/env bash

# Execute Queries for update.
#
# SQL Query File name format: [version number (BIGINT)][ |-|.|_|,|#|\|][Query description][.sql]
#
# For more help, execute this file into a Terminal without parameters.
#
# Version: 1.0
# URL: https://github.com/reduardo7/db-version-updater
#
# Eduardo Cuomo | eduardo.cuomo.ar@gmail.com


# Test if running with "bash" interpreter
if [ "$BASH" = "" ] ; then
    # Run with "bash"
    bash "$0" $@
    exit $?
fi

# DB config
DB_USER="USER"
DB_PASS="PASS"
DB_NAME="DB_NAME"
DB_HOST="localhost"
DB_TABLE="DB_VERSION"
DB_CHARSET="latin1"
DB_PORT="3306"


# DB status
DB_STATUS_EXECUTING="EXECUTING"
DB_STATUS_EXECUTED="EXECUTED"
DB_STATUS_ERROR="ERROR"

# Arguments
ARG_UPDATE="update"
ARG_CREATE="create"
ARG_MARK_UPDATED="mark-updated"
ARG_DELETE="delete"
ARG_STATUS="status"
ARG_SET_OK="set-ok"

# File format
CHAR_SEP_P="\ \_\,\|\#\.\-"
FILE_NAME_FORMAT="[version number (BIGINT)][${CHAR_SEP_P}][Query description][.sql]"

# Vars
CURRENT_DIR="$(printf '%q' "$(pwd)")"
DIR_NAME="$(dirname "$(printf '%q' "$(readlink -f "$(printf '%q' "$0")")")")"
result=""
br="
"

# Exit
function ex() {
	echo
	echo "cd $CURRENT_DIR"
	cd $CURRENT_DIR
	echo
	exit $1
}

# Escape String
function escape_string() {
	result=$(printf '%q' "$1")
}

# echo
function e() {
	echo "| $1"
}

# echo line
function e_l() {
	let fillsize=80
	fill="+"
	while [ "$fillsize" -gt "0" ] ; do
		fill="${fill}-" # fill with underscores to work on
		let fillsize=${fillsize}-1
	done
	echo $fill
}

# echo exit
function e_e() {
	e "$1"
	e_l
	ex 1
}

# Show help
function show_help() {
	escape_string "$0"
	script="$result"
	e "Help (this):"
	e "	# bash $script"
	e "	# bash $script --help"
	e
	e
	e "To use rollback on error, tables must be transactional (InnoDB)."
	e "Use next query to set as InnoDB tables:"
	e "    ALTER TABLE \`TABLE_NAME\` ENGINE = INNODB;"
	e
	e
	e "The SQL files names must have the next format:"
	e "	${FILE_NAME_FORMAT}"
	e "File name examples:"
	e "	0001. Query description.sql"
	e "	0002 - Query description 2.sqL"
	e "	3 Query description 3.Sql"
	e "	04, Query description 4.sQl"
	e "	05_Query description 5.SQL"
	e "	20100617-Query description with date as version number.sql"
	e "	201006170105#Query description with date and time as version number.sql"
	e "	00017|Other Query description.sql"
	e "	00017#Other Query description.sql"
	e
	e
	e "Usage: bash $script [OPTIONS] ACTION [EXTRA]"
	e
	e "OPTION:"
	e "-u, --user     Set DB user name to use."
	e "               Using: '$DB_USER'"
	e "-p, --pass     Set DB password to use."
	e "               Using: '$DB_PASS'"
	e "-d, --db       Set DB name to use."
	e "               Using: '$DB_NAME'"
	e "-h, --host     Set DB host to use."
	e "               Using: '$DB_HOST'"
	e "-P, --port     Set DB host port to use."
	e "               Using: '$DB_PORT'"
	e "--help         This help."
	e
	e "ACTION:"
	e "$ARG_STATUS         Show status."
	e "               Uses:"
	e "                 # bash $script $ARG_STATUS"
	e "$ARG_UPDATE         Execute update."
	e "               NOTE: Transaction rollback on MySQL error."
	e "$ARG_CREATE         Create a SQL file to mark all files as executed."
	e "               Uses:"
	e "                 # bash $script $ARG_CREATE [OUT FILE NAME]"
	e "                 # bash $script $ARG_CREATE \"out_file_name.sql\""
	e "                 # bash $script $ARG_CREATE \"0. Mark executed to version X.sql\""
	e "               TIP: You can use version '0' to execute before others already executed files."
	e "$ARG_MARK_UPDATED   Mark all files as executed without execute files."
	e "               Uses:"
	e "                 # bash $script $ARG_MARK_UPDATED"
	e "$ARG_SET_OK         Set VERSION as '$DB_STATUS_EXECUTED'."
	e "               Uses:"
	e "                 # bash $script $ARG_SET_OK VERSION"
	e "                 # bash $script $ARG_SET_OK 1234"
	e "$ARG_DELETE         Delete changelog by VERSION"
	e "               Uses:"
	e "                 # bash $script $ARG_DELETE VERSION"
	e "                 # bash $script $ARG_DELETE 1234"
	e_e
}

# Begin
echo
echo "cd $DIR_NAME"
echo
e ":: DB Updater ::"
cd $DIR_NAME
e_l

# No parameters
if [ $# -eq 0 ] ; then
	show_help
fi

# Options
TMP=`getopt --name="$0" -a --longoptions=user:,pass:,db:,host:,port:,help -o u:,p:,d:,h:,P -- $@`
if [ $? -ne 0 ] ; then
	# Invalid option
	e
	e "Error! Invalid parameters!"
	e
	show_help
fi
eval set -- $TMP

until [ $1 == -- ]; do
	case $1 in
		-u|--user)
			DB_USER=$2
			;;
		-p|--pass)
			DB_PASS=$2
			;;
		-d|--db)
			DB_NAME=$2
			;;
		-h|--host)
			DB_HOST=$2
			;;
		-P|--port)
			DB_PORT=$2
			;;
		--help)
			show_help
			;;
	esac
	shift # move the arg list to the next option or '--'
done
shift # remove the '--', now $1 positioned at first argument if any

# Query: Execute query
function q_e() {
	mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} ${DB_NAME} -e "$1"
	return $?
}

# Read version from file name
function read_version() {
	result=$(echo "$1" | sed "s/[${CHAR_SEP_P}].*$//" | sed "s/^0*//g")
	if [[ "$result" = "" ]] ; then
		result=0
	fi
	# Check integer
	if [[ $result =~ ^[^0-9]+$ ]] ; then
		e "File name format:"
		e " ${FILE_NAME_FORMAT}"
		e_e "The file '$1' not contains a Version number as start name."
	fi
}

# Read description from file name
function read_description() {
	result=$(echo "$1" | sed "s/[^\d${CHAR_SEP_P}]*//" | sed "s/\.sql.*$//i" | sed "s/^[${CHAR_SEP_P}]*//g")
}

# Create table if not exists
function create_table() {
	q_e "CREATE TABLE IF NOT EXISTS \`${DB_TABLE}\` (\`version\` BIGINT NOT NULL, \`description\` varchar(255) NOT NULL, \`file_name\` varchar(255) NOT NULL, \`executed_date\` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, \`status\` VARCHAR(10) NOT NULL DEFAULT '${DB_STATUS_EXECUTING}' COMMENT '${DB_STATUS_EXECUTING}; ${DB_STATUS_EXECUTED}; ${DB_STATUS_ERROR}', PRIMARY KEY (\`version\`)) ENGINE=InnoDB DEFAULT CHARSET=latin1"
    if [ $? -ne 0 ]; then
        e_e "[ERROR CODE 7001] QUERY ERROR! mysql exit code: $?"
    fi
	e "Connected to ${DB_USER}@${DB_HOST}.${DB_NAME}"
	e_l
}

# Read file data
file_name=""
file_nameq=""
version=""
versionq=""
desc=""
descq=""
function read_file_data() {
	file_name="$1"
	# File name
	escape_string "$file_name" ; file_nameq=$result
	e "File:         $file_name"
	# Version
	read_version "$file_name" ; version=$result
	escape_string $version ; versionq=$result
	e "Version:      $version"
	# Description
	read_description "$file_name" ; desc=$result
	escape_string "$desc" ; descq=$result
	e "Description:  $desc"
}

# Update DB
if [ "$1" = "${ARG_UPDATE}" ] ; then
	# Update
	e "Updating DB ${DB_HOST}@${DB_NAME}..."
	e_l

	# Create table if not exists
	create_table

	# Begin
	for file in *.sql ; do
		if [[ "$file" =~ ^[0-9]+[${CHAR_SEP_P}]+.+\.[sS][qQ][lL]$ ]] ; then
			read_file_data "$file"

			# Check
			q_e "DELETE FROM \`${DB_TABLE}\` WHERE \`version\` = ${version} AND \`status\` = '${DB_STATUS_ERROR}'"
			q_e "INSERT INTO \`${DB_TABLE}\` (\`version\`, \`description\`, \`file_name\`, \`status\`) VALUES (${version}, '$descq', '$file_nameq', '${DB_STATUS_EXECUTING}')" &> /dev/null

			if [ $? -ne 0 ]; then
				# Already executed
				e "* Already executed."
			else
				e "* Executing update..."
				# Prepare query
				update_query=$(cat "$file")
				update_query="SET SQL_MODE=\"NO_AUTO_VALUE_ON_ZERO\"; SET AUTOCOMMIT=0; START TRANSACTION;
-- BEGIN UPDATE

$update_query ;

-- END UPDATE
COMMIT;"
				query_executed="UPDATE \`${DB_TABLE}\` SET \`status\` = '${DB_STATUS_EXECUTED}' WHERE \`version\` = ${version}"
				# Execute query file
				#mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} --default-character-set=${DB_CHARSET} ${DB_NAME} < "$file"
				mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} --default-character-set=${DB_CHARSET} ${DB_NAME} <<< "$update_query"
				exc=$?
				if [ $exc -ne 0 ]; then
					e
					q_e "UPDATE \`${DB_TABLE}\` SET \`status\` = '${DB_STATUS_ERROR}' WHERE \`version\` = ${version}"
					e "[ERROR CODE 7003] QUERY ERROR! mysql exit code: $exc"
					e "QUERY:${br}${br}$update_query${br}"
					e
					e "Mark this script as executed:"
					e_e "$ bash $0 $ARG_SET_OK $version"
				fi
				# Ok
				q_e "$query_executed"
				e "Query executed!"
			fi
			e_l
		else
			e "Skip file: $file"
		fi
	done

	# Finish!
	e "DB ${DB_HOST}@${DB_NAME} updated!"
	e_l

	echo
	echo
	echo "Finish!"
	ex 0
fi

# Mark all files as executed without execute files
if [ "$1" = "${ARG_MARK_UPDATED}" ] ; then
	# Update
	e "Marking as updated DB ${DB_HOST}@${DB_NAME}..."
	e_l

	# Create table if not exists
	create_table

	# Begin
	for file in *.sql ; do
		if [[ "$file" =~ ^[0-9]+[${CHAR_SEP_P}]+.+\.[sS][qQ][lL]$ ]] ; then
			read_file_data "$file"

			# Check
			q_e "DELETE FROM \`${DB_TABLE}\` WHERE \`version\` = ${version} AND \`status\` = '${DB_STATUS_ERROR}'"
			q_e "INSERT INTO \`${DB_TABLE}\` (\`version\`, \`description\`, \`file_name\`, \`status\`) VALUES (${version}, '$descq', '$file_nameq', '${DB_STATUS_EXECUTING}')" &> /dev/null

			if [ $? -ne 0 ]; then
				# Already executed
				e "* Already executed."
			else
				# Mark as executed
				e "* Marking as updated..."
				query_executed="UPDATE \`${DB_TABLE}\` SET \`status\` = '${DB_STATUS_EXECUTED}' WHERE \`version\` = ${version}"
				q_e "$query_executed"
				e "Query executed!"
			fi
			e_l
		fi
	done

	# Finish!
	e "DB ${DB_HOST}@${DB_NAME} marked as updated!"
	e_l

	echo
	echo
	echo "Finish!"
	ex 0
fi

# Set Ok Version
if [ "$1" = "${ARG_SET_OK}" ] ; then
	version="$2"
	[ -z "$version" ] && e_e "Error! Version is required"
	e "Setting Version ${version} as '$DB_STATUS_EXECUTED'..."
	e_l

	# Create table if not exists
	create_table

	# Update
	q="UPDATE \`${DB_TABLE}\` SET \`status\` = '$DB_STATUS_EXECUTED' WHERE \`version\` = ${version}"
	e "$q"
	q_e "$q"

	# Finish!
	e "DB ${DB_HOST}@${DB_NAME} version ${version} is ${DB_STATUS_EXECUTED}!"
	e_l

	echo
	echo
	echo "Finish!"
	ex 0
fi

# Delete Version
if [ "$1" = "${ARG_DELETE}" ] ; then
	version="$2"
	[ -z "$version" ] && e_e "Error! Version is required"
	e "Deleting Version ${version}..."
	e_l

	# Create table if not exists
	create_table

	# Delete
	q="DELETE FROM \`${DB_TABLE}\` WHERE \`version\` = ${version}"
	e "$q"
	q_e "$q"

	# Finish!
	e "DB ${DB_HOST}@${DB_NAME} version ${version} deleted!"
	e_l

	echo
	echo
	echo "Finish!"
	ex 0
fi

# Status
if [ "$1" = "${ARG_STATUS}" ] ; then
	e "Show Status"
	e_l

	# Create table if not exists
	create_table

	# COUNT
	q="SELECT COUNT(*) AS COUNT FROM \`${DB_TABLE}\`"
	e "$q"
	q_e "$q"
	e_l
	# SELECT
	q="SELECT * FROM \`${DB_TABLE}\`"
	e "$q"
	q_e "$q"

	# Finish!
	e_l

	echo
	echo
	echo "Done!"
	ex 0
fi

# Create start status file
if [ "$1" = "${ARG_CREATE}" ] ; then
	if [ $# -eq 2 ] ; then
		file_out="$2"
		e "Creating '$file_out' file..."
		e_l

		# Create out file
		echo "INSERT INTO \`${DB_TABLE}\` (\`version\`, \`description\`, \`file_name\`, \`status\`) VALUES" > "$file_out"
		flag=1

		for file in *.sql ; do
			if [[ "$file" =~ ^[0-9]+[${CHAR_SEP_P}]+.+\.[sS][qQ][lL]$ ]] ; then
				if [ "$file" != "$file_out" ] ; then
					read_file_data "$file"

					query=$(echo "(${versionq}, '${descq}', '${file_nameq}', '${DB_STATUS_EXECUTED}')")

					# Add query
					if [ $flag -ne 1 ] ; then
						query=", $query"
					else
						flag=0
					fi
					echo "$query" >> "$file_out"

					e_l
				fi
			fi
		done

		echo ";" >> "$file_out"

		# End
		e "'$file_out' file created!"
		e_l

		echo
		echo
		echo "Finish!"
		ex 0
	fi
fi

# Invalid ACTION
e "INVALID ACTION!"
e_l
show_help
