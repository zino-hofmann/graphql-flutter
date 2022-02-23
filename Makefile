CC=dart pub global run melos
CC_TEST=spec

default: analyze check

dep:
	dart pub global activate melos;
	dart pub global activate spec_cli;
	export PATH="$PATH":"$HOME/.pub-cache/bin";
	$(CC) bootstrap

check:
	$(CC_TEST)

fmt:
	$(CC) run format --no-select

analyze: fmt
	$(CC) run analyze --no-select

ci_check:
	$(CC) run test --no-select

ci_check_flutter:
	$(CC) run flutter_test --no-select

ci_check_client:
	$(CC) run client_test --no-select

ci_fmt_client:
	$(CC) run client_analyze --no-select

check_client: ci_check_client

ci: dep ci_check

clean:
	$(CC) clean