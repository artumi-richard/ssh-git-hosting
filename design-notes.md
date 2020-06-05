# Design notes

Don't read these. I wrote them as I was thinking about the problem,
and there may still be something useful there for me, but you don't
need to read this.

## Design

We will need to have something like 
```
/home/
	clientA/reponame
	clientA/.ssh/authorized_keys
	clientA-ro/reponame -- readonly
	clientA-ro/.ssh/authorized_keys
```	
## Jobs are


1. Make a chroot script - nah looks like the user has to exist on the
   main machine as well, which I wanted to use chroots to avoid.
2. See if we can make a read-only repo work well with umask? 
3. If not can we use some kind of 
4. Add a repo
5. Import a repo
6. List repos - for git clone purposes - check who has access
7. Check umasks are right.
8. Delete a repo
9. Remove access from a repo
10. Add a user to the system
11. Remove a user from the system?

## Umask info

I want `umask 027` which is like:
```
umask (Numeric Notation) 027
Allowed Permissions rwxr-x---

Examples:
umask 027
umask u=rwx,g=rx,o=
```

So if we have user online4baby and online4baby-ro then we would see

/home/online4baby/repos/o4bcrm
/home/online4baby-ro/repos/o4bcrm

If online4baby-ro is in the online4baby group then it *should just
work*

We can set umask to 027 in /etc/login.defs

So we need a script to add users without passwords

That should be simple enough.


## Plan

1. Get a digial ocean droplet
2. Set the umaks in /etc/login.defs to 027
3. Create a bash function that will allow us to create a user
4. Create a second function that will append -ro and add to the first
   user
5. Create a function that creates authorized_keys files for all the
   users from the config file.

   
## Creating a repo

```
ssh user@domain
cd repos
mkdir reponame.git
cd reponame.git
git --bare init
```

local machine
```
mkdir reponame
cd reponame
git init . 
git add {some files}
git commit 
git remote add origin ssh://user@domain:port/repos/reponame.git
git push -u origin master
```

Then we can clone with

```
git clone ssh://gittest4-ro@167.71.142.180:22/~/repos/tmprpo.git

``

And we're done
 
 
 
## Server config changes

To initally set up the server this is required:

```

/etc/ssh/sshd_config
	Port 1212
	UseDNS no

/etc/skel/.profile
	umask 027	
 
```
 
## Data required

1. A list of repos 'user/reponame'
2. A list of keys  'keyname'
3. A way of linking the repos to the keys?

What if we have

```
config/
	username (client - artumi?)
		reponame
			readwrite
				key1.asc
				key2.asc
			readonly
				key3.asc
				key4.asc
```

Then all we would need to do is create files and directories. 
Deletion would be manual? As it probably should be. I've only ever
deleted 
   
## Chroot?

Would it work well if we used a chroot? This would allow it to
essentially be it's own thing maybe? With ssh on some separate port?


I decided against chroot

## Progress

We're stuck on how to identify if the user should be deleted or not
becaue we can't figure out how to check if a value is in an array in
bash. I've set Mandy on that task while I get some real work done.



## Converting from gitlab

- no attempt at getting deploy keys
- extracting bundles to a bare repo
	git clone --mirror myrepo.bundle my.git
- extracting bundles to a new repo
	git clone  myrepo.bundle my.git

# so the task here is to copy the bundle to the right place, and then
  unbundle it.

