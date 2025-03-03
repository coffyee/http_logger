
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
  flutter_http_logger: 1.0.3
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

### Stopping the Logger

To stop the logger and close the local server, use the `HttpLog.endServer()` function in your app:

```dart
HttpLog.endServer();
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

To use `flutter_http_logger`, follow these steps:

1. Download the required file from [flutter_http_logger_emu](https://github.com/coffyee/flutter_http_logger_emu/archive/refs/heads/main.zip).
2. Open the command prompt or terminal and navigate to the file location.
3. Run the following command to install dependencies:

   ```sh
   npm install
   ```

4. Start the local server by running:

   ```sh
   npm start
   ```

5. **If you encounter an error stating that npm is not found, install Node.js and set the system path for Node.**
6. **Once the setup is complete, every time you run the app, navigate to the file location, open the terminal, and run `npm start`.**
7. **After starting the server, an IP address will be displayed. Open a browser and enter that IP, and you need to input that IP into your Flutter app. You are ready to go!**

## Contributings

Contributions are welcome! If you have any issues or feature requests, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License.
