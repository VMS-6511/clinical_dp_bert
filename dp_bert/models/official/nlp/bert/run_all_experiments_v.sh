#!/bin/bash
source ~/.bashrc
source activate dp_bert

for TASK in mort_icu los_3 readmission_30
do
  for CLIP_NORM in 15.0
  do
    for NOISE_MULT in 0.001
    do
      for LR in 2e-3 2e-4 2e-5 2e-6 2e-7
      do
        for EPOCH in 1
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
