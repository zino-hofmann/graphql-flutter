import 'dart:async';

import 'package:gql/execution.dart';
import 'package:gql/link.dart';

Stream<Response> execute({
  Link link,
  Request request,
}) =>
    link.request(request);
