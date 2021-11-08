from flask import Flask
from flask.templating import render_template


app = Flask(__name__)
@app.route('/', methods=["POST", "GET"])
def index():
    return render_template("index.html")
    
@app.route('/vehicle', methods=["POST", "GET"])
def vehicle():
    return f"<h1>vehicle found</h1>"

if __name__ == "__main__":
    app.run( host="0.0.0.0", debug = True)
