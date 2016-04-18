package _configs_

import javaposse.jobdsl.dsl.Job

/*
  -> OSRFLinuxBase
  -> GenericRemoteToken

  Implements:
    - priorioty 300
    - keep only 10 last artifacts
    - parameters:
        - PACKAGE
        - VERSION
        - RELEASE_VERSION
        - DISTRO
        - ARCH
        - PACKAGE_ALIAS 
        - OSRF_REPOS_TO_USE
*/
class OSRFLinuxBuildBasePkg extends OSRFLinuxBase

{  
  static void create(Job job)
  {
    OSRFLinuxBase.create(job)
    GenericRemoteToken.create(job)

    job.with
    {
      properties {
        priority 300
      }

      logRotator {
        artifactNumToKeep(10)
      }

      parameters {
        stringParam("PACKAGE",null,"Package name to be built")
        stringParam("VERSION",null,"Packages version to be built")
        stringParam("RELEASE_VERSION", null, "Packages release version")
        stringParam("DISTRO", null, "Ubuntu distribution to build packages for")
        stringParam("ARCH", null, "Architecture to build packages for")
        stringParam("PACKAGE_ALIAS", null, "If not empty, package name to be used instead of PACKAGE")
        stringParam("OSRF_REPOS_TO_USE", null, "OSRF repos name to use when building the package")
      }

      steps {
        systemGroovyCommand("""\
          build.setDescription(
          '<b>' + build.buildVariableResolver.resolve('VERSION') + '-' + 
          build.buildVariableResolver.resolve('RELEASE_VERSION') + '</b>' +
          '(' + build.buildVariableResolver.resolve('DISTRO') + '/' + 
                build.buildVariableResolver.resolve('ARCH') + ')' +
          '<br />' +
          'RTOOLS_BRANCH: ' + build.buildVariableResolver.resolve('RTOOLS_BRANCH'));
          """.stripIndent()
        )
      }
    } // end of job
  } // end of method createJob
} // end of class
