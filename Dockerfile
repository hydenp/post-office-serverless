FROM public.ecr.aws/lambda/python:3.9

# install requirements
COPY requirements.txt  .
RUN  pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# copy source code
COPY src/ ${LAMBDA_TASK_ROOT}

CMD [ "app.handler" ]