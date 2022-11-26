# restic-systemd-backup

`restic-systemd-backup` is a collection of systemd units and shell
scripts that allow me to backup my systems.

The initial idea for the code contained in this repository came from
[this blog post](https://tdem.in/post/restic-with-systemd/) and [this
github issue](https://github.com/restic/restic/issues/1015).

## Usage

This repository mostly is a collection of scripts and systemd units.
The [`Makefile`](./Makefile) provides a convenient way to copy the files
in the repository to the system. However, additional manual work is
required before first use.

Templated systemd units provided by this repository assume that a
directory containing further configuration exists under
`$PREFIX/etc/restic-systemd-backup/%I/`.

### Prerequisites

The following prerequisites must be met in order to use
`restic-systemd-backup`:

1. The `restic` binary must be installed on the system.
2. A designated backup user must be created. By default this user is
   assumed to be called `restic`.

### Installation

In order to install the files to `$PREFIX/etc/restic-systemd-backup/`
execute the following command:

    sudo make install

The `PREFIX` defaults to `/usr/local`. In order to change prefix
execute:

    sudo PREFIX="/somewhere/else" make install

### Filesystem backups

Filesystem level backups are provided by the
[`restic-backup-fs@.service`](./systemd/restic-backup-fs@.service)
service. In order to schedule regular filesystem level backups execute
the following steps:

1. Create a directory `$PREFIX/etc/restic-systemd-backup/<instance-name>`.
2. Create the file
   `$PREFIX/etc/restic-systemd-backup/<instance-name>/env` setting any
   environment variables used to configure `restic`. At the very minimum
   it must set `RESTIC_REPOSITORY` and `RESTIC_PASSWORD`. The [restic
   documentation](https://restic.readthedocs.io/en/stable/040_backup.html#environment-variables)
   describes additional ways to configure restic. Note that if the file
   contains `RESTIC_PASSWORD` it should be readable by the `restic` user
   only.
3. Create the file
   `$PREFIX/etc/restic-systemd-backup/<instance-name>/files` defining
   which files and directories restic should backup. The [restic
   documentation](https://restic.readthedocs.io/en/stable/040_backup.html#including-files)
   for the `--files-from` flag explains the format of the file.
4. Enable and start the
   [`restic-backup-fs@.timer`](./systemd/restic-backup-fs@.timer).

### Backup removal

The
[`restic-backup-forget@.service`](./systemd/restic-backup-forget@.service)
allows to automatically remove outdated backups based on a fixed
schedule. Once the filesystem level backups are configured the only
thing left to do is to enable and start the
[`restic-backup-forget@.timer`](./systemd/restic-backup-forget@.timer).

### Failure notifications

The [`restic-backup-failed@.service`] provides notifications in case one
of the `restic-backup-*.service` units fails. In order to enable
notifications for a instance create a directory
`$PREFIX/etc/restic-with-systemd/<instance-name>/notify.d` and place one
or more executable files into it.

See the `notify-failed-*` files in the [`scripts`](./scripts) directory
for example. Of course one or more of the `notify-failed-*` can by
copied or symlinked to the `notify.d` directory.

## License

Copyright © 2022 Ferdinand Hofherr

Distributed under the MIT License.
