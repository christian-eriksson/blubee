# blubee

Simple json based backup utility.

## Get source

If you want to develop blubee further or install it, start by getting the source:

```
$ git clone https://github.com/christian-eriksson/blubee.git
```

## Build

To build `dist/blubee_<version>_all.deb` and `dist/blubee`, run:

```
# ./build.sh <version>
```

this script would also build a tar ball with a configured version of blubee.

## Install

Build the package as `<version>` then, on a Debian based system run:

```
# apt install dist/blubee_<version>_all.deb
```

You are now ready to run `blubee`.

### Manual install

On a non Debian system, you can install blubee by building blubee and extract the content of the resulting tar ball, `blubee_<version>_all.tar.gz`, to your `/etc` and `/usr/local/bin`. The launcher script in `dist/blubee/usr/local/bin` may be placed in some other directory present in your `$PATH` if you wish.

During restores blubee will save files that has been changed or will be deleted by the backup. Default folder for this backup copy is `/var/local/blubee/backups`, make sure to create this directory and that the user running blubee has write permissions to this directory.

Also install the dependencies listed below.

#### Dependencies

Blubee uses the following tools. If you don't have them, you'll need to install them.

* rsync
* jq

## Run blubee

To run blubee call it like:

```
blubee [-c <config-path>] -b <backup.json-path> [options] command
```

### `backup.json`

For defining a backup job, blubee expects a `backup.json` this file is passed to blubee for all commands. Here is a small example:

```json
{
    "backup_destination": "/backup/path",
    "backup_configs": [
        {
            "name": "my-backup",
            "root": "/backup/root",
            "paths": [
                "some/directory/path",
                "some/file.txt",
                "another/path"
            ]
        }
    ]
}
```

This would tell blubee that backups are to be stored in `/backup/path`. Under this directory, blubee will create one directory for each backup config in `backup.json`. In this case, one directory called `my-backup`. Within these backup paths blubee will create a new directory for each backup created, named after the date and time of the backup. Additionally there will be a directory, `latest`, linking to the most recent backup.

The backup configs specify which files to backup. Each config specifies a `root` path that will be prepended to each path in `paths`. This should form absolute paths to the files and/or directories to backup. Preferably the root should be as deep as possible. For example if `/my/path/to/file` and `/my/path/to/another/file` is to be backed up choose `/my/path/to` as the root.

**NOTE**: Careful when creating configs, blubee runs the `rsync` command with the --delete option so overlapping root+path combinations in the configs may result in dataloss. Use at your own risk! To minimize the risk, deleted and changed files are saved to `/var/local/blubee/backups`.

#### Object definition

The `backup.json` consists of an object with the properties in the following tables:

| name                 | type              | description                                                           |
| -------------------- | ----------------- | --------------------------------------------------------------------- |
| `backup_destination` | `string`          | path to where blubee will create the backups                          |
| `backup_configs`     | `backup_config[]` | list of backup config objects                                         |
| `destination_host`   | `string`          | address (eg. IP or domain name) to host with the `backup_destination` |
| `destination_user`   | `string`          | user on `destination_host` which will create the backup               |

If destination host and, optionally, user is present in the `backup.json` blubee will connect to the destination host to create the backup. It is recommended to make sure that the machine running blubee can login automatically (as the provided user) on the destination host. Otherwise you'd have to type the password for each backup config in the `backup,json` as well as any filesystem accesses blubee does.

##### `backup_config` object

The `backup_config` object defines a backup in terms of source of content and name.

| name    | type       | description                                                             |
| ------- | ---------- | ----------------------------------------------------------------------- |
| `name`  | `string`   | name of the backup, and the directory containing the config's backups   |
| `root`  | `string`   | will be prepended to all `paths`, building the absolute paths to backup |
| `paths` | `string[]` | list of paths to backup, the paths should all originate from the root   |

### Commands

Blubee takes the commands `backup`, `restore` and `dry <command>`.

#### Backup command

Blubee can create backups on a local machine aswell as pushing a backup to a remote machine. To create a backup, create `backup.json` with the content described above and run:

```
blubee -b backup.json backup
```

Given a file structure like this:

```
/
|-backup/
| |-root/
| | |-some/
| | | |-directory/
| | | | |-path/
| | | | | |-file-1
| | | | | |-file-2
| | | |-file.txt
| | | |-not-backed.up
| | |-another/
| | | |-path
| | |-yet-another/
| | | |-path
```

The result of a backup performed with the example `backup.json` in year 2020 on October 20th at 10 minutes and 30 seconds past 10PM will create a file structure like this:

```
/
|-backup/
| |-path/
| | |-my-backup/
| | | |-20201020_221030/
| | | | |-some/
| | | | | |-directory/
| | | | | | |-path/
| | | | | | | |-file-1
| | | | | | | |-file-2
| | | | | |-file.txt
| | | | |-another/
| | | | | |-path
| | | |-latest -> /backup/path/my-backup/20201020_221030
```

You can choose to only create a backup of a single config in the `backup.json` by providing the `-n` option with the name of the config.

```
blubee -b backup.json -n my-backup backup
```

#### Restore command

Blubee can restore backups from your local machine as well as pulling backups from a remote machine. You should have a `backup.json` as described above, to restore the backup created in the example above run:

```
blubee -b backup.json restore
```

The data will be restored to the root+path combinations specified in `backup.json`. To restore a specific backup config from the `backup.json` use the `-n` option with the name of the config. If you want to restore a backup from a specific point in time, use the `-d` option:

```
blubee -b backup.json -n my-backup -d 20201020_221030 restore
```

#### Dry command

The dry command lets you inspect what would happen during a backup or restore. For the example above you could run:

```
blubee -b backup.json dry backup
```

or

```
blubee -b backup.json dry restore
```

This would show you a list of files that would be changed/created and/or deleted if backup or restore was run without the `dry` command.

#### Options

Blubee allows the following options:

| flag | input                 | description                                                                       |
| ---- | --------------------- | --------------------------------------------------------------------------------- |
| -b   | `path/to/backup.json` | path to backup.json as described above.                                           |
| -c   | `path/to/config`      | path to custom blubee config as described below.                                  |
| -n   | `<config-name>`       | name of a specific backup config from the backup json to restore or backup.       |
| -d   | `<backup-datetme>`    | the datetime stamp of the backup to be restored, ignored during backup.           |
| -h   |                       | print a help prompt with simple description on how to use blubee.                 |
| -v   |                       | print version and build information, blubee must be built to show correct values. |

### Configuration file

By default, when installed as described above, blubee will look for `/etc/blubee/blubee.conf`. You may pass a config file using the `-c` option for custom configs (or edit the default one if you prefer). The config file will hold variables like this:

```sh
RESTORE_BACKUP_PATH=/some/path
```

Possible variables for the config are:

| Variable              | Description                                                                     |
| --------------------- | ------------------------------------------------------------------------------- |
| `RESTORE_BACKUP_PATH` | Path where blubee stores files that were changed or deleted during last restore |

