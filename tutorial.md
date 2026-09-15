# Metagenomics Pipeline — Setup Tutorial

## 1. Get FASTQ files

```bash
cd {projectDir}
mkdir -p fastq
cd fastq

wget https://zenodo.org/records/7871630/files/JC1A_R1.fastqsanger.gz
wget https://zenodo.org/records/7871630/files/JC1A_R2.fastqsanger.gz
wget https://zenodo.org/records/7871630/files/JP4D_R1.fastqsanger.gz
wget https://zenodo.org/records/7871630/files/JP4D_R2.fastqsanger.gz
```

## 2. Get Singularity images

```bash
cd {projectDir}
mkdir -p singularity
cd singularity

singularity pull fastqc_0.12.1.sif      docker://quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0
singularity pull trimmomatic_0.39.sif   docker://quay.io/biocontainers/trimmomatic:0.39--hdfd78af_2
singularity pull kraken2_2.1.3.sif      docker://quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0
singularity pull bracken_2.9.sif        docker://quay.io/biocontainers/bracken:2.9--py38h2494328_0
singularity pull megahit_1.2.9.sif      docker://quay.io/biocontainers/megahit:1.2.9--h5b5514e_3
singularity pull abricate_1.4.0.sif     docker://quay.io/biocontainers/abricate:1.4.0--h05cac1d_0
singularity pull multiqc_1.18.sif       docker://quay.io/biocontainers/multiqc:1.18--pyhdfd78af_0
```

## 3. Prepare reference / resources directory

```bash
cd {projectDir}
mkdir -p ref
```

### 3.1 Trimmomatic adapter file

```bash
mkdir -p {projectDir}/adapter
# copy hoặc tải TruSeq3-PE-2.fa vào đây
cp /path/to/TruSeq3-PE-2.fa {projectDir}/adapter/
```

### 3.2 Kraken2 database (Standard-8, ~8GB RAM)

```bash
cd {projectDir}
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08_GB_20260626.tar.gz

mkdir -p {projectDir}/ref/kraken2_std8_db
tar -xzvf k2_standard_08_GB_20260626.tar.gz -C {projectDir}/ref/kraken2_std8_db
```

Kiểm tra đủ 3 file bắt buộc sau khi giải nén:
```bash
ls {projectDir}/ref/kraken2_std8_db/*.k2d
# phải thấy: hash.k2d, opts.k2d, taxo.k2d
```

### 3.3 ABRicate database

```bash
mkdir -p {projectDir}/ref/abricate_db

singularity exec \
    --bind {projectDir}/ref/abricate_db:/usr/local/db \
    {projectDir}/singularity/abricate_1.4.0.sif \
    abricate-get_db --db ncbi --dbdir /usr/local/db --force
```

Kiểm tra:
```bash
ls {projectDir}/ref/abricate_db/
```

## 4. Run the pipeline

```bash
bash run_sbatch.sh
```
hoặc
```bash
sbatch run_sbatch.sh
```
tùy theo cấu hình SLURM của bạn (chạy trực tiếp trên node hiện tại vs. tự submit job).

`run_sbatch.sh` sẽ gọi `run.sh` với các tham số:
- `-i` đường dẫn input CSV
- `-o` thư mục output
- `-r` thư mục resources (chứa `kraken2_std8_db/`, `abricate_db/`)
- `-j` tên ABRicate database (mặc định `ncbi`)
- `-k` tên thư mục con chứa Kraken2 database (mặc định `kraken2_std8_db`)