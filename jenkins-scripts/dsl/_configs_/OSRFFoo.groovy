package _configs_

import javaposse.jobdsl.dsl.Job

def create_status_name = Globals.bitbucket_build_status_job_name

/*
  -> GenericMail

  Implements:
     - description
     - RTOOLS parame + groovy to set jobDescription
     - base mail for Failures and Unstables
*/

class OSRFFoo
{
   static void create(Job job, String build_any_job_name)
   {
      job.with
      {
        label "master || docker"

        // TODO: share parameters with ci-py_any- jobs
        parameters {
          stringParam('RTOOLS_BRANCH','default','release-tools branch to send to jobs')
          stringParam('SRC_REPO','','URL pointing to repository')
          stringParam('SRC_BRANCH','default','Branch of SRC_REPO to test')
          stringParam('JOB_DESCRIPTION','','Description of the job in course. For information proposes.')
          stringParam('DEST_BRANCH','default','Branch to merge in')
        }

        definition
        {
          cps
          {
            // run script in sandbox groovy
            sandbox()
            script("""\
                 currentBuild.description =  "\$JOB_DESCRIPTION"
                 def archive_number = ""

                 stage 'checkout for the mercurial hash'
                  node("master") {
                   checkout([\$class: 'MercurialSCM', credentialsId: '', installation: '(Default)', 
                             revision: "\$SRC_BRANCH", source: "\$SRC_REPO",
                             propagate: false, wait: true])
                    sh 'echo `hg id -i` > SCM_hash'
                    env.MERCURIAL_REVISION_SHORT = readFile('SCM_hash').trim()

                 stage 'create bitbucket status file'
                  node {
                    def bitbucket_metadata = build job: '${create_status_name}',
                          propagate: false, wait: true,
                          parameters:
                            [[\$class: 'StringParameterValue', name: 'RTOOLS_BRANCH',          value: "\$RTOOLS_BRANCH"],
                             [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_REPO',     value: "\$SRC_REPO"],
                             [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_HG_HASH',  value: env.MERCURIAL_REVISION_SHORT],
                             [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_JOB_NAME', value: env.JOB_NAME],
                             [\$class: 'StringParameterValue', name: 'JENKINS_BUILD_URL',      value: env.BUILD_URL]]
                    archive_number = bitbucket_metadata.getNumber().toString()
                  }


                  }
              """.stripIndent())
          } // end of cps
        } // end of definition
      } // end of job
   } // end of create
}
