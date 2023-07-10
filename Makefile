CC=dart pub global run melos
#CC_TEST=spec
CC_CHANGELOG=dart pub global run changelog_cmd

default: analyze check

dep:
	dart pub global activate melos 2.9.0;
	dart pub global activate changelog_cmd;
	$(CC) bootstrap

check: ci_check_client ci_check_flutter

fmt:
	$(CC) run format --no-select

analyze: fmt
	$(CC) run client_analyze --no-select
	$(CC) run flutter_analyze --no-select

client: ci_check_client ci_fmt_client

flutter: ci_check_flutter ci_fmt_flutter

ci_check_flutter:
	$(CC) run flutter_test --no-select

ci_check_client:
	$(CC) run client_test --no-select

ci_check_comm:
	$(CC) run comm_test --no-select

ci_fmt_client:
	$(CC) run client_analyze --no-select

ci_fmt_flutter:
	# FIXME: use client_analyze
	$(CC) run client_analyze --no-select

ci_fmt_comm:
	$(CC) run comm_analyze --no-select

ci_coverage_client:
	$(CC) run client_test_coverage --no-select

ci_coverage_flutter:
	$(CC) run flutter_test_coverage --no-select

check_client: ci_fmt_client ci_check_client

check_flutter: ci_fmt_flutter ci_check_flutter

check_comm: ci_fmt_comm ci_check_comm

changelog_client:
	cd packages/graphql && $(CC_CHANGELOG)

changelog_flutter:
	cd packages/graphql_flutter && $(CC_CHANGELOG)

changelog_comm:
	cd packages/graphql_common && $(CC_CHANGELOG)

changelog: changelog_client changelog_flutter

ci: dep check_comm check_client check_flutter

clean:
	$(CC) clean
