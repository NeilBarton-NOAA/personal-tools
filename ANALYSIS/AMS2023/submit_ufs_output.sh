#! /usr/bin/env bash
set -u

# P8
declare -A FILES
FILES=( 
["TMP"]="surface 1hybridlevel 2maboveground"
["PWAT"]="entireatmosphere_consideredasasinglelayer_"
["TCDC"]="convectivecloudlayer"
["MCDC"]="middlecloudlayer"
["LCDC"]="lowcloudlayer"
["DSWRF"]="surface"
["DLWRF"]="surface"
["USWRF"]="surface"
["ULWRF"]="surface"
["SHTFL"]="surface"
["LHTFL"]="surface"
["SNOD"]="surface"
["HGT"]="surface"
["PRES"]="surface"
["VGRD"]="10maboveground"
["UGRD"]="10maboveground"
["SPFH"]="2maboveground 1hybridlevel"
)
#FILES=( 
#["SPFH"]="1hybridlevel"
#)
#FILES=( 
#["DLWRF"]="surface"
#)
#FILES=( 
#["DLWRF"]="surface"
#["TMP"]="2maboveground 1hybridlevel"
#["SPFH"]="1hybridlevel"
#)
FILES=(
["CRF_LW"]="surface"
["CRF_SW"]="surface"
["SNOD"]="surface"
["ALBDO"]="surface"
["SNOWC"]="surface"
["HGT"]="surface 1hybridlevel"
)
FILES=(
["LCDC"]="lowcloudlayer"
["MCDC"]="middlecloudlayer"
)
for file in "${!FILES[@]}"; do
    vars=${FILES[$file]}
    files="/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8T/${file}.nc /scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8G/${file}.nc"
    for var in $vars; do
        echo $file $var
        v=${file}_${var}
        echo $files
        #/home/Neil.Barton/ANALYSIS/ufs_output_compare.py -f ${files} -v ${v} && exit 1
        submit_file=~/ANALYSIS/${file}${var}_submit_ufs_output
        rm ${submit_file} 2>/dev/null
        rm ${file}${var}.o3* 2>/dev/null
#################################################
cat<<EOF > ${submit_file}
#!/bin/sh -l
#SBATCH -J ${file}${var}
#SBATCH --time=02:00:00
#SBATCH -o %x.o%j
#SBATCH --ntasks=1
#SBATCH --exclusive #may mean use all memory
#SBATCH -A marine-cpu
/home/Neil.Barton/ANALYSIS/ufs_output_compare.py -f ${files} -v ${v}
EOF

################################################
sbatch ${submit_file}
  
    done
done


