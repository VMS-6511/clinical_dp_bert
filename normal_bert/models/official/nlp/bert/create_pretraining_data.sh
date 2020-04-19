#!/bin/bash
source ~/.bashrc
source activate dp_bert

export PYTHONPATH=$PYTHONPATH:/h/vinithms/normal_bert/models
export SCIBERT_DIR=/scratch/hdd001/home/vinithms/scibert_scivocab_uncased
export MIMIC_INPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes
export MIMIC_OUTPUT_DIR=/scratch/hdd001/home/vinithms/mimic_notes
export TASK_NAME=nurse_phys_notes

python ../data/create_pretraining_data.py \
 --input_file=${MIMIC_INPUT_DIR}/nurse_phys_notes_train.raw.txt \
 --vocab_file=${SCIBERT_DIR}/vocab.txt \
 --output_file=${MIMIC_OUTPUT_DIR}/${TASK_NAME}_train.tf_record \
 --do_lower_case=True \
 --do_whole_word_mask=True