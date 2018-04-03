#!/bin/bash

# Copyright 2018 David Hedlund
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

case "$1" in

    ""|-help)

	[ "$1" = "" ] && echo "Usage: $filename [--option] [--debug]

OPTIONS
    $0 --all
	$0 --get-data
        $0 --get-playlists
	$0 --merge
" && exit 1

        ;;

    --get-data)

        mkdir build
        cd build/ || exit

        wget "http://radcap.ru/index-d.html" -O index-d.html

        cp -a index-d.html 1.html

        sed -i 's/.$//' 1.html # Remove carrige return
        #tr -d '\r' test.html # Didn't work to remove the carrige returns for some reason
        sed -i '/romance/{N;s/\n//;}
s|  ||g
' 1.html
        grep "\"genres\"" 1.html > 2.html

        cp 2.html 3.html
        sed -i "s|><a|>\n<a|g" 3.html
        grep "\"genres\"" 3.html > 4.html
        sed -i "s|> |>|
s|<span>||g
s|</span>||g
s|</a>||g
s|</td>||g
s|<br>||g

s|<a href=\"||g
s|.html||g
s|\" class=\"genres\">|\t|g
s|<img src=\"|\t|g
s|\" alt=\"|\t|g
s|\" width=\"200\"/>|\t|g

# R'N'B issue
s|<span class=\"genres\">||g
" 4.html

        ;;
    --get-playlists)

        cd build/ || exit

        rm -fr playlists.txt
        cp -a 4.html entries.txt

        IFS=$'\n'       # make newlines the only separator

        for i in $(cat entries.txt); do

            x1=$(echo $i | awk '{print $1}');
            playlist=$(wget "http://radcap.ru/$x1.html" -qO- | grep "\.pls" | sed "s|\"|\n|g" | grep "\.pls");
            
            echo $playlist
            echo $playlist >> playlists.txt

        done

        ;;
    --merge)

        IFS=$'\n'       # make newlines the only separator

        rm -f radio-droid.tsv

        cd build/ || exit

        paste -d '\t' entries.txt playlists.txt > all.txt

        for i in $(cat all.txt); do

            homepage=$(echo $i | awk -F '\t' '{print $1}');
            name=$(echo $i | awk -F '\t' '{print $5}');
            playlist_url=$(echo $i | awk -F '\t' '{print $6}');
            
            list=$(echo -e "Radio Caprice - $name\t$playlist_url\thttp://radcap.ru/$homepage.html\thttp://radcap.ru/apple-touch-icon.png\tRussia\t\t\t$name")
            echo "$list"
            echo "$list" >> ../radio-droid.tsv

#echo $i | awk -F '\t' '{print $4}';


        done

        ;;
    --all)

        $0 --get-data "$2"
        $0 --get-playlists "$2"
        $0 --merge "$2"

        ;;

esac
