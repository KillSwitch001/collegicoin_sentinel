#!/bin/bash
set -evx

mkdir ~/.collegicoincore

# safety check
if [ ! -f ~/.collegicoincore/.collegicoin.conf ]; then
  cp share/collegicoin.conf.example ~/.collegicoincore/collegicoin.conf
fi
