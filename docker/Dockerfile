FROM alpine
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
RUN pip3 install flask psycopg2-binary
RUN mkdir -p /app/templates
EXPOSE 5000
WORKDIR /app
COPY app.py .
COPY templates/app.html ./templates
COPY templates/films.html ./templates
CMD flask run --host=0.0.0.0