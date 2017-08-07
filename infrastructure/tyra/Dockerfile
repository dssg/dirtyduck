FROM python:3.6

RUN apt-get -y update && \
    apt-get install unzip && \
    wget https://github.com/dssg/tyra/archive/master.zip && \
    unzip master.zip



WORKDIR /tyra-master

ADD default_profile.yaml /tyra-master

RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT [ "python" ]
CMD [ "run_webapp.py" ]
