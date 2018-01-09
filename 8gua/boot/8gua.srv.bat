#!/bin/sh

PREFIX=$(cd "$(dirname "$0")"; pwd)

cd $PREFIX
/usr/bin/env node gitweb-cli.js
