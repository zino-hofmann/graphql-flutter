# `graphql/client.dart` Example Application

This is a simple command line application to showcase how you can use the Dart GraphQL Client, without flutter.

To run this application:

## Setup:

1. First clone this repository and navigate to this directory
2. Install all dart dependencies
3. replace `<YOUR_PERSONAL_ACCESS_TOKEN>` in `lib/local.dart` with your GitHub token
## Usage:

```sh
# List repositories
pub run example

# Star Repository (you can get repository ids from `pub run example`)
pub run example -a star --id $REPOSITORY_ID

# Unstar Repository
pub run example -a unstar --id $REPOSITORY_ID
```

**NB:** Replace repository id in the last two commands with a real Github Repository ID. You can get by running the first command, IDs are printed on the console.
