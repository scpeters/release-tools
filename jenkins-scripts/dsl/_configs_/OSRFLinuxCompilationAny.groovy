package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxCompilation
  -> GenericAnyJob

  Implements:
   - DEST_BRANCH parameter
*/
class OSRFLinuxCompilationAny
{
  static void create(Job job, String repo)
  {
    OSRFLinuxCompilation.create(job)

    /* Properties from generic any */
    GenericAnyJob.create(job, repo)

    job.with
    {
      steps
      {
        shell("""\
        #!/bin/bash -xe

        /bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_create_build_status_file.bash
        /bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash inprogress
        """.stripIndent())
      }

      parameters
      {
        stringParam('DEST_BRANCH','default',
                    'Destination branch where the pull request will be merged.' +
                    'Mostly used to decide if calling to ABI checker')
      }

      conditionalSteps {
        condition {
          status("Success", "Success")
        }
        steps {
          shell("""\
            #!/bin/bash -xe

            /bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash ok
            """.stripIndent())
        }

        condition {
          not {
            status("Success", "Success")
          }
        }
        steps {
          shell("""\
            #!/bin/bash -xe

            /bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash failed
            """.stripIndent())
        }
      } // end of conditional steps
    } // end of with
  } // end of create method
} // end of class
