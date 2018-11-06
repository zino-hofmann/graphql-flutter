import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import './mutations/mutations.dart' as mutations;

class StarrableRepository extends StatefulWidget {
  const StarrableRepository({
    Key key,
    @required this.repository,
  }) : super(key: key);

  final Map<String, Object> repository;

  @override
  StarrableRepositoryState createState() {
    return new StarrableRepositoryState();
  }
}

class StarrableRepositoryState extends State<StarrableRepository> {
  bool loading = false;

  Map<String, Object> extractRepositoryData(Map<String, Object> data) {
    final Map<String, Object> action = data['action'];
    if (action == null) {
      return null;
    }
    return action['starrable'];
  }

  bool get viewerHasStarred => widget.repository['viewerHasStarred'];

  @override
  Widget build(BuildContext context) {
    final bool starred = loading ? !viewerHasStarred : viewerHasStarred;
    return Mutation(
      key: Key(starred.toString()),
      options: MutationOptions(
        document: starred ? mutations.removeStar : mutations.addStar,
      ),
      builder: (RunMutation toggleStar, QueryResult result) {
        return ListTile(
          leading: starred
              ? const Icon(
                  Icons.star,
                  color: Colors.amber,
                )
              : const Icon(Icons.star_border),
          trailing: loading ? const CircularProgressIndicator() : null,
          title: Text(widget.repository['name']),
          onTap: () {
            // optimistic ui updates are not implemented yet,
            // so we track loading manually
            setState(() {
              loading = true;
            });
            toggleStar(<String, dynamic>{
              'starrableId': widget.repository['id'],
            });
          },
        );
      },
      update: (Cache cache, QueryResult result) {
        if (result.hasErrors) {
          print(result.errors);
        } else {
          final Map<String, Object> updated =
              Map<String, Object>.from(widget.repository)
                ..addAll(extractRepositoryData(result.data));
          cache.write(typenameDataIdFromObject(updated), updated);
        }
      },
      onCompleted: (QueryResult result) {
        showDialog<AlertDialog>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                extractRepositoryData(result.data)['viewerHasStarred']
                    ? 'Thanks for your star!'
                    : 'Sorry you changed your mind!',
              ),
              actions: <Widget>[
                SimpleDialogOption(
                  child: const Text('Dismiss'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          },
        );
        setState(() {
          loading = false;
        });
      },
    );
  }
}
