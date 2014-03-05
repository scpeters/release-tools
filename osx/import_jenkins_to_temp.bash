ORIG="/Users/jenkins/2jenkins.yLtQ"
DEST="/tmp/jenkins.yLtQ"

rm -fr ${DEST}

sudo cp -R ${ORIG} ${DEST}
sudo chown -R jrivero ${DEST}
sudo chmod -R 777 ${DEST}
