# Generate a build.sh file with the contents of the generic compilation
# SCRIPT_DIR needed. There is value in having the compilation code
# independent (to be run) in its own file and having this to generate a
# build.sh (not run at the moment) with the compilation code (vars expanded)

cat > build.sh <<- EOF
$(envsubst ${SCRIPT_DIR}/lib/_generic_linux_compilation.bash)
EOF
