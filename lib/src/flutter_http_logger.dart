import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_http_logger/src/share_pref.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ip_dia.dart';

/// A class for logging HTTP requests and responses in real-time.
///
/// The `HttpLog` class allows you to start a local server to view logs in a
/// web browser. It supports sending logs for GET, POST, and POST_FILE requests.
class HttpLog {
  static bool _disableLogs = false;

  /// Stores the list of logs as a map.
  static final List<Map<String, dynamic>> _logs = [];

  /// The IP address of the device.
  static String? ipAddress;

  /// The HTTP server [_server] instance used for logging.
  // static HttpServer? _server;

  /// A controller where [_syncController] can be listened to more than once.
  static final _syncController = StreamController<String>.broadcast();

  static WebSocketChannel? _channel;

  /// Retrieves the device's IP address for IPv4.
  ///
  /// This method is used internally to fetch the local IP address, which is used
  /// to host the logging server.
  static Future<String?> _myIp() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: true);
      // Filter for common local network IPs (e.g., 192.168.*, 10.*, 172.*)
      final localIps = interfaces
          .expand((e) => e.addresses)
          .where(
              (a) => a.address.startsWith('192.') || a.address.startsWith('10.')
              // || a.address.startsWith('172.')
              )
          .map((a) => a.address)
          .toList();

      if (localIps.isNotEmpty) {
        if (localIps.any(((e) => e.startsWith('192.')))) {
          return localIps.firstWhere(
              ((e) => e.startsWith('192.'))); // Return the first valid local IP
        } else {
          return localIps.first;
        }
      }
    } catch (e) {
      // Handle IP fetch error
      // print('192.. IP is not found $e');
    }
    return null;
  }

  static bool get _isRealDevice => ipAddress?.startsWith('192.') ?? false;

  /// Starts the HTTP logging server on the device.
  ///
  /// The [context] parameter is required to show a dialog with the local server URL.
  /// If [isSandbox] is set to `true`, the server will run in sandbox mode.
  static void startServer(BuildContext context,
      {final bool isSandbox = true}) async {
    _disableLogs = !isSandbox;

    if (_disableLogs) return;

    ipAddress = await _myIp();

    if (ipAddress == null || ipAddress!.isEmpty) {
      _disableLogs = true;
      return;
    }

    try {
      final urlCltr = TextEditingController(text: '192.168.1.');

      final isRealDevice = _isRealDevice;

      if (isRealDevice) {
        final handler = Cascade()
            .add(_serveLogs)
            .add(webSocketHandler((WebSocketChannel webSocket) {
          _syncController.stream.listen((data) {
            webSocket.sink.add(data);
          });
        })).handler;

        final _server =
            await serve(handler, ipAddress ?? InternetAddress.anyIPv4, 9090);

        // log('HTTP Logger server running on http://${server.address.address}:${server.port}');
        urlCltr.text = "http://${_server.address.address}:${_server.port}/logs";
      } else {
        final _urllocal = await SharedPref.getUrl;

        if (_urllocal.isNotEmpty) urlCltr.text = _urllocal;
      }

      await showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) {
            return IpDialog(urlCltr: urlCltr, isRealDevice: isRealDevice);
          }).then((_) {
        if (!isRealDevice) {
          try {
            if (!urlCltr.text.trim().endsWith('.')) {
              SharedPref.setUrl = urlCltr.text;
              final url = 'ws://${urlCltr.text}:9090';
              _channel = WebSocketChannel.connect(Uri.parse(url));
            }
          } on SocketException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: ${e.message}'),
              duration: const Duration(seconds: 3),
            ));
            _channel = null;
          } catch (e) {
            _channel = null;
          }
          // print(url);
        }
      });
    } catch (e) {
      _disableLogs = true;
      return;
    }
  }

  // static void endServer() {
  //   if (_channel != null) {
  //     _channel?.sink.close();
  //   } else {
  //     _syncController.close();
  //   }
  // }

  static Response _serveLogs(Request request) {
    // print(request.url.path);
    if (request.url.path == 'logs') {
      return Response.ok(_generateHtmlContent().codeUnits, headers: {
        'Content-Type': 'text/html',
      });
    } else if (request.url.path == 'clear_logs' && request.method == 'POST') {
      clearLogs();
      return Response.ok('Logs cleared successfully');
    }
    return Response.notFound('Not found');
  }

  /// Logs HTTP request and response details.
  ///
  /// The [method] represents the HTTP method (GET, POST, etc.). The [url] is the
  /// target URL for the request. Optionally, you can provide [header], [request]
  /// payload, [statusCode], [duration] and [response].
  static void sendLog({
    required String method,
    required String url,
    Map<String, String>? header,
    Object? request,
    int? statusCode,
    int? duration,
    Object? response,
  }) {
    if (_disableLogs) return;

    Object? request0;
    Object? response0;

    try {
      if (request != null) {
        if (request is String && request.isNotEmpty) {
          request0 = json.decode(request);
        } else {
          request0 = request;
        }
      }
    } catch (e) {
      request0 = request.toString();
    }

    try {
      if (response != null) {
        if (response is String && response.isNotEmpty) {
          response0 = json.decode(response);
        } else {
          response0 = response;
        }
      }
    } catch (e) {
      response0 = response.toString();
    }
    final log = {
      'method': method,
      'url': url,
      'header': header,
      'request': request0,
      'status': statusCode,
      'duration': duration,
      'response': response0,
    };

    if (_channel != null && !_isRealDevice) {
      _channel!.sink.add(json.encode(log));
    } else {
      _syncController.add(json.encode(log));
      _logs.add(log);
    }
  }

  /// Returns the logs in JSON format.
  static String get logsJson => jsonEncode(_logs.reversed.toList());

  /// Clears all stored logs.
  static bool clearLogs() {
    _logs.clear();
    return true;
  }

  /// Generates HTML content for the log display in the browser.
  static String _generateHtmlContent() {
    final buffer = StringBuffer();

    buffer.write('''
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HTTP Logger</title>

    <style>

    

        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
        }

        .selected {
            background-color: #d3d3d3;
            color: #000;
        }

        .container {
            display: flex;
            height: 80vh;
            border-top: 1px solid #ccc;
        }

        #urlListContainer {
            flex: 1;
            border-right: 1px solid #ccc;
            overflow-y: auto;
            padding: 10px;
        }

        #resizer {
            width: 5px;
            background-color: #ccc;
            cursor: ew-resize;
        }

        #details {
            flex: 2;
            padding: 10px;
            overflow-y: auto;
        }

   
.header-container {
            display: flex;
            align-items: center;
            gap: 20px;
            background-color: #f8f9fa;
            border-bottom: 1px solid #ccc;
            padding-left: 10px;
        }
        
        .status {
            font-size: 1.2em;
            color: #ecf0f1;
        }

        .status.error {
            color: #e74c3c;
        }

        .status.success {
            color: #2ecc71;
        }

        .button-container {
            position: relative;
            margin: 10px;
        }

        .button-container button {
            padding: 10px;
            margin-right: 10px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }

        .button-container button:hover {
            background-color: #0056b3;
        }

        #clearButton {
            background-color: red;
        }
      
    </style>
</head>

<body>

<div class="header-container">
        <h2 class ="header-h3">HTTP Requests Log</h2>
        <div class="button-container">
        <button id="refreshButton" onclick="refreshPage()">Refresh</button>
        <button id="clearButton">Clear</button>
         
    </div>
      <div id="status" class="status">Connecting...</div>
    </div>

   

    <div class="container">
        <div id="urlListContainer">
            <h2>URLs</h2>
            <ul id="urlList"></ul>
        </div>
        <div id="resizer" onmousedown="startDragging(event)"></div>
        <div id="details">
            <p>Select a URL from the list to view details.</p>
        </div>
    </div>

    <script type="text/javascript">
       var logs = $logsJson;
        var selectedLogIndex = null;
        var isDragging = false;
        var startX;
        var startLeftWidth;

        const statusElement = document.getElementById('status');

        const serverHost = window.location.host;
        const serverIp = serverHost.split(':')[0];
        const wsPort = 9090;
        const wsUrl = `ws://\${serverIp}:\${wsPort}`;

        const socket = new WebSocket(wsUrl);

        socket.onopen = () => {
            statusElement.textContent = "Connected";
            statusElement.classList.remove("error");
            statusElement.classList.add("success");
        };

        socket.onerror = (error) => {
            console.error('WebSocket error:', error);
            statusElement.textContent = "Failed to connect. Check the server.";
            statusElement.classList.add("error");
            alert('Failed to connect to the server.');
        };

        socket.onclose = () => {
            statusElement.textContent = "Disconnected";
            statusElement.classList.remove("success");
            statusElement.classList.add("error");
            console.log('Disconnected from the server.');
        };

        socket.onmessage = async (event) => {
            const data = JSON.parse(event.data);
            logs.unshift(data);
            updateURLList();
            console.log("Log data added:", logs);
        };

        function updateURLList() {
            var urlList = document.getElementById('urlList');
            urlList.innerHTML = '';

            logs.forEach((log, index) => {
                var listItem = document.createElement('li');
                listItem.textContent = `\${log.method} | Status: \${log.status} | Duration: \${log.duration}ms \n: \${log.url}`;
                listItem.style.padding = '5px 0';
                listItem.onclick = function () {
                    displayDetails(index);
                };

                if (log.status !== 200) {
                    listItem.style.color = 'red';
                }

                if (index === logs.length - selectedLogIndex) {
                    listItem.classList.add('selected');
                }

                urlList.appendChild(listItem);
            });
        }

        function displayDetails(index) {
            var details = document.getElementById('details');
            var log = logs[index];

            if (log && log.url) {

                details.innerHTML = `
                  <div style="display: flex; align-items: center; gap: 20px;"> 
                    <h2>METHOD: \${log.method}</h2>
                    <button onclick="copyToClipboard()">Copy</button>
                    <label><input type="checkbox" id="headerCheckbox"> Include Header</label>
                </div>
                   </div>
                    <h3>Header</h3>
                    <pre>\${JSON.stringify(log.header, null, 2)}</pre>
                    <h3>URL: \${log.url}</h3>
                    \${log.request ? `<h3>Request</h3><pre>\${JSON.stringify(log.request, null, 2)}</pre>` : ''}
                    <h3>Status: \${log.status}</h3>
                    \${log.duration ? `<h3>Duration: \${log.duration}ms</h3>` : ''}
                    <h3>Response</h3>
                    \${log.response ? `<pre>\${JSON.stringify(log.response, null, 2)}</pre>` : ''}
                `;

                selectedLogIndex = logs.length - index;
                updateURLList();
            } else {
                details.innerHTML = '<p>Error: Log details not available.</p>';
            }
        }


// Function to copy formatted data to clipboard
function copyToClipboard() {
  var log = logs[logs.length - selectedLogIndex];
   var includeHeader = document.getElementById('headerCheckbox').checked;

     var dataToCopy = `URL: \${log.url}\n\n`;

      if (includeHeader) {
            dataToCopy += `Header:\n\${JSON.stringify(log.header, null, 2)}\n\n`;
        }

        dataToCopy += log.request ? `Request:\n\${JSON.stringify(log.request, null, 2)}\n\n` : '';
        dataToCopy += `Status: \${log.status}\n\n`;
        dataToCopy += log.duration ? `Duration: \${log.duration}ms\n\n` : '';
        dataToCopy += log.response ? `Response:\n\${JSON.stringify(log.response, null, 2)}` : '';

    const tempInput = document.createElement('textarea');
    tempInput.value = dataToCopy;
    document.body.appendChild(tempInput);
    tempInput.select();
    document.execCommand('copy');
    document.body.removeChild(tempInput);
    alert('Data copied to clipboard!');
}

        function startDragging(e) {
            isDragging = true;
            startX = e.clientX;
            startLeftWidth = document.getElementById('urlListContainer').offsetWidth;
            document.addEventListener('mousemove', drag);
            document.addEventListener('mouseup', stopDragging);
        }

        function drag(e) {
            if (isDragging) {
                var newLeftWidth = startLeftWidth + (e.clientX - startX);
                document.getElementById('urlListContainer').style.flex = '0 0 ' + newLeftWidth + 'px';
            }
        }

        function stopDragging() {
            isDragging = false;
            document.removeEventListener('mousemove', drag);
            document.removeEventListener('mouseup', stopDragging);
        }

        function refreshPage() {
            location.reload();
        }

        document.getElementById('clearButton').addEventListener('click', function () {

         // Call Dart's clearLogs function securely
    fetch('/clear_logs', { method: 'POST' })
        .then(response => {
            if (response.ok) {
                logs = []; // Clear the logs array in JavaScript
                selectedLogIndex = null; // Reset the selected log index
                updateURLList(); // Update the UI
                document.getElementById('details').innerHTML = '<p>No logs available. Logs have been cleared.</p>';
                console.log('Logs cleared successfully');
            } else {
                console.error('Failed to clear logs on server');
            }
        })
        .catch(error => console.error('Error clearing logs:', error));

      });

        window.onload = function () {
            updateURLList();
        };
    </script>
</body>

</html>
''');

    return buffer.toString();
  }
}
