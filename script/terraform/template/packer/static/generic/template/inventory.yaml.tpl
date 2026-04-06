all:
  children:
    worker:
      hosts:
%{ for i in range(length(hosts)) ~}
        worker-${i}:
          ansible_host: "${hosts[i]}"
          ansible_port: "${ports[i]}"
          ansible_user: "${users[i]}"
          ansible_connection: "${connections[i]}"
          ansible_private_key_file: "${private_key_file}"
          ansible_ssh_private_key_file: "${private_key_file}"
          private_ip: "${private_ips[i]}"
%{ endfor ~}
