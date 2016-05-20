package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxNpm
  -> GenericAnyJob

  Implements:
    -
*/
class OSRFLinuxNpmAny
{
  static void create(Job job)
  {
    OSRFLinuxNpm.create(job)
    
    /* Properties from generic any */
    GenericAnyJob.create(job, repo)

    job.with
    {
      wrappers {
        preBuildCleanup {
            includePattern('pkgs/*')
            deleteDirectories()
        }
      }
    } // end of job
  } // end of method createJob
} // end of class
