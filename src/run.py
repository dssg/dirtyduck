import os
import sqlalchemy
import yaml

from catwalk.storage import FSModelStorageEngine
from triage.experiments import SingleThreadedExperiment

food_db = os.environ.get('FOOD_DB_URL')

print(food_db)

with open('inspections-training.yaml') as f:
    experiment_config = yaml.load(f)

experiment = SingleThreadedExperiment(
    config=experiment_config,
    db_engine=sqlalchemy.create_engine(food_db),
    model_storage_class=FSModelStorageEngine,
    project_path='./triage-generated'
)

experiment.run()
