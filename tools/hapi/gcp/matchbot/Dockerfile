# Match-bot's web app (match-bot/ in crosscutio/field-kit) under gunicorn. Pinned to a field-kit
# commit on the community-geocoder branch (James McKinnon's; the Community Geocoder and the ICR
# SDI/FHIR import, not yet on main); to update, change FIELD_KIT_REF and run ./matchbot.sh up.
FROM python:3.12-slim

ARG FIELD_KIT_REF=dc22cce699089467ca68db9caafe8abc918ae5b2
# Installed from a source checkout (pip -e): the package's metadata ships only data/*.csv, so a
# regular install leaves out the web app's templates and static files.
# libexpat1 stays: fiona (shapefiles, GeoPackages) needs it. DuckDB stays on 1.x: 2.0's httpfs
# extension fails its signature check when installed (Oct 2026).
RUN apt-get update && apt-get install -y --no-install-recommends git libexpat1 \
 && git clone https://github.com/crosscutio/field-kit.git /opt/field-kit \
 && git -C /opt/field-kit checkout -q "$FIELD_KIT_REF" \
 && pip install --no-cache-dir gunicorn==23.0.0 "duckdb>=1.5,<2" -e "/opt/field-kit/match-bot[all]" \
 && apt-get purge -y git && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Uploads (each browser session's project) and the app's secret key go to Flask's instance folder
# (match-bot/instance in the checkout); the gazetteer cache to MATCH_BOT_GAZETTEER_DIR. Both are
# volumes (docker-compose.yml).
ENV MATCH_BOT_GAZETTEER_DIR=/data/gazetteer
RUN mkdir -p /data/gazetteer /opt/field-kit/match-bot/instance \
 && useradd -r -m -u 1000 matchbot \
 && chown -R matchbot /data /opt/field-kit/match-bot/instance
USER matchbot
# The ICR import reads GeoParquet over HTTPS with DuckDB's httpfs extension; installed here (in
# ~/.duckdb) rather than downloaded on first use.
RUN python -c "import duckdb; duckdb.sql('INSTALL httpfs')"
EXPOSE 5000

# One worker: sessions' projects are files and the app keeps no shared state between processes.
# Threads serve concurrent requests.
CMD ["gunicorn", "--workers", "1", "--threads", "8", "--timeout", "600", "--bind", "0.0.0.0:5000", \
     "match_bot.gui.app:create_app()"]
