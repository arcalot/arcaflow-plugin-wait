# Package path for this plugin module relative to the repo root
ARG package=arcaflow_plugin_wait

# STAGE 1 -- Build module dependencies and run tests
# The 'poetry' and 'coverage' modules are installed and verson-controlled in the
# quay.io/arcalot/arcaflow-plugin-baseimage-python-buildbase image to limit drift
FROM quay.io/arcalot/arcaflow-plugin-baseimage-python-buildbase:0.4.0@sha256:26f5d506f0750e0cad636afbe7ddd8cade09937eb5abae784096e46a1d4ae030 as build
ARG package

COPY poetry.lock /app/
COPY pyproject.toml /app/

# Convert the dependencies from poetry to a static requirements.txt file
RUN python -m poetry install --without dev --no-root \
 && python -m poetry export -f requirements.txt --output requirements.txt --without-hashes

COPY ${package}/ /app/${package}
COPY tests /app/${package}/tests

ENV PYTHONPATH /app/${package}
WORKDIR /app/${package}

# Run tests and return coverage analysis
RUN python -m coverage run tests/test_${package}.py \
 && python -m coverage html -d /htmlcov --omit=/usr/local/*


# STAGE 2 -- Build final plugin image
FROM quay.io/arcalot/arcaflow-plugin-baseimage-python-osbase:0.4.0@sha256:6674b5d2aa5de565b1d39a9c1694ad7ca15b57d06f33529bc3a6f4d6e76b100e
ARG package

COPY --from=build /app/requirements.txt /app/
COPY --from=build /htmlcov /htmlcov/
COPY LICENSE /app/
COPY README.md /app/
COPY ${package}/ /app/${package}

# Install all plugin dependencies from the generated requirements.txt file
RUN python -m pip install -r requirements.txt

WORKDIR /app/${package}

ENTRYPOINT ["python", "arcaflow_plugin_wait.py"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-wait"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Python Wait Plugin"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
