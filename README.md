# Scrive
An image captioning IOS App. Uses GoogleVision to label images, and select captions from a large library.

Setup:
1. Download and open project in XCode
2. Visit cloud.google.com and create an API Key which allows access to google vision
2. Create the a file called "Constants.swift" under the "Model" folder
3. Place the following code inside this file:
```
let API_KEY = "YOUR GOOGLE CLOUD API KEY"
let API_URL = "https://vision.googleapis.com/v1/images:annotate?key=\(API_KEY)"
```
4. Run the app
