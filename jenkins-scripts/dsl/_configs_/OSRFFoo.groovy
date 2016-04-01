package _configs_

import javaposse.jobdsl.dsl.Job

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

        definition
        {
          cps
          {
            // run script in sandbox groovy
            sandbox()
          }
        }
      }
   }
}
