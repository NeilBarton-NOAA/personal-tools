#!/bin/sh
SRC_DIR="/gpfs/f6/sfs-emc/proj-shared/Yangxing.Zheng/SFS/ICs/CPC/C96mx100"
DES_DIR="${NPB_WORKDIR}/ICs/CPC/C96mx100"
mkdir -p ${DES_DIR}
cd ${SRC_DIR}
ds=$( ls -d sfs.*/ )
for d in ${ds}; do
    echo ${d}
    files=$( find ${d} -type f | grep mem000)
    for f in ${files}; do
        new_f=$(echo "${f}" | sed 's#sfs#gfs#; s#mem000/##')
        mkdir -p ${DES_DIR}/$(dirname ${new_f})
        ln -fs ${SRC_DIR}/${f} ${DES_DIR}/${new_f}
        new_f=$(echo "${f}" | sed 's#sfs#gdas#; s#mem000/##')
        mkdir -p ${DES_DIR}/$(dirname ${new_f})
        ln -fs ${SRC_DIR}/${f} ${DES_DIR}/${new_f}
    done
done

