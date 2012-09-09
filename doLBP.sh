cd /Users/wenqili/Documents/optAnalyse/withLBP
declare -a name=('5' '7' '9' '11' '13' '15' '17' '19');
for i in ${name[@]}
do
    echo $i
    sed "s/id=.*/id='$i';/" batch.m > temp
    mv temp batch.m
    sed "s/subSize=.*/subSize=$i;/" batch.m > temp
    mv temp batch.m
    mkdir /Users/wenqili/desktop/output/LBP_$i
    cp -r /Users/wenqili/desktop/cuboid_21 /Users/wenqili/desktop/output/LBP_$i
    matlab -nojvm -r "batch"
done
