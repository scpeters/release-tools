import _configs_.*
import javaposse.jobdsl.dsl.Job

def npm_ignition_projects = [ 'bay' ]

def ci_web_distros = [ 'xenial' ]
def supported_arches = [ 'amd64' ]

// MAIN CI job

npm_ignition_projects.each { ign_sw ->
  ci_web_distros.each { distro ->
    supported_arches.each { arch ->
      // 1. Create the default ci jobs
      def ignition_ci_job_name = "ignition_${ign_sw}-ci-${distro}-${arch}"

      // --------------------------------------------------------------
      // 0. Main CI workflow
      def ign_ci_main = workflowJob("ignition_${ign_sw}-ci-pr_any")
      OSRFCIWorkFlow.create(ign_ci_main, ignition_ci_job_name)

      // --------------------------------------------------------------
      // 1. Create the default ci jobs
      def ignition_ci_job = job(ignition_ci_job_name)
      def checkout_dir="ign-${ign_sw}"

      OSRFLinuxNpm.create(ignition_ci_job)
      ignition_ci_job.with
      {
          scm {
            hg("http://bitbucket.org/ignitionrobotics/ign-${ign_sw}") {
              branch('default')
              subdirectory(checkout_dir)
            }
          }

          triggers {
            scm('*/5 * * * *')
          }

          steps {
            shell("""\
                  #!/bin/bash -xe

                  export DISTRO=${distro}
                  export ARCH=${arch}
                  export SOFTWARE_DIR=${checkout_dir}
                  /bin/bash -xe ./scripts/jenkins-scripts/docker/generic-npm-install.bash
                  """.stripIndent())
          }
      }

      // --------------------------------------------------------------
      // 2. Create the any job
      def ignition_ci_any_job = job("ignition_${ign_sw}-ci-pr_any-${distro}-${arch}")
      OSRFLinuxCompilationAny.create(ignition_ci_any_job,
                                    "http://bitbucket.org/ignitionrobotics/ign-${ign_sw}")
      ignition_ci_any_job.with
      {
        steps {
         shell("""\
              export DISTRO=${distro}
              export ARCH=${arch}
              export SOFTWARE_DIR=${checkout_dir}
              /bin/bash -xe ./scripts/jenkins-scripts/docker/generic-npm-install.bash
              """.stripIndent())
        }
      }
    } // end of arch
  } // end of distro
} // end of projects
