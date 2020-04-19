#!/bin/bash
source ~/.bashrc
source activate dp_bert

for TASK in mort_icu los_3 readmission_30
do
  for RANDOM_SEED in 0 1 2 3 4
  do
    echo normal_bert_${TASK}_$RANDOM_SEED
    bash launch_gpu_slurm_job.sh gpu norm_bert_gelu_${TASK}_${RANDOM_SEED} gpu:2 ./train_bert_classifier.sh ${TASK} ${RANDOM_SEED}
  done
done