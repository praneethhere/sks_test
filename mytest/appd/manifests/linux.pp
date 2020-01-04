##
# Document:
##

class appd_agent::linux (
  $app_name              = $appd_agent::app_name,
  $tier_name             = $appd_agent::tier_name,
  $controller_host       = $appd_agent::controller_host,
  $controller_port       = $appd_agent::controller_port,
  $controller_ssl_enabled = $appd_agent::controller_ssl_enabled,
  $account_name          = $appd_agent::account_name,
  $account_acces_key      = $appd_agent::account_acces_key,
  $sim_enabled           = $appd_agent::sim_enabled,
  $orchestration_enabledd = $appd_agent::orchestration_enabledd,
  $app_install_binary     = $appd_agent::app_install_binary,
  $machine_install_binary = $appd_agent::machine_install_binary,
  $base_appd_dir          = $appd_agent::base_appd_dir,
  $app_install_dir        = $appd_agent::app_install_dir,
  $app_agent_owner        = $appd_agent::app_agent_owner,
  $app_agent_group        = $appd_agent::app_agent_group,
  $machine_install_dir    = $appd_agent::machine_install_dir,
  $machine_agent_owner    = $appd_agent::machine_agent_owner,
  $machine_agent_group    = $appd_agent::machine_agent_group
) {

  ## Create recurse $base_appd_dir
  exec { "Create ${base_appd_dir}":
    creates => $base_appd_dir,
    command => "mkdir -p ${base_appd_dir}",
    path    => $::path
  } -> file { $base_appd_dir:  }

  ## Install App Agent 
  $app_controller_info_file = "${app_install_dir}/conf/controller-info.xml"
  # Create Dir 
  file {$app_install_dir:
  ensure => directory,
  owner  => $app_agent_owner,
  group  => $app_agent_group
  }

  # Extract Binary  
  archive { $app_install_dir:
    path         => "${app_install_dir}/${app_install_binary}",
    source       => "puppet:///modules/${module_name}/${app_install_binary}",
    extract      => true,
    extract_path => $app_install_dir,
    user         => $app_agent_owner,
    group        => $app_agent_group,
    cleanup      => true,
    creates      => $app_controller_info_file,
    require      => File[$app_install_dir]
  }

  # Set controller config file 
  file { $app_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/app_agent_controller-info.xml.epp",
      {
        'controller_host'        => $controller_host,
        'account_name'           => $account_name,
        'account_access_key'     => $account_acces_key,
        'controller_port'        => $controller_port,
        'controller_ssl_enabled' => $controller_ssl_enabled,
        'orchestration_enabled'  => $orchestration_enabledd,
        'tier_name'              => $tier_name,
        'application_name'       => $app_name,
        'node_name'              => $facts['hostname']
      }
    ),
    require => Archive[$app_install_dir]
  }

  #### Machine Agent 
  $machine_controller_info_file = "${machine_install_dir}/conf/controller-info.xml"
  $machine_agent_sysconfig_file = '/etc/sysconfig/appdynamics-machine-agent'

  # Create Dir 
  file {$machine_install_dir:
    ensure => directory,
    owner  => $machine_agent_owner,
    group  => $machine_agent_group
  }

  # Extract Binary  
  archive { $machine_install_dir:
    path         => "${machine_install_dir}/${machine_install_binary}",
    source       => "puppet:///modules/${module_name}/${machine_install_binary}",
    extract      => true,
    extract_path => $machine_install_dir,
    user         => $machine_agent_owner,
    group        => $machine_agent_group,
    cleanup      => true,
    creates      => $machine_controller_info_file,
    require      => File[$machine_install_dir]
  }

  # Set controller config file 
  file { $machine_controller_info_file:
    ensure  => 'file',
    content => epp("${module_name}/machine_agent_controller-info.xml.epp",
      {
        'controller_host'        => $controller_host,
        'account_name'           => $account_name,
        'account_access_key'     => $account_acces_key,
        'controller_port'        => $controller_port,
        'controller_ssl_enabled' => $controller_ssl_enabled,
        'orchestration_enabled'  => $orchestration_enabledd,
        'sim_enabled'            => $sim_enabled,
      }
    ),
    require => Archive[$machine_install_dir],
  }

  # Setup machine-agent sysconfig file 
  file { $machine_agent_sysconfig_file:
    ensure  => 'file',
    content => epp("${module_name}/machine_agent_sysconfig.epp",
      {
        'machine_agent_install_dir' => $machine_install_dir,
        'machine_agent_owner'       => $machine_agent_owner,
        'machine_agent_group'       => $machine_agent_group
      }
    ),
    require => Archive[$machine_install_dir],
  }

  # Machine Agent daemon service file
  File { '/etc/init.d/appdynamics-machine-agent':
    source  => "${machine_install_dir}/etc/init.d/appdynamics-machine-agent",
    mode    => '0755',
    require => File['/etc/sysconfig/appdynamics-machine-agent']
  }

  # Start Enable service 
  service { 'appdynamics-machine-agent':
    ensure  => running,
    enable  => true,
    #provider   => 'init',
    require => File['/etc/init.d/appdynamics-machine-agent']
  }

} ## END CLASS
