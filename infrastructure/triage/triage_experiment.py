# coding: utf-8

import os
import yaml
import sqlalchemy

import logging

import click


from triage.component.catwalk.storage import FSModelStorageEngine
from triage.experiments import SingleThreadedExperiment


@click.group()
@click.option('--config_file', type=click.Path(exists=True, resolve_path=True),
              help="Triage's experiment congiguration file", required=True)
@click.option('--triage_db', envvar='TRIAGE_DB_URL', type=click.STRING,
                help="""DB URL, in the form of 'postgresql://user:password@host_db:host_port/db',
                        by default it gets this from the environment (TRIAGE_DB_URL)""",
              required=True)
@click.option('--debug/--no-debug', default=False, help="Do you want a verbose output?")
@click.pass_context
def triage(ctx, config_file, triage_db, debug):

    with open(config_file) as f:
        experiment_config = yaml.load(f)

    click.echo("Creating experiment object")

    experiment = SingleThreadedExperiment(
        config=experiment_config,
        db_engine=sqlalchemy.create_engine(triage_db),
        model_storage_class=FSModelStorageEngine,
        project_path='triage'
    )

    ctx.obj = experiment

    click.echo("Experiment loaded")

@triage.command()
@click.pass_obj
def debug_features(experiment):
    pass

@triage.command()
@click.pass_obj
def debug_temporal_blocks(experiment):
    pass

@triage.command()
@click.pass_obj
def validate(experiment):
    click.echo("Validating experiment's configuration")
    try:
        experiment.validate()
    except:
        logging.error("You can't validate what has not been created (experiment not found)")
    click.echo("The experiment looks in good shape. May the force be with you")

@triage.command()
@click.pass_obj
def run(experiment):
    click.echo("Executing experiment")
    try:
        experiment.run()
    except:
        logging.error("You can't execute what has not been created (experiment not found)")
    click.echo("Done")
