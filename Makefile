CC       ?= gcc
CFLAGS   ?= -g -O2 -Wall -Wextra -Werror
CFLAGS   += -std=gnu99 -fPIC
CPPFLAGS += -I$(BASH_INCDIR)
LDFLAGS  ?= -shared -Wl,-soname,$@

##########

# Use Gentoo's path as default
BASH_INCDIR ?= /usr/include/bash-plugins

.PHONY: all
all: CHECK_DIRS vimps1

.PHONY: CHECK_DIRS
CHECK_DIRS:
	@if ! test -f '$(BASH_INCDIR)'/builtins.h; then \
	  echo 'error: cannot find Bash headers at $(BASH_INCDIR)' >&2; \
	  echo 'maybe: $$ make BASH_INCDIR=/path/to/find/bash/builtins.h/at' >&2; \
	  exit 1; \
	fi

vimps1: vimps1.c

.PHONY: clean
clean:
	$(RM) vimps1
