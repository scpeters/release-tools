import _configs_.*
import javaposse.jobdsl.dsl.Job

def sdformat_supported_branches = [ 'sdformat2', 'sdformat3' ]
def nightly_sdformat_branch = [ 'sdformat4' ]

// Main platform using for quick CI
def ci_distro               = Globals.get_ci_distro()
def abi_distro              = Globals.get_abi_distro()
// Other supported platform to be checked but no for quick
// CI integration.
def other_supported_distros = Globals.get_other_supported_distros()
def all_supported_distros   = Globals.get_all_supported_distros()
def supported_arches        = Globals.get_supported_arches()
def experimental_arches     = Globals.get_experimental_arches()

// Need to be used in ci_pr
String abi_job_name = ''

// Helper function
String get_sdformat_branch_name(String full_branch_name)
{
  String sdf_branch = full_branch_name.replace("ormat",'')

  if ("${full_branch_name}" == 'sdformat2')
     sdf_branch = 'sdf_2.3'

  return sdf_branch
}

// ABI Checker job
// Need to be the before ci-pr_any so the abi job name is defined
abi_distro.each { distro ->
  supported_arches.each { arch ->
    abi_job_name = "sdformat-abichecker-any_to_any-${distro}-${arch}"
    def abi_job = job(abi_job_name)
    OSRFLinuxABI.create(abi_job)
    abi_job.with
    {
      steps {
        shell("""\
              #!/bin/bash -xe

              export DISTRO=${distro}
              export ARCH=${arch}
              /bin/bash -xe ./scripts/jenkins-scripts/docker/sdformat-abichecker.bash
	      """.stripIndent())
      } // end of steps
    }  // end of with
  } // end of arch
} // end of distro

// MAIN CI JOBS @ SCM/5 min
ci_distro.each { distro ->
  supported_arches.each { arch ->
    // --------------------------------------------------------------
    // 1. Create the default ci jobs
    def sdformat_ci_job = job("sdformat-ci-default-${distro}-${arch}")
    OSRFLinuxCompilation.create(sdformat_ci_job)
    sdformat_ci_job.with
    {
      scm {
        hg("http://bitbucket.org/osrf/sdformat") {
          branch('default')
          subdirectory("sdformat")
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
	      /bin/bash -xe ./scripts/jenkins-scripts/docker/sdformat-compilation.bash
	      """.stripIndent())
      }
    }

    // --------------------------------------------------------------
    // 2. Create the any job
    def sdformat_ci_any_job = job("sdformat-ci-pr_any-${distro}-${arch}")
    OSRFLinuxCompilationAny.create(sdformat_ci_any_job,
				  "http://bitbucket.org/osrf/sdformat")
    sdformat_ci_any_job.with
    {
      parameters
      {
        stringParam('DEST_BRANCH','default',
                    'Destination branch where the pull request will be merged')
      }

      steps
      {
         conditionalSteps
         {
           condition
           {
             not {
               expression('${ENV, var="DEST_BRANCH"}', 'default')
             }

             steps {
               downstreamParameterized {
                 trigger("${abi_job_name}") {
                   parameters {
                     predefinedProp("ORIGIN_BRANCH", '$DEST_BRANCH')
                     predefinedProp("TARGET_BRANCH", '$SRC_BRANCH')
                   }
                 }
               }
             }
           }
         }

         shell("""\
         #!/bin/bash -xe

         export DISTRO=${distro}
         export ARCH=${arch}
         /bin/bash -xe ./scripts/jenkins-scripts/docker/sdformat-compilation.bash
         """.stripIndent())
       }
     }
  } // end of arch
} // end of distro

// OTHER CI SUPPORTED JOBS (default branch) @ SCM/DAILY
other_supported_distros.each { distro ->
  supported_arches.each { arch ->
    // ci_default job for the rest of arches / scm@daily
    def sdformat_ci_job = job("sdformat-ci-default-${distro}-${arch}")
    OSRFLinuxCompilation.create(sdformat_ci_job)
    sdformat_ci_job.with
    {
      scm {
        hg("http://bitbucket.org/osrf/sdformat") {
          branch('default')
          subdirectory("sdformat")
        }
      }

      triggers {
        scm('@daily')
      }

      steps {
        shell("""\
        #!/bin/bash -xe

	export DISTRO=${distro}
        export ARCH=${arch}
        /bin/bash -xe ./scripts/jenkins-scripts/docker/sdformat-compilation.bash
        """.stripIndent())
      }
    }
  } // end of arch
} // end of distro

