[![pub package](https://img.shields.io/pub/v/uihub_basic_inappwebview2.svg)](https://pub.dartlang.org/packages/uihub_basic_inappwebview2)

# uihub_basic_inappwebview2

[//]: # ([![YouTube Video Title]&#40;https://img.youtube.com/vi/[video-id]/0.jpg&#41;]&#40;https://www.youtube.com/shorts/[video-id]&#41;)



## Usage

1. To add UI to your project, enter the following command in the terminal at the root of your flutter project:
   ```bash
   npm install -g uihub-cli@latest
   uihub get uihub_basic_inappwebview2
   ```

2. if build on web, add this line in `web/index.html` inside the `<head>` tag.
    ```html
    <script type="application/javascript" src="/assets/packages/flutter_inappwebview_web/assets/web/web_support.js" defer></script>
    ```
   
3. run the following command to run the UI: 
    ```bash
    flutter run -d chrome lib/uihub/uihub_basic_inappwebview2/main.dart
    ```