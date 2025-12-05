FROM python

RUN apt-get update -y && \
    apt-get install -y build-essential libexpat1-dev libpcre3-dev apache2-dev apache2 libssl-dev nano yq
COPY backend/requirements.txt /app/requirements.txt
WORKDIR /app

RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
COPY backend /app

RUN groupadd -r django && useradd --no-log-init -r -g django django
RUN mkdir -p sils_reports
RUN chown -R django:django sils_reports
COPY deploy/backend/start.sh ./
COPY deploy/backend/start_checks.py ./
RUN chmod +x ./start.sh
CMD ./start.sh
