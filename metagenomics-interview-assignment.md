# Take-Home Technical Exercise — Field Application Scientist / Bioinformatician

## Scenario

You've just joined the team. A customer has shared shotgun
metagenomic sequencing data from an environmental sample and wants a quick
technical read-out before a follow-up call: is the data usable, what's living
in the sample, and are there any antimicrobial resistance (AMR) genes worth
flagging? This exercise asks you to do that analysis end-to-end, the way you
would for a real customer request.

## Deadline & expected effort

You have **48 hours** from receipt of this document to submit. That said, the
task itself is scoped to roughly **8 hours of hands-on work** — the 48-hour
window is to fit around your schedule, not to reward marathon effort. Submit
whenever you're done; you don't need to use the full window.

## Dataset

Real shotgun metagenomic data from a Galaxy Training Network tutorial,
originally collected from the Cuatro Ciénegas oasis (Mexico), from a pond
mesocosm experiment. Paired-end, adapter-trimmed reads, hosted on Zenodo:

**Zenodo record:** https://zenodo.org/record/7871630

- **Required sample — `JC1A`** (control mesocosm, ~42 MB total):
  - `JC1A_R1.fastqsanger.gz`
  - `JC1A_R2.fastqsanger.gz`
- **Optional stretch sample — `JP4D`** (fertilized pond, ~380 MB total):
  - `JP4D_R1.fastqsanger.gz`
  - `JP4D_R2.fastqsanger.gz`
  - This file is large enough that you may need to subsample it to fit your
    resource/time budget. If you use it, **document what you subsampled and
    why** — that judgment call is part of what we're evaluating.

## Constraints

- **Hardware:** assume a standard laptop — no GPU, 8–16 GB RAM. Your pipeline
  should complete within roughly **8 hours of active compute time** on
  hardware like this.
- **Tool choice is yours.** There is no single required tool for taxonomic
  classification or AMR detection. Pick what fits your resource budget and
  justify the choice in your results doc. (Heads-up: the reference database
  used in the original GTN tutorial this data comes from is ~80 GB — that is
  **not** expected or required here. Smaller pre-built databases, capped
  databases, marker-gene-based classifiers, and read-based AMR tools that
  skip assembly are all reasonable directions to look into.)
- **Language choice is yours, but Nextflow, BASH, Python, R is preferred**
- **AI coding assistants are allowed** (Copilot, ChatGPT, Claude, etc.) —
  just disclose what you used and for what in your submission. We're
  evaluating your judgment and the correctness of the result, not whether
  you typed every line yourself.

## Tasks

### 1. Quality control

- Assess raw read quality.
- Trim/filter as appropriate (adapters, low-quality bases, etc.).
- Report before/after metrics (e.g. read counts, quality distributions,
  anything else you consider relevant).

### 2. Taxonomic profiling

- Classify the (trimmed) reads taxonomically.
- Produce a summary of the top taxa by relative abundance (a table is fine;
  a chart is a nice-to-have, not required).

### 3. AMR gene detection

- Screen for antimicrobial resistance genes/gene families.
- Report what was detected, with whatever confidence/identity/coverage
  metrics your tool provides.

## Interpretation questions

Answer these in your results doc, briefly (a few sentences each is fine):

1. What data-quality issues, if any, did you observe in the raw reads, and
   how did they influence your trimming parameters?
2. Which taxa dominate this sample's community? Does that composition seem
   biologically plausible for an environmental pond/mesocosm sample, and
   what would make you suspicious of a misclassification?
3. Why did you choose your taxonomic classifier/database over alternatives,
   given the stated resource budget?
4. What AMR genes/classes did you detect, and what's a key limitation of
   your detection approach that you'd flag before anyone acted on this
   result?
5. What's one concrete sanity check you ran to convince yourself your
   results weren't garbage-in-garbage-out? What would you do differently or
   additionally with more time/compute?

## Deliverable

Your choice of:

- **(a)** Script(s)/pipeline + a short results doc (e.g. `RESULTS.md`), or
- **(b)** A GitHub repo with a README covering the same ground.

Either way:

- **It must be reproducible.** Someone with a clean environment should be
  able to go from the raw FASTQ files to your final outputs by following
  your documented steps.
- **Document your environment** (conda `environment.yml`, `Dockerfile`,
  `requirements.txt` — whatever fits your setup) including tool versions.
- **Note the actual wall-clock runtime** and rough resource usage you
  observed, so we know your pipeline was run, not just written.
- If you subsampled anything or used AI assistance, say so explicitly.

## Submission

Send back a zip/tarball, dockerfile, whatsoever or a link to a repo (private is fine) with your
scripts, environment file, and results doc.
