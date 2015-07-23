class iqss::dataverse::war {

  archive { 'maven3':
    ensure           => present,
    url              => 'ftp://mirror.reverse.net/pub/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.zip',
    target           => '/opt', # Just a temporary place.
    follow_redirects => true,
    extension        => 'zip',
    checksum         => false,
  }->exec { 'copy maven3':
    command => '/usr/bin/rsync -av /opt/apache-maven-3.3.3/ /usr/share/maven',
    creates => '/usr/share/maven';
  }

  file {
    '/usr/bin/mvn':
      ensure => link,
      target => '/usr/share/maven/bin/mvn';
    '/usr/bin/mvnDebug':
      ensure => link,
      target => '/usr/share/maven/bin/mvnDebug';
    '/opt/trigger.sh':
      ensure  => file,
      owner   => $iqss::dataverse::glassfish_user,
      group   => $iqss::dataverse::glassfish_user,
      content => template('iqss/dataverse/trigger.sh.erb'),
      mode    => 744;
  }

  if ( $iqss::dataverse::trigger ) {
    cron {
      'Dataverse repository trigger':
        ensure  => present,
        command => '/opt/trigger.sh',
        user    => root,
        minute  => $iqss::dataverse::trigger,
    }

  } else {
    cron {
      'Dataverse repository trigger':
        ensure => absent,
    }
  }

# For the console API command handling.
  include jq

  file {
    '/usr/bin/jq':
      ensure => link,
      target => '/usr/local/bin/jq',
  }

  file {
    '/opt/dataverse':
      ensure  => file,
      recurse => true,
      source  => 'puppet:///modules/iqss/dataverse';
  }

}