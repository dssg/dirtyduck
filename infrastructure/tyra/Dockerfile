FROM python:3.6

RUN apt-get -y update && \
    apt-get install unzip sudo && \
    wget https://github.com/dssg/tyra/archive/master.zip && \
    unzip master.zip



ADD default_profile.yaml /tyra-master
ADD example_users.json /tyra-master

WORKDIR /tyra-master/frontend

RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && \
    apt-get install -y nodejs && \
    npm cache clean -f && \
    npm install  -g n && \
    n stable && \
    npm install npm@latest -g && \
    npm install && \
    npm run build

WORKDIR /tyra-master

RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT [ "python" ]
CMD [ "run_webapp.py" ]
