#!/bin/bash
source ~/.bashrc
source activate dp_bert_2

for TASK in mort_icu los_3 readmission_30
do
  for CLIP_NORM in 5.0
  do
    for NOISE_MULT in 0.0 0.2 0.4 0.6 0.8 1.0
    do
      for LR in 2e-5
      do
        for EPOCH in 3
        do
          for RANDOM_SEED in 0 1 2 3 4
          do
            echo dp_bert_tanh_${TASK}_${CLIP_NORM}_${NOISE_MULT}_${LR}_${EPOCH}_${RANDOM_SEED}
            bash launch_gpu_slurm_job.sh gpu dp_bert_tanh_${TASK}_${CLIP_NORM}_${NOISE_MULT}_${LR}_${EPOCH}_${RANDOM_SEED} gpu:2 ./train_bert_classifier.sh ${CLIP_NORM} ${NOISE_MULT} ${TASK} ${RANDOM_SEED} $LR $EPOCH
          done
        done
      done
    done
  done
done
