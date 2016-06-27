import _configs_.*
import javaposse.jobdsl.dsl.Job

def supported_distros = [ 'xenial' ]
def supported_arches = [ 'amd64' ]
def gpu_to_use = "gpu-intel"


Globals.extra_emails = "hugo@osrfoundation.org"

supported_distros.each { distro ->
  supported_arches.each { arch ->
    // --------------------------------------------------------------
    // 1. Create the default ci jobs
    def gazebojs_ci_job = job("gazebojs-ci-default-${distro}-${arch}")
    OSRFUNIXBase.create(gazebojs_ci_job)

    gazebojs_ci_job.with
    {
      label "${gpu_to_use}"

      scm {
          hg('http://bitbucket.org/osrf/gazebojs') {
            branch('default')
            subdirectory('gazebojs')
          }
        }

        triggers {
          scm('*/5 * * * *')
        }

        steps {
          shell("""#!/bin/bash -xe

                export DISTRO=${distro}
                export ARCH=${arch}
                /bin/bash -xe ./scripts/jenkins-scripts/docker/gazebojs-compilation.bash
                """.stripIndent())
        }
    }

    // --------------------------------------------------------------
    // 2. Create the ANY job
    def gazebojs_any_ci_job = job("gazebojs-ci-pr_any-${distro}-${arch}")
    OSRFUNIXBase.create(gazebojs_any_ci_job)
    GenericAnyJob.create(gazebojs_any_ci_job, 'http://bitbucket.org/osrf/gazebojs')

    gazebojs_any_ci_job.with
    {
      label "${gpu_to_use}"

      parameters
      {
        stringParam('DEST_BRANCH','default',
                    'Destination branch where the pull request will be merged.' +
                    'Mostly used to decide if calling to ABI checker')
      }

      steps {
        shell("""#!/bin/bash -xe

              export DISTRO=${distro}
              export ARCH=${arch}
              /bin/bash -xe ./scripts/jenkins-scripts/docker/gazebojs-compilation.bash
              """.stripIndent())
      }
    }
  }
}
