# No explicit activation means no coverage
[ -z ${COVERAGE_ENABLED} ] && COVERAGE_ENABLED=false

code_coverage_prepare_if_enabled()
{
  if [[ ! ${COVERAGE_ENABLED} ]]; then
      echo "Code coverage analysis is not enabled"
      return
  fi

  # Download and install Bullseyes
  cd $WORKSPACE
  wget http://www.bullseye.com/download/BullseyeCoverage-8.7.42-Linux-x64.tar -O bullseye.tar
  tar -xf bullseye.tar
  cd Bulls*
  # Set up the license
  echo $PATH >install-path
  scp yos@localhost:~/bull-license .
  set +x # keep password secret
  ./install --prefix /usr/bullseyes  --key $(cat ${WORKSPACE}/bull-license)
  set -x # back to debug
  # Set up Bullseyes for compiling
  export PATH=/usr/bullseyes/bin:\$PATH
  export COVFILE=$WORKSPACE/gazebo/test.cov
  cd $WORKSPACE/gazebo
  covselect --file test.cov --add .
  cov01 --on
}

code_coverage_generate_if_enabled()
{
  if [[ ! ${COVERAGE_ENABLED} ]]; then
      echo "Code coverage analysis is not enabled"
      return
  fi

  rm -fr $WORKSPACE/coverage
  mkdir -p $WORKSPACE/coverage
  covselect --add '!build/' '!deps/' '!/opt/'
  covhtml --srcdir $WORKSPACE/gazebo/ $WORKSPACE/coverage
  # Generate valid cover.xml file using the bullshtml software
  # java is needed to run bullshtml
  apt-get install -y default-jre
  cd $WORKSPACE
  wget http://bullshtml.googlecode.com/files/bullshtml_1.0.5.tar.gz -O bullshtml.tar.gz
  tar -xzf bullshtml.tar.gz
  cd bullshtml
  sh bullshtml .
}
