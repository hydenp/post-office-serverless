catch : 
	@echo "please specify a target"

build:
	docker build -t docker-lambda-gmail .

run:
	docker run --rm -p 8080:8080 docker-lambda-gmail
# test command when container is up and running
# curl -XPOST "http://localhost:8080/2015-03-31/functions/function/invocations" -d '{"recipient" : "hyden.testing@gmail.com", "subject" : "From lambda", "message" : "here is some custome message text"}'


# build production container with platform specified
build-prod:
	docker buildx build --platform linux/amd64 -t 743917738826.dkr.ecr.us-west-1.amazonaws.com/mailthem-test .

push-prod:
	docker push 743917738826.dkr.ecr.us-west-1.amazonaws.com/mailthem-test