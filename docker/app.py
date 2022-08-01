from flask import Flask, request, jsonify
import flask
import socket
import psycopg2
from contextlib import closing

name='app'
dbuser='postgres'
dbpassword='mysecretpassword'
dbhost='postgres'
app = Flask(__name__)
hostname = socket.gethostname()

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(("8.8.8.8", 80))
ip = s.getsockname()[0]
s.close()




health = True

@app.route("/")
def run():
    if health:
        return flask.render_template('app.html', ip=ip, hostname=hostname)
    else:
        return '<h1 style="color: #ff0000; text-align: center;">I\'M DEAD, SORRY</h1>"'

@app.route("/api/destroy")
def destroy():
    global health
    health = False
    return 'Destroyed'

@app.route("/api/recover")
def recover():
    global health
    health = True
    return 'Alive'

@app.route("/health")
def health():
    if health:
        return jsonify(status='healthly'), 200
    else:
        return jsonify(status='destroyed'), 521

@app.route("/films", methods=['GET', 'POST'])
def show_films():
        if request.method == 'POST':
            if request.form['show_films'] == 'Show Films':
                conn = psycopg2.connect(dbname=name, user=dbuser, password=dbpassword, host=dbhost)
                cursor = conn.cursor()
                cursor.execute("SELECT title FROM films;")
                rows = cursor.fetchall()
                mylist = []
                for row in rows:
                    mylist.append(row[0])
                cursor.close()
                conn.close()
                return flask.render_template('films.html', content=mylist)
        else:
            return flask.render_template('app.html', ip=ip, hostname=hostname)
