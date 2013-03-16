cd /Users/wenqili/Documents/optAnalyse/bagofpixels
declare -a name=('2' '4' '8' '16' '32' '64' '128' '256' '512');
for i in ${name[@]}
do
    echo $i
    sed "s/n=.*/n=$i;/" batch.m > temp
    mv temp batch.m
    mkdir /Users/wenqili/desktop/output/RP_9_$i
    cp -r /Users/wenqili/desktop/cuboid_21 /Users/wenqili/desktop/output/RP_9_$i
    matlab -nojvm -r "batch"
done
