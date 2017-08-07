import sqlalchemy
import yaml

from catwalk.storage import FSModelStorageEngine
from triage.experiments import SingleThreadedExperiment

with open('inspections-training.yaml') as f:
    experiment_config = yaml.load(f)

experiment = SingleThreadedExperiment(
    config=experiment_config,
    db_engine=sqlalchemy.create_engine('postgresql://food_user:goli0808@food_db:5432/food'),
    model_storage_class=FSModelStorageEngine,
    project_path='./triage-generated'
)

experiment.run()
