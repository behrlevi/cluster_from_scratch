#!/bin/bash

if which kubectl >/dev/null 2>&1; then
    echo "Success: kubectl is installed and in your PATH!"
else
    echo "Error: kubectl is not installed or not executable."
fi