#!/bin/bash

function userExists() {
	local username="$1"
	id -u "$username" 1>/dev/null 2> /dev/null
	if [ $? -eq 0 ]; then
		return 0
	else
		return 1
	fi

}
function groupExists() {

	local groupname="$1"
	if [ $(getent group $groupname) ]; then
		return 0
	else
		return 1
	fi
}

function makeUserPair() { # $1 should be username
	local username=$1
	userExists $username
	if [ $? -eq 0 ]; then
	  echo "OK: $username exists"
	else
	  adduser  --disabled-password  --quiet --gecos "" $username 
	  echo "OK: Created user $username"
	fi
	userExists "$username-ro"
	if [ $? -eq 0 ]; then
	  echo "OK: $username-ro exists"
	else
	  adduser  --disabled-password  --quiet --gecos "" --ingroup $username  $username-ro
	  echo "OK: Created user $username-ro"
	fi
	if [ ! -d "/home/$username/repos" ]; then
		mkdir /home/$username/repos
		chown $username:$username /home/$username/repos
		chmod o-rwx /home/$username/repos
		echo "OK: Created homedir repos"
	fi

	if [ ! -L /home/$username-ro/repos ]; then
		ln -s /home/$username/repos /home/$username-ro/repos;
		echo "OK: Created symlink for $username-ro"
	fi

}
function makeReadWriteAuthFile(){
	local username=$1
	if [ ! -d /home/$username/.ssh ]; then
		echo "OK: Created SSH dir"
		mkdir /home/$username/.ssh
	fi
	echo "OK: Setup perms on .ssh dir"
	chown $username:$username /home/$username/.ssh
	chmod go-rwx /home/$username/.ssh
	if compgen -G "$username/readwrite/*.key" > /dev/null; then
		echo "OK: creating authorized_keys file"	
		cat $username/readwrite/*.key > /home/$username/.ssh/authorized_keys
		chmod go-rwx /home/$username/.ssh/authorized_keys
		chown $username:nogroup /home/$username/.ssh/authorized_keys
	else
		if [ -f /home/$username/.ssh/authorized_keys ]; then
			echo "OK: No keys for $username so removing authorized_keys file"
			rm /home/$username/.ssh/authorized_keys
		fi
	fi
}

function makeReadOnlyAuthFile(){
	local username=$1
	if [ ! -d /home/$username-ro/.ssh ]; then
		echo "OK: Created SSH dir"
		mkdir /home/$username-ro/.ssh
	fi
	echo "OK: Setup perms on .ssh dir"
	chown $username-ro:nogroup /home/$username-ro/.ssh
	chmod go-rwx /home/$username-ro/.ssh

	if compgen -G "$username/readonly/*.key" > /dev/null; then
		echo "OK: creating authorized_keys file"	
		cat $username/readonly/*.key > /home/$username-ro/.ssh/authorized_keys
		chmod go-rwx /home/$username-ro/.ssh/authorized_keys
		chown $username-ro:nogroup /home/$username-ro/.ssh/authorized_keys
	else
		if [ -f /home/$username-ro/.ssh/authorized_keys ]; then
			echo "OK: No keys for $username-ro so removing authorized_keys file"
			rm /home/$username-ro/.ssh/authorized_keys
		fi
	fi
}
containsElement () {
	local needle=$1
	local haystack=$2
	for item in ${haystack[*]}; do 
		if [[ "$item" = "$needle" ]]; then
		        return 0; 
		fi
	done
	return 1
}
function removeUser() {
	local user=$1
	if [ -d /home/$user ]; then
		if [ ! -d /root/archivedusers ] ; then
			mkdir /root/archivedusers
		fi
		echo "OK: moving /home/$user to /root/archivedusers/";
		mv /home/$user /root/archivedusers
		if [ $? -eq 0 ]; then
			echo "NOT OK!!!"
		fi
	fi
	userExists $user
	if [ $? -eq 0 ]; then
		deluser --force $i 2>/dev/null
	fi
}
function removeGroup () {
	local group=$1
	groupExists $group
	if [ $? -eq 0 ]; then
		echo "removing group $group"
		delgroup --only-if-empty $group
	else
		echo "group $group doesn't exist apparently"
	fi
}
function removeUsers() {
	local userlist=$1
	local OLDPWD=`pwd`
	cd /home
	for i in *; do
		local bareusername=$i
		if [ ${bareusername: -3:3} = '-ro' ] ; then
			local username=${bareusername%???}
		else
			local username=$bareusername
		fi
	
		containsElement $username "${userlist[*]}"
		if [ $? -eq 1 ]; then
			removeUser $bareusername
			removeUser $username
			removeGroup $username
		fi
	done
	cd $OLDPWD
}

function setupFromConfig() {
	local OLDPWD=`pwd`
	if [ -d config ]; then
		cd config;
		for i in *; do
			makeUserPair $i
			makeReadWriteAuthFile $i
			makeReadOnlyAuthFile $i
		done
		sleep 3
		userlist=(*)
		removeUsers "${userlist[*]}"
	fi
	cd $OLDPWD
}
setupFromConfig
