class allowgroups (
	$config_path                      = $allowgroups::params::config_path,
	$group_name                       = $allowgroups::params::group_name,
	$ensure                           = $allowgroups::params::ensure,
	) inherits allowgroups::params {
#Validate that $group_name is defined as array
	if $group_name                    == undef {
		fail('group_name undefined')
	}
	elsif ! is_array($group_name) {
		fail('group_name most be an array')
	}

#Manage sshd service
	service { 'sshd':
		ensure                        => running,
		enable                        => true,
	}

#Add or remove group name using sed command
	case $ensure {
		'present': {
			$group_name.each |String $group_name| {
				file_line { "ensure AllowGroups is present $group_name":
					ensure            => present,
					path              => $config_path,
					line              => 'AllowGroups',
					match             => "^AllowGroups",
					replace           => false,
				}
				exec { "sed add group $group_name":
					command           => "sed -i '/^AllowGroups/ s/$/ $group_name/' $config_path",
					path              => '/bin:/usr/bin',
					unless            => "grep -q $group_name $config_path",
					notify            => Service['sshd'],
				}
			}
		}
		'absent': {
			$group_name.each |String $group_name| {
				exec { "sed remove group $group_name":
					command           => "sed -i 's/$group_name//g' $config_path",
					path              => '/bin:/usr/bin',
					onlyif            => "grep -q $group_name $config_path",
					notify            => Service['sshd'],
				}
				file_line { "remove AllowGroups if value is empty $group_name":
					ensure            => absent,
					path              => $config_path,
					line              => 'AllowGroups',
					match             => '^AllowGroups\s+$',
					match_for_absence => true,
					replace           => false,
					notify            => Service['sshd'],
				}
			}
		}
#fail if $ensure value is different than present or absent
		default: {
			fail("Syntax error, $ensure is not an expected value for ensure")
		}
	}
}
