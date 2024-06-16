# ~/ home tools

tools for you linux $HOME directory.

## filesorter

creates a bash script that sorts files by type in a given directory. Intended for sorting an unruly `~/Downloads` folder

```sh
# try a dry-run
filesorter --directory ~/Downloads --dry > sort.sh
bash sort.sh

# test it out for real
filesorter --directory ~/Downloads > sort.sh
chmod +x sort.sh
./sort.sh
```
