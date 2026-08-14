import json
import urllib.request

url = 'https://fal.run/fal-ai/nano-banana-pro/edit'
data = {
    'prompt': 'Change the background to a professional corporate office.',
    'image_url': 'https://upload.wikimedia.org/wikipedia/commons/4/48/Outdoors-man-portrait_%28cropped%29.jpg'
}

req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), method='POST')
req.add_header('Content-Type', 'application/json')
req.add_header('Authorization', 'Key 2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772')

try:
    response = urllib.request.urlopen(req)
    print(response.read())
except urllib.error.HTTPError as e:
    print(e.code)
    print(json.dumps(json.loads(e.read().decode('utf-8')), indent=2))
