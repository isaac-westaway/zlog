name = zlog

files = src/Logger.zig

.PHONY: build
build:
	zig build

.PHONY: test
test:
	for file in $(files); do zig test $$file; done

.PHONY: clean
clean:
	rm -rf zig-out .zig-cache
	rm -rf *.log

all: build test