package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxBase

  Implements:
    -
*/
class OSRFLinuxNpm
{
  static void create(Job job)
  {
    OSRFLinuxBase.create(job)

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
