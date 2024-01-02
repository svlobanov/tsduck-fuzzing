#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-2-Clause

#input="in.ts"
input="$1"
#output="out.ts"
#output="/Volumes/RAMDisk/out.ts"
output="$2"
seed_start=$3
seed_end=$4
change_prob_y=$5
change_prob_x="$6"

function test_error {
    $@ 1>/dev/null 2>/dev/null
    local status=$?
    if ((status > 128)); then
        echo "FAILED $status $@ " >&2
    fi
    return $status
}

for SEED in $(seq $seed_start $seed_end); do
    for CHANGE_PROB in $change_prob_x; do
        echo "SEED=$SEED CHANGE_PROB=$CHANGE_PROB/$change_prob_y" $(date)
        ./fuzzing "$input" "$output" $SEED $CHANGE_PROB $change_prob_y 1
        test_error "tsp -I file $output -O drop"
        test_error "tsp -I file $output -P bat -i -O drop"
        test_error "tsp -I file $output -P cat -i -O drop"
        test_error "tsp -I file $output -P pat -i -O drop"
        test_error "tsp -I file $output -P clear -O drop"
        test_error "tsp -I file $output -P continuity -f -O drop"
        test_error "tsp -I file $output -P count -a -O drop"
        test_error "tsp -I file $output -P descrambler 3 -O drop"
        test_error "tsp -I file $output -P eit -O drop"
        test_error "tsp -I file $output -P filter --audio -O drop"
        test_error "tsp -I file $output -P filter --video -O drop"
        test_error "tsp -I file $output -P filter --audio --valid -O drop"
        test_error "tsp -I file $output -P filter --video --valid -O drop"
        test_error "tsp -I file $output -P pcrextract -O drop"
        test_error "tsp -I file $output -P pcrverify -O drop"
        test_error "tsp -I file $output -P pcradjust -O drop"
        test_error "tsp -I file $output -P limit -b 100000 -O drop"
        test_error "tsp -I file $output -P stats -O drop"
        test_error "tsp -I file $output -P splicemonitor -O drop"
        test_error "tsp -I file $output -P sifilter --sdt -O drop"
        test_error "tsp -I file $output -P sifilter --pmt -O drop"
        test_error "tsp -I file $output -P sdt -i -O drop"
        test_error "tsp -I file $output -P rmsplice -i -O drop"
        test_error "tsp -I file $output -P rmorphan -i -O drop"
        test_error "tsp -I file $output -P reduce -i -O drop"
        test_error "tsp -I file $output -P reduce --increment-version -O drop"
        test_error "tsp -I file $output -P pes --avc-access-unit --audio-attributes --intra-image --sei-avc --video-attributes -O drop"
        test_error "tsp -I file $output -P nitscan -a -O drop"
        test_error "tsp -I file $output -P nit -i --cleanup-private-descriptors -O drop"

        test_error "tsp -I file $output -P teletext -O drop"
        test_error "tsanalyze --no-pager $output"
        test_error "tstables --no-pager $output"
        test_error "tsfclean -o /dev/null $output"
        test_error "tsbitrate -a -f $output"
        test_error "tsdate -a $output"

    done
done
