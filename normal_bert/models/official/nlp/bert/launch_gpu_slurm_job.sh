#!/bin/bash
 
d=`date +%Y-%m-%d`
partition=$1
j_name=${2}_${5}_${6}_no_privacy

resource=$3
cmd=$4
task=$5
random_seed=$6
hdd=/scratch/hdd001/home/$USER
ssd=/scratch/ssd001/home/$USER
j_dir=$hdd/slurm/v/$d/${j_name}

mkdir -p $j_dir/scripts
 
# build slurm script
mkdir -p $j_dir/log
echo "#!/bin/bash
#SBATCH --job-name=${j_name}
#SBATCH --output=${j_dir}/log/%j.out
#SBATCH --error=${j_dir}/log/%j.err
#SBATCH --partition=${partition}
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --mem=64G
#SBATCH --gres=${resource}
#SBATCH --nodes=1
 
bash ${j_dir}/scripts/${j_name}.sh
" > $j_dir/scripts/${j_name}.slrm
 
# build bash script
echo -n "#!/bin/bash
$cmd $task $random_seed
" > $j_dir/scripts/${j_name}.sh 
 
sbatch $j_dir/scripts/${j_name}.slrm