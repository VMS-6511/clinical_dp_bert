#!/bin/bash
source ~/.bashrc
source activate dp_bert

export PYTHONPATH=$PYTHONPATH:/h/vinithms/normal_bert/models
export CLINBERT_DIR=/scratch/hdd001/home/vinithms/pretrained_bert_tf/biobert_pretrain_output_all_notes_150000
export CLINBERT_TF2_DIR=/scratch/hdd001/home/vinithms/pretrained_bert_tf/biobert_pretrain_output_all_notes_150000/tf2
export TASK=mort_icu
export MIMIC_INPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes
export MIMIC_OUTPUT_DIR=/h/vinithms/ML_Linkage_Attacks/data/mimic_notes/mort_icu
export MODEL_DIR=/scratch/hdd001/home/vinithms/dp_bert/mort_icu/no_privacy/

mkdir -p $CLINBERT_TF2_DIR

python tf2_encoder_checkpoint_converter.py \
--bert_config_file=${CLINBERT_DIR}/bert_config.json \
--checkpoint_to_convert=${CLINBERT_DIR}/model.ckpt-150000 \
--converted_checkpoint_path=${CLINBERT_TF2_DIR}/model.ckpt