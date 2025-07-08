
# flutter_http_logger

`flutter_http_logger` is a simple Flutter package that enables logging of HTTP requests and responses. This package allows developers to view logs in a web browser using a provided URL. It is designed to create a local server from real devices (not emulators) to facilitate HTTP log viewing.

## Features

- Log HTTP requests and responses in real-time.
- View logs on a web browser using a provided URL.
- Supports different HTTP methods: GET, POST, and POST_FILE.
- Simple initialization and usage.

## Getting Started

To start using `flutter_http_logger`, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_http_logger: 1.0.8
```

Then, import the package:

```dart
import 'package:flutter_http_logger/flutter_http_logger.dart';
```

## Usage

### Initializing the Logger

To initialize the logger and start the local server, use the `HttpLog.startServer(context)` function in your app:

```dart
HttpLog.startServer(context);
```

### Sending Logs

Whenever you make an HTTP request, log the request and response details using the `HttpLog.sendLog()` function. Here are examples for different HTTP methods:

#### Logging a POST Request

```dart
HttpLog.sendLog(
  method: "POST",
  url: baseUrl + api,
  header: _header,
  request: dataInJson,
  statusCode: response.statusCode,
  response: response.body,
  duration: endTime.difference(startTime).inMilliseconds,
);
```

#### Logging a GET Request

```dart
HttpLog.sendLog(
  method: "GET",
  url: baseUrl + api,
  header: _header,
  statusCode: response.statusCode,
  response: response.body,
  duration: endTime.difference(startTime).inMilliseconds,
);
```

#### Logging a POST_FILE Request

```dart
HttpLog.sendLog(
  method: "POST_FILE",
  url: baseUrl + api,
  header: _header,
  request: data,
  statusCode: response.statusCode,
  response: response.body,
  duration: endTime.difference(startTime).inMilliseconds,
);
```

### Viewing Logs

After starting the server, visit the provided URL (displayed in the logs or your app console) in a web browser to view real-time logs of your HTTP requests and responses.

## Example

Here is a simple example of how to integrate `flutter_http_logger` with an HTTP client in a Flutter app:

```dart
import 'package:flutter_http_logger/flutter_http_logger.dart';

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Initialize the HTTP Logger
    HttpLog.startServer(context);

    _makeHttpRequest();
  }

  @override
  void dispose() {
    // End the HTTP Logger
    HttpLog.endServer();
    super.dispose();
  }
}

Future<void> _makeHttpRequest() async {

  // Capture start time
    final startTime = DateTime.now();
final response = await http.post(Uri.parse( baseUrl + api),
    header: _header,
    body: dataInJson);

     // Capture end time
    final endTime = DateTime.now();

    // Log the request and response
  HttpLog.sendLog(
    method: "POST",
    url: baseUrl + api,
    header: _header,
    request: dataInJson,
    statusCode: response.statusCode,
     duration: endTime.difference(startTime).inMilliseconds,
    response: response.body,
  );
}
```

## Additional Setup Instructions (For Android Emulators Only)

### **1. For macOS & Windows (Desktop App)**
For an easy setup on desktop, download and run the appropriate application for your system:

- **Windows App:** [Download](https://github.com/coffyee/Flutter-HTTP-logger-desktop-files/raw/main/Flutter%20HTTP%20Logger.exe)
- **Mac App:** [Download](https://github.com/coffyee/Flutter-HTTP-logger-desktop-files/raw/main/Flutter%20HTTP%20Logger.zip)

Once installed, the application will handle logging automatically.


### **2. If You Don't Want to Use a Desktop Application**
If you prefer not to use a desktop application, you can try running the JavaScript files with Node.js. Follow these steps:

1. Download the [flutter_http_logger_emu](https://github.com/coffyee/flutter_http_logger_emu/archive/refs/heads/main.zip).
2. Extract the files and **rename the JavaScript files as needed**.
3. Open a terminal or command prompt and navigate to the folder containing the files.
4. Install dependencies:
   ```sh
   npm install
   ```
5. Start the server:
   ```sh
   node server.js
   ```
6. Once started, the server will display an IP address. Open a browser, enter that IP, and input it into your Flutter app to begin logging.

This method allows you to use `flutter_http_logger` without installing any additional desktop applications.


## Contributings

Contributions are welcome! If you have any issues or feature requests, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License.
