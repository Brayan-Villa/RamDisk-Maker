#!/bin/sh

#  func.pb.sh
#  
#
#  Created by Brayan Ivan Villa Claudio on 23/02/23.
#  
ircv_send_raw_file(){
    required/irecovery -f "$1"
}

ircv_send_command(){
    required/irecovery -c "$1"
}

fileExists(){
    tree="$(echo $1 | sed 's/\// /g' | awk '{printf $1}' | sed 's/%//g')"
    two="$(echo $1 | sed 's/\// /g' | awk '{printf $2}' | sed 's/%//g')"
    if [[ "$(find ./$tree -iname $two)" != "./tree/$two" ]]
    then
        echo "1"
    else
        echo "0"
    fi
}

