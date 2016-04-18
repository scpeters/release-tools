package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxBuildPkg

  Implements:
    - parameters:
        - SOURCE_TARBALL_URI
        - RELEASE_REPO_BRANCH
        - UPLOAD_TO_REPO
    - publish artifacts
    - launch repository_ng
*/
class OSRFLinuxBuildPkg

{  
  static void create(Job job)
  {
    OSRFLinuxBuildBasePkg.create(job)

    job.with
    {
      parameters {
        stringParam("SOURCE_TARBALL_URI", null, "URL to the tarball containing the package sources")
        stringParam("RELEASE_REPO_BRANCH", null, "Branch from the -release repo to be used")
        stringParam("UPLOAD_TO_REPO", null, "OSRF repo name to upload the package to")
      }

      steps {
        systemGroovyCommand("""\
          build.setDescription(
          '<b>' + build.buildVariableResolver.resolve('VERSION') + '-' + 
          build.buildVariableResolver.resolve('RELEASE_VERSION') + '</b>' +
          '(' + build.buildVariableResolver.resolve('DISTRO') + '/' + 
                build.buildVariableResolver.resolve('ARCH') + ')' +
          '<br />' +
          'branch: ' + build.buildVariableResolver.resolve('RELEASE_REPO_BRANCH') + ' | ' +
          'upload to: ' + build.buildVariableResolver.resolve('UPLOAD_TO_REPO') +
          '<br />' +
          'RTOOLS_BRANCH: ' + build.buildVariableResolver.resolve('RTOOLS_BRANCH'));
          """.stripIndent()
        )
      }

      publishers {
        archiveArtifacts('pkgs/*')

        downstreamParameterized {
	  trigger('repository_uploader_ng') {
	    condition('SUCCESS')
	    parameters {
	      currentBuild()
	      predefinedProp("PROJECT_NAME_TO_COPY_ARTIFACTS", "\${JOB_NAME}")
	    }
	  }
        }
      }
    } // end of job
  } // end of method createJob
} // end of class
