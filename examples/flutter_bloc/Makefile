CC=flutter

default: fmt dep

dep:
	$(CC) pub get

check:
	$(CC) test .

fmt:
	$(CC) format .
	$(CC) analyze .

clean:
	$(CC) clean