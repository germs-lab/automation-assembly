seq_R1 = $(wildcard *R1*fastq.gz)

all: interleave-command.sh diginorm-command.sh error-trim.sh final-contigs.fa

trim-command.sh: 
	for x in $(seq_R1) ; do \
		echo "java -jar /usr/local/bin/trimmomatic-0.27.jar PE $${x%_R1*}_R1_001.fastq.gz $${x%_R1*}_R2_001.fastq.gz s1_pe s1_se s2_pe s2_se ILLUMINACLIP:/root/Trimmomatic-0.27/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:100 1>$${x%_R1*}.log" ; \
	done > trim-command.sh 
	cat trim-command.sh | /root/parallel-20100424/src/parallel

interleave-command.sh: $(seq_R1)
	for x in $(seq_R1) ; do \
		echo "/root/khmer/scripts/interleave-reads.py $${x%_R1*}_R1_001.fastq.gz $${x%_R1*}_R2_001.fastq.gz -o $${x%_R1*}.interweaved.fastq" ; \
	done > interleave-command.sh
	cat interleave-command.sh | /root/parallel-20100424/src/parallel

diginorm-command.sh: interleave-command.sh
	echo "/root/khmer/scripts/normalize-by-median.py --ksize 20 -R diginorm.report -C 20 --n_tables 4 --min-tablesize 20e9 -p -s normC20k20.kh *interweaved.fastq" > diginorm-command.sh
	bash diginorm-command.sh 

error-trim.sh: diginorm-command.sh
	echo "/root/khmer/scripts/filter-abund.py -V normC20k20.kh *keep" > error-trim.sh
	bash error-trim.sh

final-contigs.fa:
	gzip *abundfilt
	cat *abundfilt*gz > abundfilt-all.gz
	~/megahit/megahit -m 25e9 -l 250 --k-max 81 -r abundfilt-all.gz $ --cpu-only -o megahit_assembly
