plan:
	terraform plan -var-file=${FILE_NAME}
	
deploy:
	terraform apply -var-file=${FILE_NAME}