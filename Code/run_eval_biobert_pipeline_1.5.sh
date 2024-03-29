#!/usr/bin/env bash


craft_path='/Users/MaylaB/Dropbox/Documents/0_Thesis_stuff-Larry_Sonia/Negacy_seq_2_seq_NER_model/ConceptRecognition/CRAFT-3.1.3/'
concept_recognition_path='/Users/MaylaB/Dropbox/Documents/0_Thesis_stuff-Larry_Sonia/Negacy_seq_2_seq_NER_model/ConceptRecognition/'

eval_path='/Users/MaylaB/Dropbox/Documents/0_Thesis_stuff-Larry_Sonia/Negacy_seq_2_seq_NER_model/ConceptRecognition/Evaluation_Files/'

concept_system_output='concept_system_output/'

article_folder='Articles/txt/' #want files.txt
tokenized_files='Tokenized_Files/'
python_scripts='PythonScripts/'
results_span_detection='Results_span_detection/'
concept_norm_files='Concept_Norm_Files/'
pmcid_sentence_files_path='PMCID_files_sentences/'

concept_annotation='concept-annotation/'

ontologies="CHEBI,CL,GO_BP,GO_CC,GO_MF,MOP,NCBITaxon,PR,SO,UBERON"
#ontologies="CHEBI"

evaluation_files="11532192,17696610"

gold_standard='True'

algos='LSTM_ELMO' #CRF, LSTM, LSTM_CRF, CHAR_EMBEDDINGS, LSTM_ELMO, BIOBERT
algos='BIOBERT'

all_lcs_path='/Users/MaylaB/Dropbox/Documents/0_Thesis_stuff-Larry_Sonia/0_Gold_Standard_Annotation/Ontologies/Ontology_Of_Ignorance_all_cues_2020-03-27.txt'



##FOR BIOBERT
biobert='BIOBERT'
if [ $algos == $biobert ]; then
#    ##move test.tsv file to fiji for predictions
#    prediction_file='/Users/MaylaB/Dropbox/Documents/0_Thesis_stuff-Larry_Sonia/Negacy_seq_2_seq_NER_model/ConceptRecognition/Evaluation_Files/Tokenized_Files/BIOBERT'
#    scp $prediction_file/test.tsv mabo1182@fiji.colorado.edu:/Users/mabo1182/negacy_project/Evaluation_Files/Tokenized_Files/BIOBERT/
#
#    #GO TO FIJI_RUN_EVAL_BIOBERT!
#    ##TODO: biobert run classification algorithm - fiji_run_eval_biobert.sh on fiji!!!
#    #sbatch GPU_run_fiji_eval_biobert.sbatch - runs fiji_run_eval_biobert.sh


    ##BRING ALL OUTPUT LOCALLY FOR BIOBERT
    declare -a arr=('CHEBI' 'CL' 'GO_BP' 'GO_CC' 'GO_MF' 'MOP' 'NCBITaxon' 'PR' 'SO' 'UBERON')
##    declare -a arr=('CHEBI')
#
#    ##loop over each ontology and run the corresponding model
    results_span_detection='/Users/mabo1182/negacy_project/Evaluation_Files/Results_span_detection/'
    biobert='/BIOBERT'
    local_results='/Users/MaylaB/Dropbox/Documents/0_Thesis_stuff-Larry_Sonia/Negacy_seq_2_seq_NER_model/ConceptRecognition/Evaluation_Files/Results_span_detection/'
#
    for i in "${arr[@]}"
    do
        echo $i
        results_path=$results_span_detection$i$biobert
        local_path=$local_results$i$biobert
        scp mabo1182@fiji.colorado.edu:$results_path/*_test.txt* $local_path

    done

    ###ner_detokenize_updated for predictions only
    #updated detokenize to put all stuff back together to CONLL format!

    biotags='B,I,O-,O' #ordered for importance
    gold_standard='false'
    gold_standard='true'
    true='true'

    declare -a ont=('CHEBI' 'CL' 'GO_BP' 'GO_CC' 'GO_MF' 'MOP' 'NCBITaxon' 'PR' 'SO' 'UBERON')
#    declare -a ont=('CHEBI')
#    declare -a ont=('GO_MF')
    for i in "${ont[@]}"
    do
        echo "$i"
        tokenized_files='Tokenized_Files'
        results_span_detection='Results_span_detection/'
        NER_DIR=$eval_path$tokenized_files$biobert
        OUTPUT_DIR=$eval_path$results_span_detection$i$biobert

        python3 biobert_ner_detokenize_updated.py --token_test_path=$OUTPUT_DIR/token_test.txt --label_test_path=$OUTPUT_DIR/label_test.txt --answer_path=$NER_DIR/test.tsv --output_dir=$OUTPUT_DIR --biotags=$biotags --gold_standard=$gold_standard

        echo 'DONE WITH TEST.TSV'


        ##if gold standard then we also want the gold standard information using the ontology_test.tsv files
        if [ $gold_standard == $true ]; then
            ont_test='_test.tsv'
            python3 biobert_ner_detokenize_updated.py --token_test_path=$OUTPUT_DIR/token_test.txt --label_test_path=$OUTPUT_DIR/label_test.txt --answer_path=$NER_DIR/$i$ont_test --output_dir=$OUTPUT_DIR --biotags=$biotags --gold_standard=$gold_standard


            ##classification report if gold standard

            python3 biobert_classification_report.py --ner_conll_results_path=$OUTPUT_DIR/ --biotags=$biotags --ontology=$i --output_path=$OUTPUT_DIR/ --gold_standard=$gold_standard

            #copy the classification report to the main results with ontology name
            biobert_class_report='_biobert_local_eval_files_classification_report.txt'
            cp $OUTPUT_DIR/biobert_classification_report.txt $eval_path$results_span_detection$i/$i$biobert_class_report



        fi

    done


    tokenized_files='Tokenized_Files/'
    results_span_detection='Results_span_detection/'
    biobert_prediction_results=$eval_path$results_span_detection

    ##create the evaluation dataframe!
    python3 biobert_eval_dataframe_output.py -ontologies=$ontologies -excluded_files=$evaluation_files -tokenized_file_path=$eval_path$tokenized_files -biobert_prediction_results=$biobert_prediction_results -output_path=$biobert_prediction_results -algos=$algos --pmcid_sentence_files_path=$pmcid_sentence_files_path

fi





##preprocess to get all the concepts for the next steps
python3 eval_preprocess_concept_norm_files.py -ontologies=$ontologies -results_span_detection_path=$eval_path$results_span_detection -concept_norm_files_path=$eval_path$concept_norm_files -evaluation_files=$evaluation_files


##run the open_nmt to predict
#run_eval_open_nmt.sh
