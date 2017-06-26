FROM python:3.6

ENV DOCKER_VERSION latest
RUN curl -o docker.tgz https://get.docker.com/builds/Linux/x86_64/docker-$DOCKER_VERSION.tgz && \
    tar zxpf docker.tgz -C /tmp/
RUN mv /tmp/docker/* /usr/bin && rm docker.tgz
RUN chmod 755 /usr/bin/docker


ENV BASE /vigilamos
ARG PROJECT_NAME

WORKDIR $BASE

ADD $PROJECT_NAME $BASE/$PROJECT_NAME
ADD requirements.txt $BASE/
RUN pip install -r requirements.txt

ADD setup.py tox.ini MANIFEST.in README.org $BASE/
RUN pip install --editable .

ENV LUIGI_CONFIG_PATH $BASE/$PROJECT_NAME/pipelines/luigi.cfg
