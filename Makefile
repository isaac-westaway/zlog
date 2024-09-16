name = zlog

files = src/Logger.zig

.PHONY: build
build:
	zig build

.PHONY: run
run:
	zig build run

.PHONY: test
test:
	for file in $(files); do zig test $$file; done

.PHONY: clean
clean:
	rm -rf zig-out .zig-cache
	rm -r *.log

all: build test clean