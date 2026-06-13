FROM postgis/postgis:16-3.4

# Install GDAL
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdal-bin \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY docker-init.sql /docker-entrypoint-initdb.d/01-docker-init.sql
COPY campaign-module.sql /docker-entrypoint-initdb.d/campaign-module.sql
