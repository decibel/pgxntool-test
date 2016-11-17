.PHONY: all
all: test

#
# Environment setup
#
temp.env: make_temp.sh
	./make_temp.sh > temp.env

.PHONY: clean_temp
clean: clean_temp
clean_temp:
	[ ! -e temp.env ] || ./clean_temp.sh


#
# Tests
#
.PHONY: test.sh
test.sh: temp.env lib.sh
	./test.sh

.PHONY: test
test: clean test.sh

clean:
	rm -rf $(CLEAN)
