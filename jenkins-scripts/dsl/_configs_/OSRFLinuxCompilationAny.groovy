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

      publishers
      {
        postBuildTask {
            /* Set aborts, failures and unstable as a failure in bitbucket */
            task('marked build as failure', '/bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash failure  ', false, false)
            task('Build was aborted', '/bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash failure  ', false, false)
            task('result to UNSTABLE', '/bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash failure  ', false, false)
            /* Set the success builds (true in the last argument) not unstable as ok */
            task('(?!result to UNSTABLE)', '/bin/bash -xe ./scripts/jenkins-scripts/_bitbucket_set_status.bash ok  ', false, true)
        }
      }
    }
  }
}
