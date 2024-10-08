DIRS = lux

build:
	@for d in $(DIRS) ; do \
	  $(MAKE) -C $$d build || exit 1; \
	done

clean:
	@for d in $(DIRS) ; do \
	  $(MAKE) -C $$d clean || exit 1; \
	done

test:
	@for d in $(DIRS) ; do \
	  $(MAKE) -C $$d test || exit 1; \
	done

desc:
	@for d in $(DIRS) ; do \
	  $(MAKE) -C $$d desc || exit 1; \
	done