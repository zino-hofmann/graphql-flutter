CC=dart
CC_UI=flutter


default: fmt dep
	@echo "Please run \"make server !&\" to run the server"


dep:
	cd server; $(CC) pub get
	$(CC_UI) pub get

server:
	$(CC) pub run graphql_starwars_test_server

fmt:
	$(CC_UI) format .
	$(CC_UI) analyze .

clean:
	$(CC_UI) clean
