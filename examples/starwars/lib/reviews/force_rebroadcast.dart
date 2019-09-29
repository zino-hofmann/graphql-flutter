import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ForceRebroadcast extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: r'''
        mutation Rebroadcast {
        }
        ''',
      ),
      builder: (runMutation, result) {
        return result.loading
            ? RaisedButton(
                onPressed: null,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : RaisedButton(
                onPressed: () {
                  runMutation({});
                },
                child: Text('REBROADCAST'),
              );
      },
    );
  }
}
