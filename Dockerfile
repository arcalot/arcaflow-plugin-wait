FROM quay.io/centos/centos:stream8

RUN dnf -y module install python39 && dnf --setopt=tsflags=nodocs -y install python39 python39-pip && dnf clean all
RUN mkdir /app
# this is to satisfy arcaflow-plugin-image-builder but the local license file is the same.
ADD https://raw.githubusercontent.com/arcalot/arcaflow-plugin-template-python/main/LICENSE /app/
ADD README.md /app/
ADD wait_plugin.py /app/
ADD tests/test_wait_plugin.py /app/
ADD poetry.lock pyproject.toml /app/
WORKDIR /app

RUN pip3 install poetry
RUN poetry config virtualenvs.create false
RUN poetry install
RUN python3 -m coverage run test_wait_plugin.py
RUN python3 -m coverage html -d /htmlcov --omit=/usr/local/*

VOLUME /config

ENTRYPOINT ["python3", "/app/wait_plugin.py"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-wait"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Python Wait Plugin"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
