# ts-backup-bash

After [downloading](https://github.com/pmario/ts-backup-bash/releases/) the script, make sure it is executable.

Prerequisites:

 - curl
 - sed
 - printf
 

Executable:

The ts-backup file needs to be an executable!

```
chmod +x ts-backup.sh
```

Usage: 

```
./ts-backup.sh <tsUserName>

eg: 

./ts-backup.sh pmario
```

## Video

see: https://youtu.be/bBSF1mFQswA

## Donate

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.me/PMarioJo)

If this script helped you, to save your valuable time, you can help me spend more time creating useful things. Thanks!

## Extended Options

```
./ts-backup -h

Usage:  ts-backup UserName [Options]

Options:

        -s .. Search string to create my-spaces.txt
        -o .. Output filename. default: my-spaces.txt
        -i .. Use FileName you created with -o parameter, as input to download public spaces

        -v .. Version
        -h .. This Help
```

### Examples

```
$ ./ts-backup.sh pmario
```

Default behaviour.
It will download **private and public** spaces as html and json files.
Data will be stored in `pmario/data` directory.
`pmario` will be used as the TS user name. The UI will ask for the TS password.
Logfile: `spaces-pmario.log` contains the full URL, that may be used later on with the internet archive.org, to backup the spaces there too.


```
$ ./ts-backup.sh hugo -s hugo
```

This command downloads a list of all existing space names and save it as `all-spaces.txt`. If `all-spaces.txt` exists, it will be reused!

It will create a file named: `my-spaces.txt` which contains the selected spaces.
It will download **public spaces only** even if you provide a username! The userName will only be used to create the local backup directory.


```
$ ./ts-backup.sh foo -s bar -o selected-spaces.txt
```

This command is similar to the one above. 
It will search for the string `bar` in space names.
It will save the selected spaces in a file named: `selected-spaces.txt`
It will use the backup directory: `foo`


```
$ ./ts-backup.sh test -i selected-spaces.txt
```

This command will create a backup directory named: `test` and use 
`selected-spaces.txt` as the input selection to download the public content.
