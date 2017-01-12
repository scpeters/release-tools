import _configs_.*
import javaposse.jobdsl.dsl.Job

def supported_distros = [ 'trusty']
def supported_arches  = [ 'amd64' ]

def snapshot_job = job("ros_snapshots_mirror-create_snapshot")
OSRFLinuxBase.create(snapshot_job)
snapshot_job.with
{
  label "ros_snapshots_mirror.trusty"

  wrappers {
    preBuildCleanup {
       includePattern('info/*')
      // the sudo does not seems to be able to remove root owned packaged
      deleteCommand('sudo rm -rf %s')
    }
  }

  parameters
  {
    stringParam('SNAPSHOT_TAG', '', 'Optional tag to identify the snapshot')
  }
         
  steps
  {
    shell("""\
      #!/bin/bash -xe

      /bin/bash -xe ./scripts/jenkins-scripts/docker/ros_snapshots_mirror_create_snapshot.bash
      """.stripIndent())
  }

  publishers
  {
    archiveArtifacts('info/*')
  }
}

def checker_job = job("ros_snapshots_mirror-check_for_new_snapshot")
OSRFLinuxBase.create(checker_job)
checker_job.with
{
  label "ros_snapshots_mirror.trusty"

  steps
  {
    shell("""\
      #!/bin/bash -xe

      /bin/bash -xe ./scripts/jenkins-scripts/docker/ros_snapshots_mirror_checker.bash
      """.stripIndent())
  }

  publishers
  {
    consoleParsing {
        globalRules('/var/lib/jenkins/logparser_warn_on_mark_unstable')
        unstableOnWarning()
    }
  }
}


def snapshot_publish_job = job("ros_snapshots_mirror-publish_snapshot")
OSRFLinuxBase.create(snapshot_publish_job)
snapshot_publish_job.with
{
  steps
  {

    label "ros_snapshots_mirror.trusty"

    parameters
    {
      stringParam('SNAPSHOT_NAME', '', 'Internal snapshot name to publish as external repo')
    }
   
    shell("""\
      #!/bin/bash -xe

      /bin/bash -xe ./scripts/jenkins-scripts/docker/ros_snapshots_mirror_publish_snapshot.bash
      """.stripIndent())
  }

  publishers
  {
    archiveArtifacts('info/*')
  }
}

supported_distros.each { distro ->
  supported_arches.each { arch ->
    def install_job = job("ros_snapshots_mirror-install-${distro}-${arch}")
    OSRFLinuxBase.create(install_job)
    install_job.with
    {
      steps
      {
        shell("""\
	      #!/bin/bash -xe

	      export DISTRO=${distro}
              export ARCH=${arch}
	      /bin/bash -xe ./scripts/jenkins-scripts/docker/ros_snapshots_mirror_desktop_full_install.bash
	      """.stripIndent())
      }
    }
  }
}
