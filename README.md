# MobileSync

A collection of utilities for working with MobileSync (iPod, iPhone, iPad…) backups. Right now it only supports mounting backups via FuseFS. Tested only under OSX Lion and with iOS 5 Backups (at this time I found no other utility compatible).

## Installation 

	$ git clone git@github.com:knoopx/mobilesync.git
	$ cd mobilesync/
	$ rake install

## Usage

	$ mobilesync help
	Tasks:
	  mobilesync help [TASK]                       # Describe available tasks or one specific task
	  mobilesync mount [BACKUP DIR] [MOUNT POINT]  # Mount the specified backup into the specified mount point

	$ mkdir mountpoint
	$ mobilesync mount ~/Library/Application\ Support/MobileSync/Backup/5258f14e14a5a7907878774eb41653ba1d787f8b-20111005-154802/ mountpoint/

	$ cd mountpoint/
	$ ls
	Documents             Library               Media                 SystemConfiguration   TrustStore.sqlite3    keychain-backup.plist

## Future Plans

Descryption of keychain. If you are familiar please contact me or send pull request :)