from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route('/<user>/<repo>')
def get_last_release(user, repo):
    url = f"https://api.github.com/repos/{user}/{repo}/releases/latest"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        return jsonify({
            'name': data['name'],
            'tag_name': data['tag_name'],
            'created_at': data['created_at'],
            'published_at': data['published_at'],
            'html_url': data['html_url']
        })
    else:
        return jsonify({'error': 'Unable to retrieve last release'}), 404

if __name__ == '__main__':
    app.run(port=8080,host="0.0.0.0")

