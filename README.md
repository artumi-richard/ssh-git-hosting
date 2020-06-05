# Bare git hosting

This project is not ready yet! I've not really tested it thoroughly!

The goals of this project are

1) The box hosting the repositories only needs to run ssh
2) There are different user permissions available on repositories.
   Specifically, we need to support deploy keys. So a key for clientA
   on server A1 can only access the repos for clientA in a readonly
   way. Client B would not be able to see that data.
3) It must import from gitlab backups   
			
## Install

1. Create a new server.
2. Clone this repo onto it. 
3. Create a config directory (see below).
4. In `/etc/skel/.profile` add the line : `umask 027`
5. Run setup-server-from-config.sh 
 
			
## Config 

Create a folder called "keys/" and enter all the public keys you have
named so you know what they are. richard.key, server1.key etc.

If you want a repo that is related to client A that richard can access
as a read-write repo, but server1.key is a deploy only key, so that is
read-only you would add a structure like this
```
config/
  clientA/ -- no spaces!
  	readonly
		server1.key
	readwrite
		richard.key
```
The setup-server-from-config.sh will read this structure, create all
the useraccounts (without passwords) and set the groups correctly for
each user. It will move folders that aren't there anymore to
`/root/archivedusers` and will not delete data.

It will setup the correct .ssh/authorized_keys file

## Repo URLs

Read-write repo URLs  will be of the form

ssh://clientA@yourgitserver/~/repos/reponame.git

Read-only repo URLs  will be of the form

ssh://clientA-ro@yourgitserver/~/repos/reponame.git
		
## ToDo

The ssh authorized_keys file can be used with git-shell to ensure only
git operations happen on these accounts, so far these are full ssh
accounts, which is not idea. 

			
## Adding a repo

There will be a better way than this, 
```
ssh clientA@yourgitserver
cd repos
mkdir reponame.git
cd reponame.git
git init --bare . 
```
			
