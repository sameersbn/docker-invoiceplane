all: build

build:
	@docker build --tag=sameersbn/invoiceplane:latest .

release: build
	@docker build --tag=sameersbn/invoiceplane:$(shell cat VERSION) .
