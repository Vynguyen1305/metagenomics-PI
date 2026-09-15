#! /bin/bash
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "  -i  Path to the input CSV"
    echo "  -o  Path to the output directory"
    echo "  -r  Path to the resources directory (contains kraken2_std8_db/, abricate_db/, adapter/)"
    echo "  -j  ABRicate database NAME, e.g. ncbi | card | resfinder (default: ncbi)"
    echo "  -k  Kraken2 database folder name under resources dir (default: kraken2_std8_db)"
    exit 1
}

REF_VIRUS_ABRICATE="ncbi"
KRAKEN2_DB_NAME="kraken2_std8_db"

while getopts "i:o:r:k:j:" opt; do
  case ${opt} in
    i) INPUT_CSV="$OPTARG" ;;
    o) DIR_OUTPUT="$OPTARG" ;;
    r) DIR_RESOURCES="$OPTARG" ;;
    k) KRAKEN2_DB_NAME="$OPTARG" ;;
    j) REF_VIRUS_ABRICATE="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$INPUT_CSV" ] || [ -z "$DIR_OUTPUT" ] || [ -z "$DIR_RESOURCES" ]; then
    echo "Error: Missing required parameters."
    usage
fi

DIR_WORKFLOW=$(realpath $(dirname $0))
DIR_ROOT=$(realpath $(dirname $(dirname $DIR_WORKFLOW)))
RUNID=$(basename "${INPUT_CSV}" .csv)

DIR_WORK=${DIR_OUTPUT}/${RUNID}/work
DIR_REPORT=${DIR_OUTPUT}/${RUNID}/logs
DIR_RESULTS=${DIR_OUTPUT}/${RUNID}/results
DIR_NFRUN=${DIR_OUTPUT}/${RUNID}/nextflows_run

DIR_ABRICATE_DB=${DIR_RESOURCES}/abricate_db
DIR_KRAKEN2_DB=${DIR_RESOURCES}/${KRAKEN2_DB_NAME}

echo "========================================================"
echo " INPUT CSV      : $INPUT_CSV"
echo " DIR_OUTPUT     : $DIR_OUTPUT"
echo " DIR_RESRC      : $DIR_RESOURCES"
echo " KRAKEN2 DB DIR : $DIR_KRAKEN2_DB"
echo " ABRICATE DB DIR: $DIR_ABRICATE_DB"
echo " ABRICATE DB    : $REF_VIRUS_ABRICATE"
echo " DIR_NFRUN      : $DIR_WORKFLOW"
echo "========================================================"

mkdir -p $DIR_OUTPUT $DIR_WORK $DIR_REPORT $DIR_NFRUN $DIR_RESULTS
cd $DIR_NFRUN

nextflow run ${DIR_WORKFLOW}/metagenomics.nf \
    -c ${DIR_WORKFLOW}/main.config \
    -with-report "${DIR_REPORT}/report_${RUNID}_$(date +%Y%m%d%H%M).html" \
    -with-dag "${DIR_REPORT}/pipeline_${RUNID}_$(date +%Y%m%d%H%M).html" \
    --projectDir $DIR_ROOT \
    --inputCSV $INPUT_CSV \
    --outdir $DIR_RESULTS \
    --resources $DIR_RESOURCES \
    --kraken2_db $DIR_KRAKEN2_DB \
    --abricate_db $REF_VIRUS_ABRICATE \
    --abricate_db_dir $DIR_ABRICATE_DB \
    -w $DIR_WORK \
    -resume

