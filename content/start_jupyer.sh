#!/bin/bash -e

# set cuda library path
export LD_LIBRARY_PATH=/usr/local/cuda-9.0/targets/x86_64-linux/lib:$LD_LIBRARY_PATH

# Enable http_over_ws (It was enabled on Dockerfile but it is neccesarry becauseof unknown reason)
jupyter serverextension enable --py jupyter_http_over_ws

# Run jupyer notebook
cd /content
jupyter notebook --NotebookApp.allow_origin='https://colab.research.google.com' --port=8081
