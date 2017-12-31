FROM python:3.6

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir triage_experiment

WORKDIR triage_experiment

COPY triage_experiment.py /triage_experiment/
COPY utils.py /triage_experiment/
COPY setup.py /triage_experiment/

RUN pip install --editable .

ENTRYPOINT [ "triage_experiment" ]
