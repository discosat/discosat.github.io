FROM python:3.11-slim-buster

WORKDIR /app

RUN apt-get update && \
    apt-get install -y entr && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    sphinx \
    sphinx_rtd_theme \
    myst_parser

CMD find doc -type f | entr -r sh -c \
    'sphinx-build doc _build && python -m http.server 8000 --directory _build'
