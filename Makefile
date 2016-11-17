.PHONY: all
all: test

#
# Environment setup
#
.env: make_temp.sh
	./make_temp.sh > .env

env: clean_temp .env

.PHONY: clean_temp
clean: clean_temp
clean_temp:
	[ ! -e .env ] || ./clean_temp.sh

CLEAN += .setup
.setup: setup.sh env lib.sh
	./setup.sh
	touch $@

#
# Tests
#
.PHONY: test.sh
test.sh: .setup
	./test.sh

.PHONY: test
test: test.sh

clean:
	rm -rf $(CLEAN)
