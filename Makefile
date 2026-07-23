.PHONY: validate test

validate:
	ruby tools/validate_soas.rb

test:
	ruby -Itest test/soas_validation_test.rb
