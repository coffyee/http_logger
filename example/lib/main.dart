import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_http_logger/flutter_http_logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP Logger Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HttpLoggerExample(),
    );
  }
}

class HttpLoggerExample extends StatefulWidget {
  const HttpLoggerExample({super.key});

  @override
  State<HttpLoggerExample> createState() => _HttpLoggerExampleState();
}

class _HttpLoggerExampleState extends State<HttpLoggerExample> {
  String _response = "No response yet";

  @override
  void initState() {
    super.initState();
    // Start the HTTP Logger server
    HttpLog.startServer(context);
  }

  // Function to make a simple GET request
  Future<void> _makeGetRequest() async {
    var url = 'https://jsonplaceholder.typicode.com/posts/1';
    var headers = {"Content-Type": "application/json"};

    // Capture start time
    final startTime = DateTime.now();

    // Make the HTTP GET request
    var response = await http.get(Uri.parse(url), headers: headers);

    // Capture end time
    final endTime = DateTime.now();

    // Log the GET request and response
    HttpLog.sendLog(
      method: "GET",
      url: url,
      header: headers,
      statusCode: response.statusCode,
      duration: endTime.difference(startTime).inMilliseconds,
      response: response.body,
    );

    setState(() {
      _response = response.body;
    });
  }

  // Function to make a simple POST request
  Future<void> _makePostRequest() async {
    var url = 'https://jsonplaceholder.typicode.com/posts';
    var headers = {"Content-Type": "application/json"};
    var requestBody = '{"title": "foo", "body": "bar", "userId": 1}';

    // Capture start time
    final startTime = DateTime.now();

    // Make the HTTP POST request
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: requestBody,
    );

    // Capture end time
    final endTime = DateTime.now();

    // Log the POST request and response
    HttpLog.sendLog(
      method: "POST",
      url: url,
      header: headers,
      request: requestBody,
      statusCode: response.statusCode,
      duration: endTime.difference(startTime).inMilliseconds,
      response: response.body,
    );

    setState(() {
      _response = response.body;
    });
  }

  @override
  void dispose() {
    HttpLog.endServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HTTP Logger Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: _makeGetRequest,
              child: const Text('Make GET Request'),
            ),
            ElevatedButton(
              onPressed: _makePostRequest,
              child: const Text('Make POST Request'),
            ),
            const SizedBox(height: 20),
            const Text('Response:'),
            Expanded(child: SingleChildScrollView(child: Text(_response))),
          ],
        ),
      ),
    );
  }
}
