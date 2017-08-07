FROM python:3.6

RUN apt-get -y update && \
    apt-get install unzip && \
    wget https://github.com/dssg/tyra/archive/master.zip && \
    unzip master.zip



WORKDIR /tyra-master

ADD default_profile.yaml /tyra-master

RUN pip install -r requirements.txt

ENTRYPOINT ["python", "run_webapp.py"]
