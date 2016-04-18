package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxBuildPkg

  Implements:
    - parameters:
        - RELEASE_REPO_BRANCH
    - publish artifacts
    - launch repository_ng
*/
class OSRFLinuxBuildPkgPrivate

{
  static void create(Job job, String repo)
  {
    OSRFLinuxBuildBasePkg.create(job)

    job.with
    {
      parameters {
        stringParam("RELEASE_REPO_BRANCH", null,
                    "Branch from the -release repo to be used")
        stringParam('SRC_TAG_TO_BUILD', 'default',
                    'Branch from the repo software to built package from')
        stringParam("UPLOAD_TO_REPO", 'private', "You should not need to modify this value.")
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

      scm
      {
        hg(repo) {
          branch('${SRC_TAG_TO_BUILD}')
          // script expect the path at WORKSPACE/build/$PACKAGE
          subdirectory('build/${PACKAGE}')
          credentials(Globals.get_bitbucket_bot_username())
        }
      }
    } // end of job
  } // end of method createJob
} // end of class
