import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Uses a local test server for consistent, cache-free testing.
// Start it with: dart run tool/test_server.dart --delay=500
// The server delays 500ms before responding, giving plenty of time to cancel.
const _serverUrl = 'http://localhost:4000/graphql';

const _countriesQuery = r'''
  query GetCountries {
    countries {
      code
      name
      continent { name }
      languages { name }
    }
  }
''';

// Simple mutation for file upload demo (won't actually work without a
// proper server, but demonstrates the structure)
const _uploadMutation = r'''
  mutation UploadFile($file: Upload!) {
    uploadFile(file: $file) {
      id
      filename
    }
  }
''';

/// Demonstrates request cancellation with both standard HttpLink
/// and CancellableHttpLink.
///
/// Key difference:
/// - **HttpLink** (from gql_http_link): Standard HTTP link, cancellation only
///   prevents processing the response but doesn't abort the HTTP request.
/// - **CancellableHttpLink**: New opt-in link that truly aborts HTTP requests
///   at the network level (uses XMLHttpRequest.abort() on web,
///   HttpClientRequest.abort() on IO).
class GraphQLCancellationDemo extends StatefulWidget {
  const GraphQLCancellationDemo({Key? key}) : super(key: key);

  @override
  State<GraphQLCancellationDemo> createState() =>
      _GraphQLCancellationDemoState();
}

class _GraphQLCancellationDemoState extends State<GraphQLCancellationDemo> {
  CancellableOperation<QueryResult<Object?>>? _operation;
  CancellableOperation<QueryResult<Object?>>? _uploadOperation;
  Timer? _cancelTimer;
  String _status = 'Ready to make request';
  bool _isLoading = false;
  // Default to 100ms - local server responds after 500ms so plenty of margin.
  final TextEditingController _delayController =
      TextEditingController(text: '100');
  final List<String> _logs = [];

  int get _cancelDelayMs => int.tryParse(_delayController.text) ?? 50;

