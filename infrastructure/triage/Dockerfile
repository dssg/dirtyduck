FROM python:3.6

LABEL triage.version="v2.2.0" \
      triage.fs="local file" \
      triage.experiment="single threaded" \
      creator="Center for Data Science and Public Policy (DSaPP)" \
      maintainer="Adolfo De Unánue <adolfo@uchicago.edu>"

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir triage_experiment

WORKDIR triage_experiment

COPY triage_experiment.py /triage_experiment/
COPY utils.py /triage_experiment/
COPY setup.py /triage_experiment/

RUN pip install --editable .

ENTRYPOINT [ "triage_experiment" ]
