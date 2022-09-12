CC=flutter
FMT=format
PATH=

default: get fmt check

get:
	$(CC) pub get

generate:
	$(CC) pub run build_runner build --delete-conflicting-outputs;

fmt:
	$(CC) $(FMT) .
	$(CC) analyze .

check:
	$(CC) test

clean:
	$(CC) clean

run:
	$(CC) run -d linux

dep_upgrade:
	$(CC) pub upgrade --major-versions
