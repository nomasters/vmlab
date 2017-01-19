#!/bin/bash
# create a virtual root disk for a guest

create_usage () {
cat<<EOF
usage: $0 options

OPTIONS:
  -s	Disk size in GB, for example "$SCRIPT_ID -s 10G"
  -f	Force create. overwrites a new disk
  -v	Verbose output
  -h	Show this message
EOF
}

create () {
  # restrict action by run state
  [ -n "$runflag" ] && echo "Guest is running. Halt first" && return 1	

  # handle options
  while getopts ":s:fvh" opt; do
    case $opt in
      s)
        size="$OPTARG"
        ;;
      f)
        forceflag=1
        ;;
      v)
        verboseflag=1
        ;;
      h)
        create_usage
        return 0
        ;;
      \?)
        echo "Invalid option: -$OPTARG" && return 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." && return 1
        ;;
    esac
  done

  # make '-s' mandatory
  [ -z "$size" ] && echo "Create: -s option mandatory. Set a disk size" && return 1

  # handle verbosity
  [ -z "$verboseflag" ] && verbosity=" > /dev/null"
  
  # if the guest's lab does not exist, create lab directory under /vmlab-data/
  if [[ $guest =~ / ]]; then
    lab="$(echo $guest |rev |cut -d / -f2- |rev)"
    gName="$(echo $guest |rev |cut -d / -f1 |rev)"
    mkdir -p $imagepath/$lab
  fi

  # don't overwrite non-blank disks, and require -f to recreate newly created disks
  if [ -e ${imagepath}/${guest}.img ]; then
    echo "Create: guest already installed to disk. Use 'wipe' action to zero it out" && return 2
  elif [ -e ${imagepath}/$lab/new.${gName}.img ]; then 
    [ -z "$forceflag" ] && echo "Create: new disk already exists. Use -f to force overwrite" && return 1
  fi

  # create the disk
  if [[ -n $gName ]]; then
    verbosity="$(qemu-img create -f qcow2 ${imagepath}/$lab/new.${gName}.img $size)"
  else
    verbosity="$(qemu-img create -f qcow2 ${imagepath}/new.${guest}.img $size)"
  fi
  [ -n "$verboseflag" ] && echo $verbosity
  return 0
}
