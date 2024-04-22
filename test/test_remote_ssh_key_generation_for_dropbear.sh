#!/bin/bash
LOCALSYSTEM=$(hostname)
REMOTESYSTEM="MY_SERVER_NAME"
ssh-keygen -t ed25519 -C ${REMOTESYSTEM} -f ${HOME}/.ssh/${REMOTESYSTEM}
echo "========================================================================================================================================"
echo "Public Key Generated in ${HOME}/.ssh/${REMOTESYSTEM}.pub"
echo "Private Key Generated in ${HOME}/.ssh/${REMOTESYSTEM}"
echo "========================================================================================================================================"
RAWPUBKEY=$(cat ${HOME}/.ssh/${REMOTESYSTEM}.pub)
RENAMEDPUBKEY=$(echo "${RAWPUBKEY}" | sed -E "s|${REMOTESYSTEM}|${LOCALSYSTEM}|")
echo "RAW Public Key: ${RAWPUBKEY}"
echo "========================================================================================================================================"
echo "Renamed Public Key: ${RENAMEDPUBKEY}"
echo "========================================================================================================================================"
unset RENAMEDPUBKEY
unset RAWPUBKEY
