#!/bin/bash
source ~/.bashrc
source activate dp_bert_2

export PYTHONPATH=$PYTHONPATH:/h/vinithms/clinical_dp_bert/dp_bert/models
export CLINBERT_DIR=/scratch/hdd001/home/vinithms/pretrained_bert_tf/biobert_pretrain_output_all_notes_150000
export CLIP_NORM=$1
export NOISE_MULTIPLIER=$2
export TASK=$3
export RANDOM_SEED=$4
export LEARNING_RATE=$5
export EPOCHS=$6
export MIMIC_DATA_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes/$TASK
export MIMIC_OUTPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes/${TASK}/
export MODEL_DIR=/scratch/hdd001/home/vinithms/dp_bert_models/${TASK}/${CLIP_NORM}_${NOISE_MULTIPLIER}/${LEARNING_RATE}/${EPOCHS}/${RANDOM_SEED}/
export RESULTS_DIR=./results/dp_bert_gelu/${TASK}/${CLIP_NORM}_${NOISE_MULTIPLIER}/${LEARNING_RATE}/${EPOCHS}/${RANDOM_SEED}/
mkdir -p $MODEL_DIR
mkdir -p $RESULTS_DIR

echo $RESULTS_DIR

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
  --learning_rate=${LEARNING_RATE} \
  --num_train_epochs=${EPOCHS} \
  --model_dir=${MODEL_DIR} \
  --distribution_strategy=mirrored \
  --l2_norm_clip=${CLIP_NORM} \
  --noise_multiplier=${NOISE_MULTIPLIER} \
  --results_dir=$RESULTS_DIR \
  --random_seed=$RANDOM_SEED \

rm -rf $MODEL_DIR
 