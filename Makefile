catch : 
	@echo "please specify a target"

build:
	docker build -t docker-lambda-gmail .

run:
	docker run --rm -p 8080:8080 docker-lambda-gmail
	# test command when container is up and running
	# curl -X POST "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{"recipient" : "hyden.testing@gmail.com", "subject" : "From lambda", "message" : "here is some custom message text"}'


# build production container with platform specified
build-prod:
	docker buildx build --platform linux/amd64 -t 743917738826.dkr.ecr.us-west-1.amazonaws.com/post-office-dev .


push-prod:
	# push the image to ECR repo
	docker push 743917738826.dkr.ecr.us-west-1.amazonaws.com/post-office-dev

update-func:
	# update the post-office-dev function to the latest image
	aws lambda update-function-code --function-name post-office-dev --image-uri 743917738826.dkr.ecr.us-west-1.amazonaws.com/post-office-dev:latest

release-prod: build-prod push-prod update-func

# re-login to elastic container registry (ECR)
login:
	aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 743917738826.dkr.ecr.us-west-1.amazonaws.com