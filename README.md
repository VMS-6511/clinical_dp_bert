# Clinical Text Prediction with Differential Privacy

Note that in each of the repos you must follow the path of /models/official/nlp/bert to get to the files used for this research. All of these repos were forked from official Tensorflow repos and modified based on the needs for our project.

## Environment Setup

Create a conda environment with the name of your choice using the ```requirements.txt``` file that has been provided. We chose ```dp_bert``` which is used in our scripts as well. Thus if you use a different environment name you will have to make the required changes in the bash scripts. Also make sure that you have CUDA 10.1 and cuDNN 7.0 installed as these are the drivers we are using with Tensorflow 2.0. Once you have created this environment run this command to install the TF Privacy Library:

``` pip install -e privacy```

## Data Preprocessing

You must have access to the MIMIC-III database which requires completion of the CITI certificate. Once this has been done you must create an instance of the MIMIC database on your computer. This requires about 50GB of space and more instructions can be found here.
After this you can run this specific SQL query and save to a CSV file:

``` SELECT * FROM NOTEEVENTS ```

This will create a CSV of all of the clinical notes stored in the database which is approximately 2 million.

From there you can use the ```dp_bert/notebooks/notes_analysis.ipynb``` notebook to provide an analysis of the notes. In this notebook you will create the raw text files that will be used for finetuning and acquire the labels for the three prediction tasks of mortality, length of stay > 3 days, and readmission within 30 days. From here you will end up with the training, validation and test data raw text files for finetuning.

After this, you must run the ```./create_finetuning_data.sh``` script in the ```normal_bert``` folder to create the required TFRecords that will be used by our Tensorflow BERT implementation.

## ClinicalBERT Initialization

You will need to download the TF 1.x checkpoint from this [link](https://github.com/EmilyAlsentzer/clinicalBERT) that was trained on BioBERT and all of the MIMIC clinical notes. From here you will need to use the ```tf2_encoder_checkpoint_converter.py``` script to convert the TF 1.x checkpoint into a TF 2.0 checkpoint that can be used as the starting point for this implementation.

## Running the No Privacy Finetuning Baselines

All you need to run is ```./train_bert_classifier.sh``` in the ```normal_bert``` directory.


## Finetuning with DP-SGD
All that is need to run the experiments is the following bash script:

``` ./run_all_experiments.sh``` which can be found in the folder mentioned in the beginning in the ```dp_bert``` folder. You can specify where the model and results are saved in the ```./train_bert_classifier.sh``` script.

## Results Analysis
Finally, we can use the ```dp_bert_analysis.ipynb``` in the ```dp_bert``` note books folder. This will generate the dataframe that was used to populate our tables and the code used to generate our plots.

## Acknowledgements and Citations
First, off we would like to thank and indicate the work that we built upon from the open-source Tensorflow implementations of BERT and DP-SGD. These implementations helped with our implementations of the DP-BERT models that we built. This is evidenced in the fact that our implementation is built within forked versions of these repos. 

Below are the links to the original repos:

[Tensorflow Models Repository](https://github.com/tensorflow/models)

[TF Privacy Repository](https://github.com/tensorflow/privacy)

## Contributors

Vinith M. Suriyakumar,
Nathan Ng,
Robert Grant



