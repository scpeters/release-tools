# handy script to generate a the generic build.sh file and run it
# for details read _generic_linux_compilation_build.sh.bash
SCRIPT_DIR=${1}

if [[ -n ${MAKE_JOBS} ]]; then
    echo ${MAKE_JOBS} > ${WORKSPACE}/make_jobs
else
    echo "MAKE_JOBS empty!"
fi

. ${SCRIPT_DIR}/lib/_generic_linux_compilation_build.sh.bash
. build.sh
