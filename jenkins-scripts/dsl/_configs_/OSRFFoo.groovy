package _configs_

import javaposse.jobdsl.dsl.Job

def create_status_name = Globals.bitbucket_build_status_job_name

/* 
 * -> OSRFWorkFlow Main
 *
 *  Implements:
 *    - label
 *    - workflow definition
 *    - parameters
 */
class OSRFFoo
{
   static void create(Job job, String build_any_job_name)
   {
     job.with
     {
       label "master || docker"

       definition
       {
         cps
         {
           // run script in sandbox groovy
           sandbox()
        }
      }
 
      parameters {
        stringParam('RTOOLS_BRANCH','default','release-tools branch to send to jobs')
        stringParam('SRC_REPO','','URL pointing to repository')
        stringParam('SRC_BRANCH','default','Branch of SRC_REPO to test')
        stringParam('JOB_DESCRIPTION','','Description of the job in course. For information proposes.')
        stringParam('DEST_BRANCH','default','Branch to merge in')
      } // end of parameters
    } // end of job
  } // end of create
} 
