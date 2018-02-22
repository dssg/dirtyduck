# coding: utf-8

import os

import sqlalchemy
from sqlalchemy import create_engine

from io import StringIO
from functools import reduce
from datetime import datetime
from dateutil.relativedelta import relativedelta

import numpy as np
import pandas as pd

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as md

import seaborn as sns
sns.set_style("white")
sns.set_context("paper")
sns.set_style("ticks")

import pydotplus

import sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.tree import export_graphviz, DecisionTreeClassifier
from sklearn.externals import joblib

import triage.component.timechop as timechop
from triage.util.conf import convert_str_to_relativedelta


FIG_SIZE = (32,16)
TRIAGE_DB_URL = os.environ.get("TRIAGE_DB_URL")
TRIAGE_OUTPUT_PATH = "/triage/output/"

def show_timechop(chopper, show_as_of_times=True, show_boundaries=True, file_name=None):

    plt.close('all')

    chops = chopper.chop_time()

    chops.reverse()

    fig, ax = plt.subplots(len(chops), sharex=True, sharey=True, figsize=FIG_SIZE)


    for idx, chop in enumerate(chops):
        train_as_of_times = chop['train_matrix']['as_of_times']
        test_as_of_times = chop['test_matrices'][0]['as_of_times']

        max_training_history = chop['train_matrix']['max_training_history']
        test_label_timespan = chop['test_matrices'][0]['test_label_timespan']
        training_label_timespan = chop['train_matrix']['training_label_timespan']

        color_rgb = np.random.random(3)

        if(show_as_of_times):
            # Train matrix (as_of_times)
            ax[idx].hlines(
              [x for x in range(len(train_as_of_times))],
              [x.date() for x in train_as_of_times],
              [x.date() + convert_str_to_relativedelta(training_label_timespan) for x in train_as_of_times],
              linewidth=3, color=color_rgb,label=f"train_{idx}"
            )

            # Test matrix
            ax[idx].hlines(
              [x for x in range(len(test_as_of_times))],
              [x.date() for x in test_as_of_times],
              [x.date() + convert_str_to_relativedelta(test_label_timespan) for x in test_as_of_times],
              linewidth=3, color=color_rgb,
              label=f"test_{idx}"
            )


        if(show_boundaries):
            # Limits: train
            ax[idx].axvspan(chop['train_matrix']['first_as_of_time'],
                            chop['train_matrix']['last_as_of_time'],
                            color=color_rgb,
                            alpha=0.3
            )


            ax[idx].axvline(chop['train_matrix']['matrix_info_end_time'], color='k', linestyle='--')


            # Limits: test
            ax[idx].axvspan(chop['test_matrices'][0]['first_as_of_time'],
                            chop['test_matrices'][0]['last_as_of_time'],
                            color=color_rgb,
                            alpha=0.3
            )

            ax[idx].axvline(chop['feature_start_time'], color='k', linestyle='--', alpha=0.2)
            ax[idx].axvline(chop['feature_end_time'], color='k', linestyle='--',  alpha=0.2)
            ax[idx].axvline(chop['label_start_time'] ,color='k', linestyle='--', alpha=0.2)
            ax[idx].axvline(chop['label_end_time'] ,color='k', linestyle='--',  alpha=0.2)

            ax[idx].axvline(chop['test_matrices'][0]['matrix_info_end_time'],color='k', linestyle='--')

        ax[idx].yaxis.set_major_locator(plt.NullLocator())
        ax[idx].yaxis.set_label_position("right")
        ax[idx].set_ylabel(f"Block {idx}", rotation='horizontal', labelpad=30)

        ax[idx].xaxis.set_major_formatter(md.DateFormatter('%Y'))
        ax[idx].xaxis.set_major_locator(md.YearLocator())
        ax[idx].xaxis.set_minor_locator(md.MonthLocator())

    ax[0].set_title('Timechop: Temporal cross-validation blocks')
    fig.subplots_adjust(hspace=0)
    plt.setp([a.get_xticklabels() for a in fig.axes[:-1]], visible=False)

    file_name = os.path.join(TRIAGE_OUTPUT_PATH, "images", file_name)
    fig.savefig(file_name)

    plt.show()

    return file_name


def show_features_queries(st):

    for sql_list in st.get_selects().values():
        for sql in sql_list:
            print(str(sql))

    print(str(st.get_create()))


def get_model_hashes(model_id):
    db = create_engine(TRIAGE_DB_URL)

    rows = db.execute(
        f"""
        select distinct on (model_hash, train_matrix_uuid, matrix_uuid) 
        model_hash, train_matrix_uuid as train_hash, matrix_uuid as test_hash
        from results.models 
        inner join results.predictions using(model_id) 
        where model_id = {model_id};
       """)

    for row in rows:
        model_hash, train_hash, test_hash = row.model_hash, row.train_hash, row.test_hash

    return model_hash, train_hash, test_hash

def show_model(model_id):
    model_hash, train_hash, _ = get_model_hashes(model_id)

    clf = joblib.load(os.path.join(TRIAGE_OUTPUT_PATH, "trained_models", model_hash))
    
    X = pd.read_csv(os.path.join(TRIAGE_OUTPUT_PATH, "matrices", f"{train_hash}.csv"), nrows = 1)
    X.drop(['entity_id', 'as_of_date', 'outcome'], axis = 1, inplace=True)

    trees = []
    file_names = []
    
    if isinstance(clf, RandomForestClassifier):
        # We have a forest, we will pick 5 at random
        trees.extend(np.random.choice(clf.estimators_, size=1 , replace=False))
        print(trees)
    elif isinstance(clf, DecisionTreeClassifier):
        trees.append(clf)
    else:
        trees = None
        file_names = None
        print("You selected a model that isn't a Decision Tree. I can not plot that. Sorry")

    for i, dtree in enumerate(trees):
        print(f"Plotting tree number {i}")
        dot_data = StringIO()
        dtree.export_graphviz(out_file=dot_data,  
                              filled=True, rounded=True,
                              special_characters=True,
                              feature_names = X.columns)
        
        graph = pydotplus.graph_from_dot_data(dot_data.getvalue())
        file_name = os.path.join(TRIAGE_OUTPUT_PATH, "images", f"model_{model_id}_tree_{i}.svg")
        graph.write_svg(file_name)
        file_names.append(file_name)
        graph.write_png(file_name.replace("svg", "png"))


    return file_names
