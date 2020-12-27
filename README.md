# blubee

Simple backup utility, based on rsync.

## Install

Choose an `<install/path>` and run:

```
$ cd <install/path>
$ git clone https://github.com/christian-eriksson/blubee.git
```

If `<install/path>` is not in your `$PATH`, create a link to `blubee` in a path that is in `$PATH`, eg. `/usr/local/bin`

```
# ln -s <insall/path>/blubee /usr/local/bin/blubee
```

During restores blubee will save files that has been changed or will be deleted by the backup. Default folder for this backup copy is `/var/local/blubee`, make sure to run blubee with a user with write permissions to this directory or use a custom config with the `RESTORE_BACKUP_PATH` variable set.

### Dependencies

Blubee uses the following tools. If you don't have them, you'll need to install them.

* rsync
* jq

## `backup.json`

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

### Object definition

The `backup.json` consists of an object with the properties in the following tables:

| name                 | type              | description                                                           |
| -------------------- | ----------------- | --------------------------------------------------------------------- |
| `backup_destination` | `string`          | path to where blubee will create the backups                          |
| `backup_configs`     | `backup_config[]` | list of backup config objects                                         |
| `destination_host`   | `string`          | address (eg. IP or domain name) to host with the `backup_destination` |
| `destination_user`   | `string`          | user on `destination_host` which will create the backup               |

#### `backup_config` object

The `backup_config` object defines a backup in terms of source of content and name.

| name    | type       | description                                                             |
| ------- | ---------- | ----------------------------------------------------------------------- |
| `name`  | `string`   | name of the backup, and the directory containing the config's backups   |
| `root`  | `string`   | will be prepended to all `paths`, building the absolute paths to backup |
| `paths` | `string[]` | list of paths to backup, the paths should all originate from the root   |

## Configuration

You need to pass a config file using the `-c` option for blubee to know where vital files are. This file will hold variables like this:

```sh
RESTORE_BACKUP_PATH=/some/path
```

Possible variables for the config are:

| Variable              | Description                                                                     |
| --------------------- | ------------------------------------------------------------------------------- |
| `RESTORE_BACKUP_PATH` | Path where blubee stores files that were changed or deleted during last restore |

## Creating Backups

Blubee can create backups on a local machine aswell as pushing a backup to a remote machine. To create a backup, create a `backup.json` as described above and run:

```
blubee -c <blubee-config> -b <path-to-backup.json> backup
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

**NOTE: Avoid keeping overlapping root+path combinations in your backup configs, it is easy to create backups that, when restored, will overwrite each other!!**

You can choose to only create a backup of a single config in the `backup.json` by providing the `-n` option with the name of the config.

```
blubee -c <blubee-config> -b <path-to-backup.json> [-n <config-name>] backup
```

## Restoring Backups

Blubee can restore backups from your local machine as well as pulling backups from a remote machine. You should have a `backup.json` as described above, to restore the backup created in the example above run:

```
blubee -c <blubee-config> -b <path-to-backup.json> restore
```

The data will be restored to the root+path combinations specified in `<backup.json>`. To restore a specific backup config from the `backup.json` use the `-n` option with the name of the config. If you want to restore a backup from a specific point in time, use the `-d` option:

```
blubee -c <blubee-config> -b <path-to-backup.json> [-n <config-name> -d <datetime-of-backup>] restore
```

## Dry run command

To inspect what would happen during a backup or restore you can use the dry command.

```
blubee -c <blubee-config> -b <path-to-backup.json> dry [backup|restore]
```

This would show you a list of files that would be changed/created and/or deleted if run without the `dry` command.

