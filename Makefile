

all:
	@echo "Commands:"
	@echo "    copy-file -> Info on copying files"
	@echo "    clean     -> Remove cache and rails VCR cassettes"
	@echo "    test      -> Run the rspec tests"

copy-file:
	@echo "  kubectl get pods --namespace offender-management-staging"
	@echo "  kubectl cp /tmp/foo offender-management-staging/<some-pod>:/tmp/bar"

clean:
	@-rake tmp:cache:clear
	@-rm spec/fixtures/vcr_cassettes/*.yml

test: clean
	@bundle exec rspec
