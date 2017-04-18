import javaposse.jobdsl.dsl.Job
  class MyUtilities {
    def addEnterpriseFeature(Job job) {
        job.with {
          description('Arbitrary feature')
       }
    }
  }
