#!/bin/bash
source ~/.bashrc
source activate dp_bert_2

export PYTHONPATH=$PYTHONPATH:/h/vinithms/clinical_dp_bert/normal_bert/models
export CLINBERT_DIR=/scratch/hdd001/home/vinithms/pretrained_bert_tf/biobert_pretrain_output_all_notes_150000
export TASK=$1
export RANDOM_SEED=$2
export MIMIC_INPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes
export MIMIC_OUTPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes/${TASK}
export MODEL_DIR=/scratch/hdd001/home/vinithms/dp_bert/${TASK}/no_privacy/${RANDOM_SEED}
export RESULTS_DIR=./results/dp_bert_gelu/${TASK}/0.0_0.0/2e-5/3/${RANDOM_SEED}/

mkdir -p $MODEL_DIR
mkdir -p $RESULTS_DIR

python run_classifier.py \
  --mode='train_and_eval' \
  --input_meta_data_path=${MIMIC_OUTPUT_DIR}/${TASK}_meta_data \
  --train_data_path=${MIMIC_OUTPUT_DIR}/${TASK}_train.tf_record \
  --eval_data_path=${MIMIC_OUTPUT_DIR}/${TASK}_eval.tf_record \
  --bert_config_file=${CLINBERT_DIR}/bert_config.json \
  --init_checkpoint=${CLINBERT_DIR}/tf2/model.ckpt \
  --train_batch_size=4 \
  --eval_batch_size=4 \
  --steps_per_loop=1 \
  --learning_rate=2e-5 \
  --num_train_epochs=3 \
  --model_dir=${MODEL_DIR} \
  --distribution_strategy=mirrored \
  --results_dir=$RESULTS_DIR \