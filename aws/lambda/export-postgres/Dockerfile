FROM public.ecr.aws/lambda/python:3.10-x86_64

RUN yum -y install postgresql postgresql-devel python-devel
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

COPY lambda_function.py ${LAMBDA_TASK_ROOT}
COPY main.py ${LAMBDA_TASK_ROOT}
COPY config ${LAMBDA_TASK_ROOT}/config
COPY utils ${LAMBDA_TASK_ROOT}/utils

CMD [ "lambda_function.handler" ]