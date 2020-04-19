#!/bin/bash
source ~/.bashrc
source activate dp_bert

export PYTHONPATH=$PYTHONPATH:/h/vinithms/dp_bert/models

export GLUE_DIR=/scratch/hdd001/home/vinithms/glue_data
export BERT_DIR=gs://cloud-tpu-checkpoints/bert/keras_bert/uncased_L-12_H-768_A-12

export TASK_NAME=$1
export OUTPUT_DIR=/scratch/hdd001/home/vinithms/bert_finetuning_data/
python ../data/create_finetuning_data.py \
 --input_data_dir=${GLUE_DIR}/${TASK_NAME}/ \
 --vocab_file=${BERT_DIR}/vocab.txt \
 --train_data_output_path=${OUTPUT_DIR}/${TASK_NAME}_train.tf_record \
 --eval_data_output_path=${OUTPUT_DIR}/${TASK_NAME}_eval.tf_record \
 --meta_data_file_path=${OUTPUT_DIR}/${TASK_NAME}_meta_data \
 --fine_tuning_task_type=classification --max_seq_length=128 \
 --classification_task_name=${TASK_NAME}
