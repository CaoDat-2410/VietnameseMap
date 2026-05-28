FROM postgis/postgis:16-3.4

# Install GDAL
RUN apt-get update && apt-get install -y --no-install-recommends \
    gdal-bin \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