  void _log(String message, {int level = 0}) {
    developer.log(message, name: 'GraphQLRequest', level: level);
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 23)}: $message');
      if (_logs.length > 20) _logs.removeAt(0);
    });
  }

  // Standard HttpLink client - cancellation only skips response processing
  GraphQLClient _buildHttpLinkClient() => GraphQLClient(
        cache: GraphQLCache(),
        link: HttpLink(_serverUrl),
      );

  // CancellableHttpLink client - true HTTP-level cancellation
  GraphQLClient _buildCancellableHttpLinkClient() => GraphQLClient(
        cache: GraphQLCache(),
        link: CancellableHttpLink(_serverUrl),
      );

  Future<void> _startQueryWithHttpLink() async {
    await _startQuery(
      client: _buildHttpLinkClient(),
      linkName: 'HttpLink',
    );
  }

  Future<void> _startQueryWithCancellableHttpLink() async {
    await _startQuery(
      client: _buildCancellableHttpLinkClient(),
      linkName: 'CancellableHttpLink',
    );
  }

  Future<void> _startQuery({
    required GraphQLClient client,
    required String linkName,
  }) async {
    setState(() {
      _isLoading = true;
      _status = 'Query in progress with $linkName...';
    });

    _log(
        'Starting query with $linkName — will auto-cancel in ${_cancelDelayMs}ms');

    // Schedule automatic cancellation after the configured delay.
    _cancelTimer = Timer(Duration(milliseconds: _cancelDelayMs), () {
      _log('Auto-cancelling after ${_cancelDelayMs}ms...');
      _operation?.cancel();
    });

    // queryCancellable() creates a CancellationToken internally and returns
    // a CancellableOperation that exposes both .result and .cancel().
    _operation = client.queryCancellable(
      QueryOptions(
        document: gql(_countriesQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    final result = await _operation!.result;
    _cancelTimer?.cancel();

    if (!mounted) return;

    if (result.hasException) {
      final linkEx = result.exception!.linkException;
      if (linkEx is CancelledException) {
        _log('Query was cancelled ($linkName)', level: 800);
        setState(() {
          _status = 'Query was cancelled!\n(using $linkName)';
          _isLoading = false;
        });
      } else {
        _log('Query failed: ${result.exception}', level: 1000);
        setState(() {
          _status = 'Query failed:\n${result.exception}';
          _isLoading = false;
        });
      }
      return;
    }

    final count = (result.data?['countries'] as List?)?.length ?? 0;
    _log('Query completed – $count countries received ($linkName)');
    setState(() {
      _status = 'Query completed with $linkName!\nLoaded $count countries.';
      _isLoading = false;
    });
  }

  Future<void> _testFileUpload({required bool cancellable}) async {
    setState(() {
      _isLoading = true;
      _status =
          'File upload in progress (${cancellable ? "cancellable" : "non-cancellable"})...';
    });

    final linkName = cancellable ? 'CancellableHttpLink' : 'HttpLink';
    _log('Starting file upload with $linkName');

    // Create a mock file for upload
    final fileContent = 'Hello, this is a test file for GraphQL upload!';
    final multipartFile = http.MultipartFile.fromString(
      'file',
      fileContent,
      filename: 'test_upload.txt',
      contentType: MediaType('text', 'plain'),
    );

    final client = cancellable
        ? GraphQLClient(
            cache: GraphQLCache(),
            link: CancellableHttpLink(_serverUrl),
          )
        : GraphQLClient(
            cache: GraphQLCache(),
            link: HttpLink(_serverUrl),
          );

    if (cancellable) {
      // Schedule automatic cancellation
      _cancelTimer = Timer(Duration(milliseconds: _cancelDelayMs), () {
        _log('Auto-cancelling file upload after ${_cancelDelayMs}ms...');
        _uploadOperation?.cancel();
      });

      _uploadOperation = client.mutateCancellable(
        MutationOptions(
          document: gql(_uploadMutation),
          variables: {'file': multipartFile},
        ),
      );

      try {
        final result = await _uploadOperation!.result;
        _cancelTimer?.cancel();

        if (!mounted) return;

        if (result.hasException) {
          final linkEx = result.exception!.linkException;
          if (linkEx is CancelledException) {
            _log('File upload was cancelled', level: 800);
            setState(() {
              _status = 'File upload was cancelled!';
              _isLoading = false;
            });
          } else {
            // httpbin.org returns JSON but not in GraphQL format,
            // so we'll see a parse error - that's expected for this demo
            _log('Upload completed (parse error expected for httpbin)');
            setState(() {
              _status =
                  'File upload sent!\n(httpbin.org echoes the request back)';
              _isLoading = false;
            });
          }
          return;
        }

        _log('File upload completed');
        setState(() {
          _status = 'File upload completed!';
          _isLoading = false;
        });
      } catch (e) {
        _log('File upload error: $e', level: 1000);
        setState(() {
          _status =
              'File upload sent to httpbin.org\n(Demo: parse error expected)';
          _isLoading = false;
        });
      }
    } else {
      // Non-cancellable upload
      try {
        await client.mutate(
          MutationOptions(
            document: gql(_uploadMutation),
            variables: {'file': multipartFile},
          ),
        );

        if (!mounted) return;

        _log('Non-cancellable file upload completed');
        setState(() {
          _status =
              'Non-cancellable file upload sent!\n(httpbin.org echoes back)';
          _isLoading = false;
        });
      } catch (e) {
        _log('File upload error: $e', level: 1000);
        setState(() {
          _status =
              'File upload sent to httpbin.org\n(Demo: parse error expected)';
          _isLoading = false;
        });
      }
    }
  }

  void _cancelCurrentOperation() {
    _cancelTimer?.cancel();
    _log('Manually cancelling operation...');
    _operation?.cancel();
    _uploadOperation?.cancel();
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    _delayController.dispose();
    _cancelCurrentOperation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Cancellation Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link Types',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const SelectableText(
                      '• HttpLink: Standard link from gql_http_link\n'
                      '• CancellableHttpLink: New link with true HTTP abort\n\n'
                      'Run: dart run tool/test_server.dart --delay=500\n'
                      'Server responds after 500ms, cancel fires at 100ms.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delay input
            TextField(
              controller: _delayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Auto-cancel delay',
                border: OutlineInputBorder(),
                suffixText: 'ms',
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Status
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Query buttons
            Text(
              'Query Tests',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startQueryWithHttpLink,
                  icon: const Icon(Icons.http),
                  label: const Text('HttpLink'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : _startQueryWithCancellableHttpLink,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('CancellableHttpLink'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // File upload buttons
            Text(
              'File Upload Tests',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _testFileUpload(cancellable: false),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload (HttpLink)'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _testFileUpload(cancellable: true),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload (Cancellable)'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cancel button
            OutlinedButton.icon(
              onPressed: _isLoading ? _cancelCurrentOperation : null,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Logs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Logs',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton(
                  onPressed: _clearLogs,
                  child: const Text('Clear'),
                ),
              ],
            ),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(
                  _logs[index],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
