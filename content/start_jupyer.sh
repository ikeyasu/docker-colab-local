#!/bin/bash -e

# Enable http_over_ws (It was enabled on Dockerfile but it is neccesarry becauseof unknown reason)
jupyter serverextension enable --py jupyter_http_over_ws

# Run jupyer notebook
cd /content
jupyter notebook --NotebookApp.allow_origin='https://colab.research.google.com' --port=8081
