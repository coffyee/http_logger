import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// A class for logging HTTP requests and responses in real-time.
///
/// The `HttpLog` class allows you to start a local server to view logs in a
/// web browser. It supports sending logs for GET, POST, and POST_FILE requests.
class HttpLog {
  static bool _disableLogs = false;

  /// Stores the list of logs as a map.
  static final List<Map<String, dynamic>> _logs = [];

  /// The IP address of the device.
  static String? ipAddress = "";

  /// Retrieves the device's IP address for IPv4.
  ///
  /// This method is used internally to fetch the local IP address, which is used
  /// to host the logging server.
  static Future<String?> _myIp() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: true);
      return interfaces
          .where((e) => e.addresses.first.address.indexOf('192.') == 0)
          .first
          .addresses
          .first
          .address;
    } catch (e) {
      // Handle IP fetch error
      // print('192.. IP is not found $e');
    }
    return null;
  }

  static late String? _ip;

  /// Starts the HTTP logging server on the device.
  ///
  /// The [context] parameter is required to show a dialog with the local server URL.
  /// If [isSandbox] is set to `true`, the server will run in sandbox mode.
  static void startServer(BuildContext context,
      {final bool isSandbox = true}) async {
    _disableLogs = !isSandbox;

    if (_disableLogs) return;

    try {
      _ip = await _myIp();
      final server = await HttpServer.bind(_ip, 9090, shared: true);
      // log('HTTP Logger server running on http://${server.address.address}:${server.port}');
      final _url = "http://${server.address.address}:${server.port}/logs";
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                const Center(
                  child: Text(
                    "IP Address",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black26)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: SelectableText(
                      _url,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Close")),
              ],
            );
          });

      await for (HttpRequest request in server) {
        if (request.uri.path == '/clear_logs' && request.method == 'POST') {
          clearLogs();
          request.response
            ..statusCode = HttpStatus.ok
            ..write('Logs cleared successfully')
            ..close();
        } else if (request.uri.path == '/logs') {
          // print('-----refresh');
          request.response
            ..headers.contentType = ContentType.html
            ..write(_generateHtmlContent())
            ..close();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found')
            ..close();
        }
      }
    } catch (e) {
      _disableLogs = true;
      return;
      // print("HTTP Local Server Error : $e");
    }
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

    Object? _request;
    Object? _response;

    try {
      if (request != null) {
        if (request is String && request.isNotEmpty) {
          _request = json.decode(request);
        } else {
          _request = request;
        }
      }
    } catch (e) {
      _request = request.toString();
    }

    try {
      if (response != null) {
        if (response is String && response.isNotEmpty) {
          _response = json.decode(response);
        } else {
          _response = response;
        }
      }
    } catch (e) {
      _response = response.toString();
    }
    final log = {
      'method': method,
      'url': url,
      'header': header,
      'request': _request,
      'status': statusCode,
      'duration': duration,
      'response': _response,
    };

    _logs.add(log);
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
    buffer.write('<html><head><title>HTTP Logger</title>');

    buffer.write('''
<script type="text/javascript">
    var logs = $logsJson; // Store logs data to manage view
    var selectedLogIndex = null; // Track the currently selected log
    var isDragging = false; // Track dragging status for the resizer
    var startX; // Starting mouse X position
    var startLeftWidth; // Starting width of the left container

    function updateURLList() {
        console.log('Updating URL list with logs:', logs); // Debugging line
        var urlList = document.getElementById('urlList');

        urlList.innerHTML = '';
        logs.forEach(function(log, index) {
            var listItem = document.createElement('li');
            listItem.textContent = `\${log.method} | Status: \${log.status} | Duration: \${log.duration}ms \n: \${log.url}`;
            listItem.onclick = function() {
                displayDetails(index);
            };

            if (log.status !== 200) {
                listItem.style.color = 'red';
            }

            if (index === selectedLogIndex) {
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
                <h2>METHOD: \${log.method}</h2>
                 <h3>Header</h3>
                <pre>\${JSON.stringify(log.header, null, 2)}</pre>
                <h3>URL: \${log.url}</h3>
                <h3 style=\${log.request == null ? "display:none" : ""}>Request</h3>
                <pre style=\${log.request == null ? "display:none" : ""}>\${JSON.stringify(log.request, null, 2)}</pre>
                <h3>Status: \${log.status}</h3>
                <h3 style=\${log.duration == null ? "display:none" : ""}>Duration: \${log.duration}ms</h3>
                <h3>Response</h3>
                <pre style=\${log.response == null ? "display:none" : ""}>\${JSON.stringify(log.response, null, 2)}</pre>
            `;

            selectedLogIndex = index;
            updateURLList();
        } else {
            details.innerHTML = '<p>Error: Log details not available.</p>';
        }
    }

    // Draggable divider functionality
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
        window.location.reload();
    }

    window.onload = function() {
        updateURLList();
    };

   document.addEventListener('DOMContentLoaded', function () {
    const clearButton = document.getElementById('clearButton');
    if (clearButton) {
        clearButton.addEventListener('click', function () {
            clearLogs();
        });
    } else {
        console.error('Clear Button not found in the DOM');
    }
});


function clearLogs() {
    // Prevent accidental triggering
    console.log('Clear Logs button clicked');
    
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
}


</script>

<style>
    .selected {
        background-color: #d3d3d3;
        color: #000;
    }

    #resizer {
        width: 5px;
        background-color: #ccc;
        cursor: ew-resize;
    }

    #refreshButton, #clearButton {
        position: fixed;
        top: 10px;
        padding: 10px;
        background-color: #007bff;
        color: white;
        border: none;
        border-radius: 5px;
        cursor: pointer;
    }

    #refreshButton:hover, #clearButton:hover {
        background-color: #0056b3;
    }

    #refreshButton {
        left: 320px;
    }

    #clearButton {
        left: 400px;
         background-color: red;
    }
</style>
''');

    buffer.write('</head><body>');
    buffer.write('<h1>HTTP Requests Log</h1>');

// Add the refresh and clear buttons
    buffer.write(
        '<button id="refreshButton" onclick="refreshPage()">Refresh</button>');
    buffer.write('<button id="clearButton">Clear</button>');

    buffer.write('<div style="display: flex; height: 80vh;">');

// Left side: List of URLs
    buffer.write(
        '<div id="urlListContainer" style="flex: 1; border-right: 1px solid #ccc; overflow-y: auto; padding: 10px;">');
    buffer.write('<h2>URLs</h2>');
    buffer.write('<ul id="urlList"></ul>');
    buffer.write('</div>');

// Resizer divider
    buffer.write('<div id="resizer" onmousedown="startDragging(event)"></div>');

// Right side: Log details
    buffer.write(
        '<div id="details" style="flex: 2; padding: 10px; overflow-y: auto;">');
    buffer.write('<p>Select a URL from the list to view details.</p>');
    buffer.write('</div>');

    buffer.write('</div>'); // End of split-screen layout

    buffer.write('</body></html>');

    return buffer.toString();
  }
}
