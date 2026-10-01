.PHONY: help

# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: dl_mnist

dl_mnist: ## Download MNIST dataset
	@echo "Downloading MNIST dataset"
	wget -O mnist_test.csv https://data.pjreddie.com/files/mnist_test.csv
	wget -O mnist_train.csv https://data.pjreddie.com/files/mnist_train.csv

.PHONY: sep_label

sep_label: ## Separate label from features
	@echo "Separating label from features"
	sed -r "s/([0-9]),/\1|/" mnist_test.csv > mnist_test_sep.csv
	sed -r "s/([0-9]),/\1|/" mnist_train.csv > mnist_train_sep.csv

DATASET_TEST ?= mnist_test
DATASET_TRAIN ?= mnist_train

.PHONY: convert convert_parquet

convert: ## Convert CSV to JSONL, one sample per row (DATASET_TRAIN=mnist_train to override)
	@echo "Converting $(DATASET_TRAIN)_sep.csv to $(DATASET_TRAIN).jsonl"
	input=$(DATASET_TRAIN)_sep.csv output=$(DATASET_TRAIN).jsonl envsubst < convert.sql | duckdb
	@echo "Converting $(DATASET_TEST)_sep.csv to $(DATASET_TEST).jsonl"
	input=$(DATASET_TEST)_sep.csv output=$(DATASET_TEST).jsonl envsubst < convert.sql | duckdb

convert_parquet: ## Convert CSV to Parquet with ZSTD compression (DATASET_TRAIN=mnist_train to override)
	@echo "Converting $(DATASET_TRAIN)_sep.csv to $(DATASET_TRAIN).parquet"
	input=$(DATASET_TRAIN)_sep.csv output=$(DATASET_TRAIN).parquet envsubst < convert_parquet.sql | duckdb
	@echo "Converting $(DATASET_TEST)_sep.csv to $(DATASET_TEST).parquet"
	input=$(DATASET_TEST)_sep.csv output=$(DATASET_TEST).parquet envsubst < convert_parquet.sql | duckdb
