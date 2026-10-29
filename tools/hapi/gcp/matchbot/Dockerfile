# Match-bot's web app (match-bot/ in crosscutio/field-kit) under gunicorn. Pinned to a field-kit
# commit; to update, change FIELD_KIT_REF and run ./matchbot.sh up.
FROM python:3.12-slim

ARG FIELD_KIT_REF=9495e671defefd6f8d6e59ba3da8f39801ef5cb4
# Installed from a source checkout (pip -e): the package's metadata ships only data/*.csv, so a
# regular install leaves out the web app's templates and static files.
# libexpat1 stays: fiona (shapefiles, GeoPackages) needs it.
RUN apt-get update && apt-get install -y --no-install-recommends git libexpat1 \
 && git clone https://github.com/crosscutio/field-kit.git /opt/field-kit \
 && git -C /opt/field-kit checkout -q "$FIELD_KIT_REF" \
 && pip install --no-cache-dir gunicorn==23.0.0 -e "/opt/field-kit/match-bot[all]" \
 && apt-get purge -y git && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# Uploads go to Flask's instance folder (match-bot/instance in the checkout); the gazetteer
# cache to MATCH_BOT_GAZETTEER_DIR. Both are volumes (docker-compose.yml).
ENV MATCH_BOT_GAZETTEER_DIR=/data/gazetteer
RUN mkdir -p /data/gazetteer /opt/field-kit/match-bot/instance \
 && useradd -r -u 1000 matchbot \
 && chown -R matchbot /data /opt/field-kit/match-bot/instance
USER matchbot
EXPOSE 5000

# One worker: the app signs its session cookie with a key made at start-up, so a second worker
# would not recognise the first one's sessions. Threads serve concurrent requests.
CMD ["gunicorn", "--workers", "1", "--threads", "8", "--timeout", "600", "--bind", "0.0.0.0:5000", \
     "match_bot.gui.app:create_app()"]
