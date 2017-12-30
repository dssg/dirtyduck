# coding: utf-8

from setuptools import setup

setup(
    name='triage_experiment',
    version='0.1',
    py_modules=['triage_experiment'],
    entry_points='''
        [console_scripts]
        run_experiment=triage_experiment:run
        validate_experiment=triage_experiment:validate
        debug_features=triage_experiment:debug_features
        debug_temporal_blocks=triage_experiment:debug_temporal_blocks
    ''',
)
