# Example Dart Application 

This is a simple command line application to showcase how you can use the Dart GraphQL Client, without flutter. 

To run this applications:

1. First clone this repository and navigate to this directory
2. Install all dart dependancies
3. The run the Application using the commands below:
   
   1. **List Your Repositories**

   ```
   pub run main.dart
   ```

   1. **Star Repository**

   ```
   pub run main.dart -a star --id <REPOSITORY_ID_HERE>
   ```

   1. **Unstar Repository**

   ```
   pub run main.dart -a unstar --id <REPOSITORY_ID_HERE>
   ```

**NB:** Replace repository id in the last two commands with a real Github Repository ID. You can get by running the first command, IDs are printed on the console. 
