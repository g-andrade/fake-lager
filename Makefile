REBAR3_URL=https://s3.amazonaws.com/rebar3/rebar3

ifeq ($(wildcard rebar3),rebar3)
	REBAR3 = $(CURDIR)/rebar3
endif

ifdef RUNNING_ON_CI
REBAR3 = ./rebar3
else
REBAR3 ?= $(shell test -e `which rebar3` 2>/dev/null && which rebar3 || echo "./rebar3")
endif

ifeq ($(REBAR3),)
	REBAR3 = $(CURDIR)/rebar3
endif

.PHONY: all build clean check dialyzer xref
.PHONY: test cover
.PHONY: console doc publish

.NOTPARALLEL: check cover test

all: build

build: $(REBAR3)
	@$(REBAR3) compile

$(REBAR3):
	wget $(REBAR3_URL) || curl -Lo rebar3 $(REBAR3_URL)
	@chmod a+x rebar3

clean: $(REBAR3)
	@$(REBAR3) clean

check: dialyzer xref

dialyzer: $(REBAR3)
	@$(REBAR3) dialyzer

xref: $(REBAR3)
	@$(REBAR3) xref

test: $(REBAR3) cli
	@$(REBAR3) ct

cover: $(REBAR3) test
	@$(REBAR3) cover

console: export ERL_FLAGS =? +pc unicode
console:
	@$(REBAR3) as development shell --apps lager

doc: $(REBAR3)
	@$(REBAR3) edoc

README.md: doc
	# non-portable dirty hack follows (pandoc 2.1.1 used)
	# gfm: "github-flavoured markdown"
	@pandoc --from html --to gfm doc/overview-summary.html -o README.md
	@tail -n +11 <"README.md"   >"README.md_"
	@head -n -14 <"README.md_"  >"README.md"
	@rm "README.md_"

publish: $(REBAR3)
	@$(REBAR3) as publish hex publish
	@$(REBAR3) as publish hex docs
