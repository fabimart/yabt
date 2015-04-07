#
# yabt.sh
#
# Description:
# Common routines used by all yabt-XXXX.sh
#
# History:
# 18/07/2014 - Fabiano Martins - Initial version
# 23/03/2015 - Fabiano Martins - Accept YABT_TMP_DIR to define temporary
#                                directory and YABT_COMPRESS_OPTION to
#                                extra optons. In addition to it, uses
#                                parallel version of gz, xz or bzip2 if
#                                available.

unset POSIXLY_CORRECT

trap 'yabt_trap_err ${LINENO} $?' ERR

unset YABT_MSG_ERR

YABT_DEFAULT_CONF_FILE="/etc/yabt/$(basename $0 .sh).conf"

# Override as needed, for example "ldif" for LDAP dumps
YABT_DUMP_EXTENSION="sql"

yabt_run()
{
	if [ ! -z "$1" ]; then
		ARRAY_SIZE=$(eval echo \${#$1[*]})
		POS=0           
		for (( POS=0; POS<$ARRAY_SIZE; POS++ )); do
			COMMAND="$(eval echo \${$1[$POS]})"
			$COMMAND
		done
	fi
}

yabt_trap_err()
{
	MYSELF="$0"              # equals to my script name
	LASTLINE="$1"            # argument 1: last line of error occurrence
	LASTERR="$2"             # argument 2: error code of last command

	trap - ERR
	
	if [ -z "${YABT_MSG_ERR}" ] ; then
		yabt_abort "execution error at line ${LASTLINE} of ${MYSELF} (exit code ${LASTERR}) : aborting..." "${LASTERR}"
	else
		yabt_abort "${YABT_MSG_ERR} fails (exit code ${LASTERR}) : aborting..." "${LASTERR}"
	fi

	if [ ! -z "${PARM_V}" ] ; then
		echo "unsafe finished as fail at $(date)..."
	fi
}

yabt_abort() {
	PARM_MSG="$1"

	# If nor receive exit code as parameter, assumes "1"
	PARM_EXIT="${2:-1}"

	# If POST_FAIL execution script was defined, run it
	yabt_run YABT_RUN_POST_FAIL

	# Remove temporary file at exit
	if [ ! -z "${YABT_TMP_FILE}" ] ; then
		rm -f "{YABT_TMP_FILE}"
	fi

	if [ ! -z "${PARM_MSG}" ] ; then
		echo "${PARM_MSG}" 1>&2
	fi

	if [ ! -z "${PARM_V}" ] ; then
		echo "finished as fail at $(date)..."
	fi

	exit ${PARM_EXIT}
}

yabt_abort_default() {
	yabt_abort "error $1 at $2 : aborting..."
}

yabt_abort_syntax()
{
	if [ ! -z "$*" ] ; then
		echo "$*" 1>&2
	fi
	echo ""
	echo "syntax: $0 [-c DEFAULT_CONF_FILE] [-v], where" 1>&2
	echo "-c : configuration file to use (defaults to \"${YABT_DEFAULT_CONF_FILE}\")" 1>&2
	echo "-v : verbose mode" 1>&2
	echo "" 1>&2
	yabt_abort
	exit 1
}

yabt_compress() {

	YABT_COMPRESS_CMD=""

	# Only for informational purpose, compression result of a sample MySQL dump
	# of 36M (36760517 bytes) with each technique on maximum compression:
	# - xz (with xz) : 32s, 3.0Mb (3071944 bytes)
	# - xz (with pxz): 28s, 3.0Mb (3071944 bytes)
	# - bz2..........: 11s, 3.9Mb (3986961 bytes)
	# - gz...........:  6s, 5.0Mb (5199968 bytes)
	case "${YABT_COMPRESS}" in
		"")	YABT_COMPRESS_CMD="cat"
		;;
		"xz")	if type -p pxz > /dev/null ; then
				YABT_COMPRESS_CMD="pxz -z"
			else
				YABT_COMPRESS_CMD="xz -z"
			fi
		;;
		"bz2")	if type -p lbzip2 > /dev/null ; then
				YABT_COMPRESS_CMD="lbzip2"
			elif type -p pbzip2 > /dev/null ; then
				YABT_COMPRESS_CMD="pbzip2"
			else
				YABT_COMPRESS_CMD="bzip2"
			fi
		;;
		"gz")	if type -p pigz > /dev/null ; then
				YABT_COMPRESS_CMD="pigz"
			else
				YABT_COMPRESS_CMD="gzip"
			fi
		;;
		*)	echo "invalid YABT_COMPRESS option: \"${YABT_COMPRESS}\""
			exit 1
		;;
	esac

	# Appends extra options
	if [ ! -z "${YABT_COMPRESS}" ] ; then
		YABT_COMPRESS_CMD="${YABT_COMPRESS_CMD} ${YABT_COMPRESS_OPTION:--9}"
	fi

	${YABT_COMPRESS_CMD} > "$1"
}

# If backup dir does not exist, create it
yabt_make_backup_dir() {
	if [ ! -d "${YABT_DEST_DIR}" ] ; then
		YABT_MSG_ERR="backup dir creation"
		mkdir -p "${YABT_DEST_DIR}"
		unset YABT_MSG_ERR
	fi
}

# Make temporary file where dumps will be saved
YABT_MSG_ERR="temporary file creation"
if [ -z "${YABT_TMP_DIR}" ] ; then
	YABT_TMP_FILE="$(mktemp yabt-XXXXXX.tmp)"
