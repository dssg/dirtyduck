# coding: utf-8

import pandas as pd
import numpy as np

import matplotlib.pyplot as plt
import matplotlib.dates as md

import seaborn as sns
#sns.set_style("whitegrid")
sns.set_context("paper")
sns.set_style("ticks")

from functools import reduce

from datetime import datetime
from dateutil.relativedelta import relativedelta

import triage.component.timechop as timechop
from triage.util.conf import convert_str_to_relativedelta


FIG_SIZE = (16,8)

df = pd.read_csv("src/df.csv", parse_dates=['date'])

chopper = timechop.Timechop(
    feature_start_time=np.min(df.date),
    feature_end_time=np.max(df.date),
    label_start_time=np.min(df.date),
    label_end_time=np.max(df.date),
    model_update_frequency='1year',
    training_label_timespans='6month',
    test_label_timespans='6month',
    max_training_histories='2year',
    test_durations='3month',
    training_as_of_date_frequencies='3month',
    test_as_of_date_frequencies='1month'
)

def show_timechop(chopper):

    plt.close('all')

    chops = chopper.chop_time()

    fig, ax = plt.subplots(len(chops), sharex=True, sharey=True, figsize=FIG_SIZE)


    for idx, chop in enumerate(chops):
        train_as_of_times = chop['train_matrix']['as_of_times']
        test_as_of_times = chop['test_matrices'][0]['as_of_times']

        max_training_history = chop['train_matrix']['max_training_history']
        test_label_timespan = chop['test_matrices'][0]['test_label_timespan']

        # Train matrix
        ax[idx].hlines(
          [x - 0.2 for x in range(len(train_as_of_times))],
          [x.date() for x in train_as_of_times],
          [x.date() - convert_str_to_relativedelta(max_training_history) for x in train_as_of_times],
          linewidth=3, color=f"C{idx}",label=f"train_{idx}"
        )

        # Test matrix
        ax[idx].hlines(
          [x - 0.2 for x in range(len(test_as_of_times))],
          [x.date() for x in test_as_of_times],
          [x.date() + convert_str_to_relativedelta(test_label_timespan) for x in test_as_of_times],
          linewidth=3, color=f"C{idx}",
          label=f"test_{idx}"
        )

        #ax.axvline(chop['feature_start_time'], color='k', linestyle='--')
        #ax.axvline(chop['feature_end_time'], color='k', linestyle='--')
        #ax.axvline(chop['label_start_time'] ,color='k', linestyle='--')
        #ax.axvline(chop['label_end_time'] ,color='k', linestyle='--')

        # Limits: train
        #ax.axvline(chop['train_matrix']['first_as_of_time'],color='k', linestyle='--')
        #ax.axvline(chop['train_matrix']['last_as_of_time'],color='k', linestyle='--')
        #ax.axvline(chop['train_matrix']['matrix_info_end_time'],color='k', linestyle='--')


        # Limits: test
        #ax.axvline(chop['test_matrices'][0]['first_as_of_time'] - convert_str_to_relativedelta(test_label_timespan) ,color='k', linestyle='--')
        #ax.axvline(chop['test_matrices'][0]['last_as_of_time'],color='k', linestyle='--')
        #ax.axvline(chop['test_matrices'][0]['matrix_info_end_time'],color='k', linestyle='--')

        ax[idx].xaxis.set_major_formatter(md.DateFormatter('%Y-%m'))

        ax[idx].xaxis.set_major_locator(md.MonthLocator())
        #ax.xaxis.set_minor_locator(md.WeekdayLocator(byweekday=md.MO))
        #ax.xaxis.grid(b=True)

        fig.autofmt_xdate()

    # Limit: data

    #ax.vlines([chop['feature_start_time'],chop['feature_end_time']], ymin=0, ymax=10)

    #ax.yaxis.set_ticklabels([x['label'] for x in data])
    #ax.yaxis.set_ticks([idx for idx, x in enumerate(data)])
    #ax.yaxis.grid(b=True)
    #ax.set_ylim(len(data), -1)

    #ax.legend()

    fig.subplots_adjust(hspace=0)
    plt.setp([a.get_xticklabels() for a in fig.axes[:-1]], visible=False)
    plt.show()
