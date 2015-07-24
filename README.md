Dataverse puppet module
=======================

Table of Contents
-----------------

1. [Overview - What is the Dataverse module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with Dataverse module](#setup)
4. [Before you begin - Pre setup conditions](#before-you-begin)
5. [Configuring the infrastructure - Installing dataverse](#configuring-your-infrastructure)
6. [Hieradata - Using hieradata](#hieradata)
7. [Known issues - Known issues](#known-issues)
8. [To do - Or not to do] (#todo)

Overview
--------

The Dataverse module allows you to install Dataverse with Puppet.

Module Description
-------------------

Dataverse is an open source (code is available on GitHub) web application to share, preserve, cite, explore and analyze
research data. It facilitates making data available to others, and allows you to replicate others work. Researchers,
data authors, publishers, data distributors, and affiliated institutions all receive appropriate credit via a data
citation with a persistent identifier (e.g., DOI, or Handle).The module offers support for basic management of common
security settings.

This module will install dataverse with default settings and allow customisation of those settings.

Setup
-----

**What this Dataverse setup affects:**

* package/service/configuration files for Dataverse, R and R packages, PostgreSQL, Solr and TwoRavens.

**What this Dataverse setup does not affect:**

* You need to run the final database and api scripts to populate your dataverse instance. For example, if you deploy on
a development environment with the default settings run:


    sudo -u dvnApp psql dvndb -f /opt/dataverse/scripts/database/reference_data.sql
    /opt/dataverse/scripts/api/setup-all.sh
    
* optimizations such as the best settings for java and PostgreSQL.
* Shibboleth configurations (as they have an experimental status), although the packages are installed. 

**Introductory Questions**

Before getting started, you will want to consider:

* Do you need a development environment ?
* Are you installing an acceptance environment or production environment ?

Your answers to these questions will determine on which nodes you will install what classes and their parameters.

Before you begin
----------------

These are the dependencies the puppet module needs:
* a first-time update of each of the host's package repository ( e.g. using 'apt-get update' or 'yum update' )
* the unzip utility
* This module depends on the altered fatmcgav-glassfish module which is not part of the puppet force repository.
 There is a [PR:https://github.com/fatmcgav/fatmcgav-glassfish/pull/51] to incorporate them. Until that time use
   the fork and install it on your puppet master or puppetless client environment:
   
     $ wget -O fatmcgav-glassfish-0.6.0.tar.gz https://github.com/IISH/fatmcgav-glassfish/archive/dataverse.tar.gz
     $ puppet module install fatmcgav-glassfish-0.6.0.tar.gz
     
Configuring your infrastructure
-------------------------------

To install Dataverse and TwoRavens with all the out-of-the-box settings use:

    class {
    # The global settings
      'iqss::globals':
        ensure  => present;
    }->class {
      [
        'iqss::database',
        'iqss::dataverse',
        'iqss::solr',
        'iqss::tworavens'
      ]:
    }
    
To install on different machines you can deploy per server per component. E.g.:

    Server A-1: class { 'iqss::globals':}->class { 'iqss::dataverse': }
    Server A-2: class { 'iqss::globals':}->class { 'iqss::dataverse': }
    Server A-3: class { 'iqss::globals':}->class { 'iqss::dataverse': }
    Server B-1: class { 'iqss::globals':}->class { 'iqss::database': }
    Server C-1: class { 'iqss::globals':}->class { 'iqss::solr': }
    Server D-1: class { 'iqss::globals':}->class { 'iqss::tworavens': }
    Server E-1: class { 'iqss::globals':}->class { 'iqss::rserve': }
    
###Classes and Defined Types

This module modifies configuration files and directories.

####Class: Iqss::Globals

This class allows you to configure the global configuration that contain settings shared amongst classes,
most notably the database settings. Example:

    class {
      'iqss::globals':
        ensure            => present,
        dataverse_fqdn    => 'mysite.org',
        database_name     => 'dataverse',
        database_user     => 'dataverse',
        database_password => 'Cárammë',
    }
    
It also contains settings for

#####`apache_purge_configs`

Removes all other Apache configs and vhosts. Setting this to 'false' is a stopgap measure to allow the apache module to coexist with existing or otherwise-managed configuration. Defaults to 'true'.

#####`dataverse_fqdn`

If the Dataverse server has multiple DNS names, this option specifies the one to be used as the “official” host name. For example, you may want to have dataverse.foobar.edu, and not the less appealling server-123.socsci.foobar.edu to appear exclusively in all the registered global identifiers, Data Deposit API records, etc. Defaults to 'localhost'.

Do note that whenever the system needs to form a service URL, by default, it will be formed with https:// and port 443. I.e.,
https://{dataverse.fqdn}/

If that does not suit your setup, use the `Iqss::Dataverse::dataverse_site_url` option.

#####`database_host`

The domain of the database. Defaults to `Globals:dataverse_fqdn`.

#####`database_port`

The port of the database. Defaults to '5432'.

#####`database_name`

The name of the database. Defaults to 'dvndb'.

#####`database_user`

The name of the database owner. Defaults to 'dvnApp'.

#####`database_password`

The password for the database user. Defaults to 'dvnAppPass'.

####Class: Iqss::Dataverse

This class installs Glassfish, the domain settings and depending on the configuration builds a war or pulls a war distribution from a repository. Example:

    class {
        'iqss::dataverse':
            repo => 'https://github.com/IQSS/dataverse/releases/download/v4.0.1/dataverse-4.0.1.war',
    }
    
This will create three services:

* The glassfish service: $ service dataverse start|stop|status
* An R-daemon: $ service rserve start|stop|status
* The Apache web server

It also contains settings for

#####`dataverse_auth_password_reset_timeout_in_minutes`

A JVM option: the time in minutes for a password reset. Defaults to '60'.

#####`dataverse_files_directory`

The location of the uploaded files and their tabular derivatives. Defaults to '/home/glassfish/dataverse/files'.

#####`dataverse_rserve_host`

The Rserve service hostname. Defaults to `Globals:dataverse_fqdn`.

#####`dataverse_rserve_password`

The password needed to access the Rserve service. Defaults to 'rserve'.

#####`dataverse_rserve_port`

The Rserve service port. Defaults to 'rserve'. Defaults to '6311'.

#####`dataverse_rserve_user`

The serve service user. Defaults to 'serve'. 
 
#####`dataverse_site_url`

Set this to override the default URL construction behaviour of the `Global::dataverse_fqdn` setting with a custom value.

#####`doi_baseurlstring`

The DOI endpoint for the EZID Service. Defaults to 'https://ezid.cdlib.org'.
 
#####`doi_username`

The username to connect to the EZID Service. Defaults to 'apitest'. 

#####`doi_password`

The password to connect to the EZID Service. Defaults to 'apitest'. 

#####`glassfish_parent_dir`

The Glassfish parent directory. Defaults to '/home/glassfish'.

#####`glassfish_domain_name`

The domain name. Defaults to 'domain1'.

#####`glassfish_fromaddress`

The e-mail -from field in the mail header. Defaults to 'do-not-reply@localhost'.

#####`glassfish_jvmoption`

An array of jvm options. Defaults to ["-Xmx1024m", "-Djavax.xml.parsers.SAXParserFactory=com.sun.org.apache.xerces.internal.jaxp.SAXParserFactoryImpl"].

#####`glassfish_mailhost`

The mail relay hostname. Defaults to `Globals:dataverse_fqdn`.

#####`glassfish_mailuser`

The user name that is allowed by the mail relay to sent mails. Defaults to 'dataversenotify'.

#####`glassfish_mailproperties`

Key-value pairs sent with to the mail relay, such as credentials. Defaults to dummy values 'username=a_username:password=a_password'.

#####`glassfish_service_name`

The service handle to submit start, stop, status commands. E.g. service dataverse start. Defaults to 'dataverse'

#####`glassfish_tmp_dir`

The download path of the glassfish package. Defaults to '/opt/glassfish'.

#####`glassfish_user`

The user running the glassfish domain. Defaults to 'glassfish'.

#####`glassfish_version`

The Glassfish J2EE Application server version. Defaults to '4.1'.

#####`repository`

The repository url of a Dataverse war file.

#####`trigger`

A timer that monitors the Last Modified Date of the url set by `repository`. Should it change, the trigger scripts will download and deploy a new war. Defaults to three minutes: '*/3.


####Class: Iqss::Database

Installs Postgresql, the database user and database. For example:

    class {
      'iqss::database':
        name     => 'dataverse',
        user     => 'dataverse',
        password => 'secret',
    }
    
Use the Iqss::Globals class to override settings. This will create a running Postgresql server with the
database, users and access policies.

It also contains settings for
   
#####`createdb`
   
When 'true' the user can create databases. Defaults to 'false'.

#####`createrole`

When 'true' the user can create roles. Defaults to 'false'.
 
#####`hba_rule`
 
The access rules that determine who can connect to what database from where. Defaults to:

    IPv4 local connections => {
        description => 'Open up a IP4 connection from localhost',
        type        => 'host',
        database    => 'dvndb',
        user        => 'dvnApp',
        address     => '127.0.0.1/32',
        auth_method => 'md5'
        },
    IPv6 local connections => {
        description => 'Open up a IP6 connection from localhost',
        type        => 'host',
        database    => 'dvndb',
        user        => 'dvnApp',
        address     => '::1/128',
        auth_method => 'md5'
        }
        
#####`host`

The url connection string. Defaults to 'localhost'.

#####`login`

The fact the user can login or not. Defaults to 'true'.

#####`name`

Name of the database. Inherited by iqss::globals::database_name. Defaults to 'dvndb'.

#####`password`

The user password. Defaults to 'dvnAppPass'.

#####`port`

The connection port to the database. Defaults to '5432'

#####`replication`

When 'true' this role can replicate. Defaults to 'false'.

#####`superuser`

When 'true' this role is a superuser. Defaults to 'false'.

#####`user`

The user name. Defaults to 'dvnApp'.

#####`version`

The version of Postgresql. Defaults to '9.3'. 

#####`manage_package_repo`

If `true` this will setup the official PostgreSQL repositories on your host. Defaults to `true`.

#####`encoding`

This will set the default encoding encoding for all databases created with this module. On certain operating systems this will be used during the `template1` initialization as well so it becomes a default outside of the module as well. Defaults to 'UTF-8'.

#####`locale`

This will set the default database locale for all databases created with this module. Defaults to 'en_US.UTF-8'.

#####`listen_addresses`

This value defaults to `localhost`, meaning the postgres server will only accept connections from localhost. If you'd like to be able to connect to postgres from remote machines, you can override this setting. A value of `*` will tell postgres to accept connections from any remote machine. Alternately, you can specify a comma-separated list of hostnames or IP addresses. (For more info, have a look at the `postgresql.conf` file from your system's postgres package).


####Class: Iqss::Solr

Installs Solr. Example:

    class { 'iqss::solr':
        version => '4.7.1',
    }
    
This will create a Jetty server with a running Solr instance : $ service solr stop|status|start

It also contains settings for

#####`core`

The solr core. Defaults to 'collection1'.

#####`jetty_home`

The Jetty home directory which contains start.jar. Defaults to '/home/solr-4.6.0/example'

#####`jetty_host`

Use 0.0.0.0 as host to accept all connections. Defaults to `Globals:dataverse_fqdn`.

#####`jetty_java_options`

JVM options for Jetty. Defaults to '-Xmx512m'.

#####`jetty_port`

The port Jetty will bind to. Defaults to '8983'.

#####`jetty_user`

The user running the Jetty Solr instance. Defaults to 'solr'.

#####`solr_home`

The Solr home used for the jvm setting -Dsolr.solr.home. Defaults to '/home/solr-4.6.0/example/solr'.

#####`solr_parent_dir`

The home directory of Solr. Defaults to '/home/solr-4.6.0'.

#####`url`

The download url for solr. Preferably a mirror. Defaults to 'http://archive.apache.org/dist/lucene/solr'.

#####`version`

The Apache Solr version. Defaults to '4.6.0'.

####Class: Iqss::Tworavens

This class installs the Apache RApache handler and the Tworavens web application. For example:

    class {
      'iqss::tworavens':
        tworavens_package => 'https://github.com/IQSS/TwoRavens/archive/master.zip',
        parent_dir        => '/var/www/html',
    }
    
It also contains settings for
    
#####`domain`

The public domain name of the TwoRavens web application. Defaults to 'localhost'.  

#####`package`

The download url of TwoRavens. Defaults to 'https://github.com/IQSS/TwoRavens/archive/v0.1.zip'.

#####`parent_dir`

The installation directory of the TwoRavens web application. Defaults to '/var/www/html'. 

#####`port`

The port TwoRavens can be accessed on. Defaults to '9999'.

#####`protocol`

The protocol TwoRavens can be accessed on. Defaults to 'https'.

#####`rapache_version`

The rapache version to be installed. Defaults to '1.2.6'.

#####`tworavens_dataverse_fqdn`

The domain name of the dataverse web application this TwoRavens web application will connect to. Defaults to 'localhost'.

#####`tworavens_dataverse_port`

The port of the dataverse web application. Defaults to '9999'.

#####`dataverse_site_url`

The url to a dataverse web application. Defaults to 'https://`dataverse_fqdn`:9999'.

Hieradata
---------

This example shows how all default settings can be set with a hieradata document. Note that you can also
inject values like the R packages or package_repo:

```javascript
{
    "iqss::database::createdb": false,
    "iqss::database::createrole": false,
    "iqss::database::encoding": "UTF-8",
    "iqss::database::listen_addresses": "*",
    "iqss::database::locale": "en_US.UTF-8",
    "iqss::database::login": true,
    "iqss::database::manage_package_repo": true,
    "iqss::database::hba_rule": {
        "IPv4 local connections": {
            "description": "Open up a IP4 connection from localhost",
            "type": "host",
            "database": "dvndb",
            "user": "dvnApp",
            "address": "127.0.0.1/32",
            "auth_method": "md5"
        },
        "IPv6 local connections": {
            "description": "Open up a IP6 connection from localhost",
            "type": "host",
            "database": "dvndb",
            "user": "dvnApp",
            "address": "::1/128",
            "auth_method": "md5"
        }
    },
    "iqss::database::superuser": false,
    "iqss::database::version": "9.3",
    "iqss::dataverse::glassfish_domain_name": "domain1",
    "iqss::dataverse::glassfish_parent_dir": "/home/glassfish",
    "iqss::dataverse::glassfish_service_name": "dataverse",
    "iqss::dataverse::glassfish_tmp_dir": "/opt/glassfish",
    "iqss::dataverse::glassfish_user": "glassfish",
    "iqss::dataverse::glassfish_version": "4.1",
    "iqss::dataverse::repository": "local",
    "iqss::dataverse::repository_custom": "https://bamboo.socialhistoryservices.org/browse/DATAVERSE-TEST/latestSuccessful/artifact/JOB1/4.0.1/dataverse-4.0.1.war",
    "iqss::dataverse::trigger": "*/3",
    "iqss::dataverse::dataverse_site_url": "https://localhost:9999",
    "iqss::dataverse::dataverse_files_directory": "/home/glassfish/dataverse/files",
    "iqss::dataverse::dataverse_rserve_host": "localhost",
    "iqss::dataverse::dataverse_rserve_port": "6311",
    "iqss::dataverse::dataverse_rserve_user": "rserve",
    "iqss::dataverse::dataverse_rserve_password": "rserve",
    "iqss::dataverse::dataverse_auth_password_reset_timeout_in_minutes": "60",
    "iqss::dataverse::doi_username": "apitest",
    "iqss::dataverse::doi_password": "apitest",
    "iqss::dataverse::doi_baseurlstring": "https\://ezid.cdlib.org",
    "iqss::dataverse::glassfish_fromaddress": "do-not-reply@localhost",
    "iqss::dataverse::glassfish_jvmoption": [
        "-XX\:MaxPermSize=512m",
        "-XX\:PermSize=256m",
        "-Xmx1024m",
        "-Djavax.xml.parsers.SAXParserFactory=com.sun.org.apache.xerces.internal.jaxp.SAXParserFactoryImpl"
    ],
    "iqss::dataverse::glassfish_mailhost": "localhost",
    "iqss::dataverse::glassfish_mailuser": "dataversenotify",
    "iqss::dataverse::glassfish_mailproperties": "username=a_username:password=a_password",
    "iqss::globals::apache2_purge_configs": true,
    "iqss::globals::database_host": "localhost",
    "iqss::globals::dataverse_fqdn": "localhost",
    "iqss::globals::dataverse_port": "9999",
    "iqss::globals::database_port": 5432,
    "iqss::globals::database_name": "dvndb",
    "iqss::globals::database_user": "dvnApp",
    "iqss::globals::database_password": "dvnAppPass",
    "iqss::rserve::packages_r": [ "devtools", "DescTools", "R2HTML", "Rserve", "VGAM", "AER", "dplyr", "quantreg", "geepack", "maxLik", "Amelia", "Rook", "jsonlite", "rjson"],
    "iqss::rserve::packages_zelig": "https://github.com/IQSS/Zelig/archive/master.zip",
    "iqss::rserve::user": "rserve",
    "iqss::rserve::package_repo": "http://cran.r-project.org",
    "iqss::solr::url": "http://archive.apache.org/dist/lucene/solr",
    "iqss::solr::version": "4.6.0",
    "iqss::solr::solr_parent_dir": "/home/solr-4.6.0",
    "iqss::solr::jetty_user": "solr",
    "iqss::solr::jetty_host": "localhost",
    "iqss::solr::jetty_port": "8983",
    "iqss::solr::jetty_java_options": "-Xmx512m",
    "iqss::solr::jetty_home": "/home/solr-4.6.0/example",
    "iqss::solr::solr_home": "/home/solr-4.6.0/example/solr",
    "iqss::solr::core": "collection1",
    "iqss::tworavens::rapache_version": "1.2.6",
    "iqss::tworavens::package": "https://github.com/IQSS/TwoRavens/archive/v0.1.zip",
    "iqss::tworavens::parent_dir": "/var/www/html",
    "iqss::tworavens::domain": "localhost",
    "iqss::tworavens::tworavens_dataverse_port": "9999",
    "iqss::tworavens::port": "9999",
    "iqss::tworavens::protocol": "https"
}
``` 

Known issues
------------

* The Rserve service does not automatically start when it is installed for the first time.
* When installing TwoRavens for the first time, apache does not restart and read in the configuration.

To do
-----

* Discuss how to move on from here: a dataverse installation module on https://forge.puppetlabs.com/ so developers and IT administrators can setup their DTAP environment ?
* Test with Centos 7 ?
* Shibboleth
* Maintainers and contributors ?
