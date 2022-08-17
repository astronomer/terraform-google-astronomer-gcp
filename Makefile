.PHONY: clean

clean:
	find . -name "*.terraform" -type d -exec rm -rf {} + || true
	find . -name "*.terraform.lock.hcl" -type f -delete || true
	find . -name "*.tfplan" -type f -delete || true
