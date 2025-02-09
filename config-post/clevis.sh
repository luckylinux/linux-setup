#!/bin/bash

# Select which Threshold to Use (how many Tang Servers need to Answer in order to successfully decrypt)
keyservers_threshold=1

clevis_luks_keyslot=1

# Format Clevis TANG String
tangkeyserverdict=$(cat <<KEYSTR
{
     "t": ${keyservers_threshold},
     "pins": {
               "tang":  [
KEYSTR
)

keyservers_num=${#keyservers[@]}
keyserver_counter=0

for keyserver in "${keyservers[@]}"
do
    if [ ${keyserver_counter} -eq $((keyservers_num - 1)) ]
    then
        keyserver_next=""
    else
        keyserver_next=","
    fi

tangkeyserverdict=$(cat <<KEYSTR
${tangkeyserverdict}
                            {
                                "url": "http://${keyserver}"
                            }${keyserver_next}
KEYSTR
)

    keyserver_counter=$((keyserver_counter + 1))
done


tangkeyserverdict=$(cat <<KEYSTR
${tangkeyserverdict}
                         ]
             }
}
KEYSTR
)

# Debug
# echo ${tangkeyserverdict}

# Echo
# echo ${tangkeyserverdict} | jq

# Compact Form
# echo ${tangkeyserverdict} | jq -r --color-output