else
	YABT_TMP_FILE="$(mktemp --tmpdir=${YABT_TMP_DIR} yabt-XXXXXX.tmp)"
fi
unset YABT_MSG_ERR

# Treatment of the parameters
PARM_C="${YABT_DEFAULT_CONF_FILE}"
while getopts ':c:v' OPTION
do
    case "${OPTION}" in
	"v")	PARM_V="v"
	;;
        "c")	PARM_C="${OPTARG}"
        ;;
        "?")	yabt_abort_syntax "Unrecognized option: -${OPTARG}"
	;;
        :  )	yabt_abort_syntax "Missing argument for option -${OPTARG}"
	;;
        *  )	yabt_abort_syntax "Internal error : option -${OPTARG} not implemented"
	;;
    esac
done

# Load configurations
if [ ! -e "${PARM_C}" ] ; then
	yabt_abort "configuration file \"${PARM_C}\" not found"
fi
YABT_MSG_ERR="configuration file load"
. "${PARM_C}"
unset YABT_MSG_ERR

if [ ! -z "${PARM_V}" ] ; then
	echo "started at $(date)..."
fi

# If PRE execution script was defined, run it
yabt_run YABT_RUN_PRE

# Make the backup dir if needed
yabt_make_backup_dir

# Yabt custom initialization (plugin specific)
yabt_init

# Get list of databases (plugin specific)
YABT_DATABASES=( )
while read YABT_DATABASE; do
	YABT_DATABASES+=" ${YABT_DATABASE}"
done < <(yabt_list_databases)

# Set temporary file timestamp to ${YABT_OLDFILES_MAX_DAYS} days old: it is necessary to compare with actual backups
YABT_MSG_ERR="timestamp test on temporary file"
touch -d "-${YABT_OLDFILES_MAX_DAYS}day" "${YABT_TMP_FILE}"
unset YABT_MSG_ERR

# Loop to actual backups, and remove that no more exists on DB and have more than ${YABT_OLDFILES_MAX_DAYS} days old
find "${YABT_DEST_DIR}" -type f | while read FILE ; do
	if [ -z "${YABT_COMPRESS}" ] ; then
		YABT_DATABASE="$(echo ${FILE#${YABT_DEST_DIR}/} | sed "s/\.${YABT_DUMP_EXTENSION}$//")"
	else
		YABT_DATABASE="$(echo ${FILE#${YABT_DEST_DIR}/} | sed "s/\.${YABT_DUMP_EXTENSION}\.${YABT_COMPRESS}$//")"
	fi
	if echo ${YABT_DATABASES} | fgrep -q "-e${YABT_DATABASE}" ; then
		if [ ! -z "${PARM_V}" ] ; then
			echo "database '${YABT_DATABASE}' exists on DB: keeping backup file '${FILE}'"
		fi
	else
		if [ "${FILE}" -nt "${YABT_TMP_FILE}" ] ; then
			echo "database '${YABT_DATABASE}' no more exists on DB, but are newer than ${YABT_OLDFILES_MAX_DAYS} days old: keeping for now..."
		else
			echo "database '${YABT_DATABASE}' no more exists on DB, and have more than ${YABT_OLDFILES_MAX_DAYS} days old: deleting..."
			YABT_MSG_ERR="remove file '${FILE}'"
			rm -f "${FILE}"
			unset YABT_MSG_ERR
		fi
	fi
done

# Loopa para todos databases identificados
if [ -z "${YABT_DUMP_EXTENSION}" ] ; then
	yabt_abort "YABT_DUMP_EXTENSION undefined"
fi
for YABT_DATABASE in ${YABT_DATABASES[@]} ; do

	# Skips desireds databases
	if ! echo ${YABT_SKIP_DATABASES} | grep -q "${YABT_DATABASE}" ; then

		if [ ! -z "${PARM_V}" ] ; then
			echo "dumping database '${YABT_DATABASE}'..."
		fi

		# Makes compressed dump compactado on temporary file
		YABT_MSG_ERR="database ${YABT_DATABASE} dump"
		yabt_dump_database ${YABT_DATABASE} | yabt_compress "${YABT_TMP_FILE}"
		unset YABT_MSG_ERR

		# Compares generated dump  o dump gerado com o ultimo backup, e atualiza se estiver diferente
		if [ -z "${YABT_COMPRESS}" ] ; then
			YABT_BACKUP_FILE="${YABT_DEST_DIR}/${YABT_DATABASE}.${YABT_DUMP_EXTENSION}"
		else
			YABT_BACKUP_FILE="${YABT_DEST_DIR}/${YABT_DATABASE}.${YABT_DUMP_EXTENSION}.${YABT_COMPRESS}"
		fi
		if ! cmp -s "${YABT_TMP_FILE}" "${YABT_BACKUP_FILE}" ; then
			if [ ! -z "${PARM_V}" ] ; then
				echo "backup of database '${YABT_DATABASE}' changed: updating..."
			fi
			YABT_MSG_ERR="move dump of database '${YABT_DATABASE}' to backup '${YABT_BACKUP_FILE}'"
			mv "${YABT_TMP_FILE}" "${YABT_BACKUP_FILE}"
			unset YABT_MSG_ERR
		else
			if [ ! -z "${PARM_V}" ] ; then
				echo "backup of database '${YABT_DATABASE}' unchanged: skipping..."
			fi
		fi
	fi
done

rm -f "${YABT_TMP_FILE}"


# If POST_SUCCESS execution script was defined, run it
yabt_run YABT_RUN_POST_SUCCESS

if [ ! -z "${PARM_V}" ] ; then
	echo "finished as success at $(date)..."
fi

