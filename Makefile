CC=dart pub global run melos
CC_TEST=spec

default: analyze check

dep:
	dart pub global activate melos;
	dart pub global activate spec_cli;
	$(CC) bootstrap

check:
	$(CC_TEST)

fmt:
	$(CC) run format --no-select

analyze: fmt
	$(CC) run analyze --no-select

ci_check_flutter:
	$(CC) run flutter_test --no-select

ci_check_client:
	$(CC) run client_test --no-select

ci_fmt_client:
	$(CC) run client_analyze --no-select

ci_fmt_flutter:
	$(CC) run client_analyze --no-select

ci_coverage_client:
	$(CC) run client_test_coverage --no-select

ci_coverage_flutter:
	$(CC) run flutter_test_coverage --no-select

check_client: ci_fmt_client ci_check_client

check_flutter: ci_fmt_flutter ci_check_flutter

ci: dep check_client check_flutter

clean:
	$(CC) clean