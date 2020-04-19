#!/bin/bash
 
d=`date +%Y-%m-%d`
partition=$1
j_name=${2}

resource=$3
cmd=$4
l2_norm_clip=$5
noise_mult=$6
task=$7
random_seed=$8
learning_rate=${9}
epochs=${10}
hdd=/scratch/hdd001/home/$USER
ssd=/scratch/ssd001/home/$USER
j_dir=$hdd/slurm/vremote/$d/${j_name}
 
mkdir -p $j_dir/scripts
 
# build slurm script
mkdir -p $j_dir/log
echo "#!/bin/bash
#SBATCH --job-name=${j_name}
#SBATCH --output=${j_dir}/log/%j.out
#SBATCH --error=${j_dir}/log/%j.err
#SBATCH --partition=${partition}
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-node=1
#SBATCH --mem=10G
#SBATCH --gres=${resource}
#SBATCH --nodes=1
 
bash ${j_dir}/scripts/${j_name}.sh
" > $j_dir/scripts/${j_name}.slrm
 
# build bash script
echo -n "#!/bin/bash
$cmd $l2_norm_clip $noise_mult $task $random_seed $learning_rate $epochs
" > $j_dir/scripts/${j_name}.sh 
 
sbatch $j_dir/scripts/${j_name}.slrm