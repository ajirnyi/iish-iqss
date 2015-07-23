class iqss::dataverse::content {

  exec {
    'Run /opt/trigger.sh for ingest content':
      command =>  '/opt/trigger.sh',
      timeout => 600,
      creates => "${iqss::dataverse::autodeploy_folder}/applications/__internal",
  }

}