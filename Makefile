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

analyze:
	$(CC) run format --no-select
	$(CC) run analyze --no-select

ci_check:
	$(CC) run test --no-select

ci: dep ci_check

clean:
	$(CC) clean