# A Flutter GraphQL example using "graphql" with "flutter_bloc"

This example uses [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) package for state management and [`graphql`](https://pub.dev/packages/graphql) package to connect to GitHubs' GraphQL API to fetch and star/un-star your repositories.

## Running this example

Before running this example, make sure to create a `local.dart` file inside the `lib` directory, and add your Github token, as shown below:

```dart
const String YOUR_PERSONAL_ACCESS_TOKEN =
   '<YOUR_PERSONAL_ACCESS_TOKEN>';
```
