#!/bin/bash

###################################################################
#
#	Create user acounts on Linux
#
###################################################################
#
#  Script created by Damien PIQUET: damien.piquet@iutbeziers.fr || piqudam@gmail.com
#
#  Add users listed in users.lst and add public key in from <login>.pub in .ssh directory
#

# Default values
export loginShell="/bin/bash"
export passwdFile='/etc/passwd'
export shadowFile='/etc/shadow'
export groupFile='/etc/group'
export homePath='/home'
export membersFile="./users.lst"
export keyDir="."

export userID=1000
export groupID=1000

export ret_err=1
export ret_ok=0

function create_account() {

    if [ $# -ne 1 ]; then
        echo "ERROR in create_account function usage !"
	return $ret_err;
    fi

    userCreated=1
    groupCreated=1

    # initialized at 9999 because 0 is root's userid /!\
    curUserId=9999
    curGroupId=9999

    userName=$1

    # Do not add duplicate users !!
    grep $userName $passwdFile
    if [ $? -eq 0 ]; then
	echo "ERROR, user $userName already exists !!! Skipping..."
	return $ret_err;
    fi

    # /etc/passwd entry
    while [ $userCreated -ne 0 ]
    do
	grep $userID $passwdFile
	if [ $? -eq 1 ]; then
	    echo "$userName:x:$userID:65534::/home/$userName:$loginShell" >> $passwdFile
	    userCreated=0;
            curUserId=$userID
	    ((++userID));
	else	
	    ((++userID));
	fi
    done

    # Shadow entry
    echo "$userName:*:15811:0:99999:7:::" >> $shadowFile

    # do not create duplicate groups !!
    # skip creation if group already exists
    grep $userName $groupFile
    if [ $? -eq 0 ]; then
	echo "Warning ! group $userName already exists !"
    else

        # /etc/group entry
        while [ $groupCreated -ne 0 ]
        do
	    grep $groupID $groupFile
	    if [ $? -eq 1 ]; then
	        echo "$userName:x:$groupID:$userName" >> $groupFile
	        groupCreated=0
		curGroupId=$groupID
		((++groupID));
	    else
	        ((++groupID));
	    fi
        done;
    fi

    # home and .ssh directory
    mkdir $homePath/$userName
    if [ $? -ne 0 ]; then
	echo "ERROR, Could not create $userName home directory !"
	return $ret_err;
    fi

    mkdir $homePath/$userName/.ssh
    if [ $? -ne 0 ]; then
	echo "ERROR, Could not create $userName .ssh directory !"
	return $ret_err;
    fi

    cat $keyDir/$userName.pub > $homePath/$userName/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
	echo "ERROR, Could not create authorized_ key file for $userName !"
	return $ret_err;
    fi

    chmod 600 $homePath/$userName/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
        echo "WARNING, could not change $userName's authorized key file permission !";
    fi

    chmod 700 $homePath/$userName/.ssh
    if [ $? -ne 0 ]; then
	echo "WARNING, could not change $userName's .ssh directory permission !";
    fi

    chown -R $curUserId:$curGroupId $homePath/$userName
    if [ $? -ne 0 ]; then
	echo "WARNING, chown operation $curUserId:$curGroupId on $userName home directory failed !"
    fi

    echo "$userName added to system"
    return $ret_ok
}

function show_usage() {
    echo "Usage: ./$0 [-h --home /home] [-s --shadow-file /etc/shadow]"
    echo "[-g --group-file /etc/group] [-l --login-shell /bin/bash]"
    echo "[-p --passwd-file /etc/passwd] [-f --user-file users.lst]"
    echo "[-u --uid 1000] [-g --gid 1000]"

    return $ret_ok
}

# Retrieve parameters
while test $# -gt 0; do
    case "$1" in
        -h|--home)
	    shift
	    homePath=$1
	    shift
	    ;;
        -s|--shadow-file)
	    shift
	    shadowFile=$1
	    shift
	    ;;
        -g|--group-file)
	    shift
	    groupFile=$1
	    shift
	    ;;
        -l|--login-shell)
	    shift
	    loginShell=$1
	    shift
	    ;;
        -p|--passwd-file)
	    shift
	    passwdFile=$1
	    shift
	    ;;
        -f|--user-file)
	    shift
	    membersFile=$1
	    shift
	    ;;
        -k|--key-dir)
            shift
            keyDir=$1
            shift
            ;;
        -u|--uid)
	    shift
	    userID=$1
	    shift
	    ;;
        -g|--gid)
	    shift
	    groupID=$1
	    shift
	    ;;
        --help)
            shift
            show_usage
            exit $ret_ok
            ;;
        *)
            echo "$1 is not a valid parameter"
	    show_usage
	    exit $ret_err
	   ;;
    esac
done

# Verify required file exists
if [ ! -f $passwdFile ]; then	
    echo "ERROR, $passwdFile does not exists ! Aborting..."
    exit $ret_err;
fi

if [ ! -f $shadowFile ]; then
    echo "ERROR, $shadowFile does not exists ! Aborting..."
    exit $ret_err;
fi

if [ ! -f $groupFile ]; then
    echo "ERROR, $groupFile does not exists ! Aborting..."
    exit $ret_err;
fi

if [ ! -f $membersFile ]; then
    echo "ERROR, $membersFile does not exists ! Aborting..."
    exit $ret_err;
fi

if [ ! -d $homePath ]; then
    echo "ERROR, directory $homePath does not exists ! Aborting..."
    exit $ret_err;
fi

# Read users file
while read line
do
    create_account "$line"
done < $membersFile

echo "Users added to system !"

