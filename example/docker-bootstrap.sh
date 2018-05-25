#!/bin/sh -l
JS="static/js/agid-spid-enter-config.js"
cd /src/app
envsubst < ${JS}.template > ${JS}
npm start
