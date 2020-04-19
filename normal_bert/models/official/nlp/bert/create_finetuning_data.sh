#!/bin/bash
source ~/.bashrc
source activate dp_bert

export PYTHONPATH=$PYTHONPATH:/h/vinithms/normal_bert/models
export CLINBERT_DIR=/scratch/hdd001/home/vinithms/pretrained_bert_tf/biobert_pretrain_output_all_notes_150000
export TASK_NAME=MIMIC_READM
export MIMIC_INPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes
export MIMIC_OUTPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes/readmission_30


python ../data/create_finetuning_data.py \
 --input_data_dir=${MIMIC_INPUT_DIR}/readmission_30/ \
 --vocab_file=${CLINBERT_DIR}/vocab.txt \
 --train_data_output_path=${MIMIC_OUTPUT_DIR}/readmission_30_train.tf_record \
 --eval_data_output_path=${MIMIC_OUTPUT_DIR}/readmission_30_eval.tf_record \
 --meta_data_file_path=${MIMIC_OUTPUT_DIR}/readmission_30_meta_data \
 --fine_tuning_task_type=classification --max_seq_length=128 \
 --classification_task_name=${TASK_NAME}