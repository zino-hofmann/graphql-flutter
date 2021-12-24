CC=flutter

default: fmt dep

dep:
	$(CC) pub get

fmt:
	$(CC) format .
	$(CC) analyze .

clean:
	$(CC) clean