#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
####################################################
# Inspects specified image and gets parents.
#
# Inputs:
#   - docker_host - Docker machine host
#   - docker_username - Docker machine username
#   - docker_password - Docker machine password
#   - image_ID - image for which to check parents
#   - private_key_file - optional - path to the private key file - Default: none
#   - timeout - optional - time in milliseconds to wait for the command to complete
# Outputs:
#   - parents - parents of the specified containers
####################################################
namespace: io.cloudslang.docker.images

imports:
 docker_images: io.cloudslang.docker.images
 docker_utils: io.cloudslang.docker.utils
 base_os_linux: io.cloudslang.base.os.linux

flow:
  name: get_image_parents
  inputs:
    - docker_host
    - docker_username
    - docker_password
    - image_name
    - private_key_file:
        default: "''"
    - timeout:
        required: false
  workflow:
    - validate_linux_machine_ssh_access:
        do:
          base_os_linux.validate_linux_machine_ssh_access:
            - host: docker_host
            - username: docker_username
            - password: docker_password
            - privateKeyFile: private_key_file
            - timeout:
                required: false
    - inspect_image:
        do:
          docker_images.inspect_image:
            - host: docker_host
            - username: docker_username
            - password: docker_password
            - imageName: image_name
            - privateKeyFile: private_key_file
            - timeout:
                required: false
        publish:
          - standard_out
          - standard_err
    - get_parents:
        do:
           docker_utils.parse_inspect_for_parents:
             - json_response: standard_out
        publish:
          - parent_images
    - get_parents_name:
        do:
           docker_images.get_image_name_from_id:
             - host: docker_host
             - username: docker_username
             - password: docker_password
             - privateKeyFile: private_key_file
             - timeout:
                 required: false
             - image_id: parent_images[:10]
        publish:
          - image_name
  outputs:
    - parent_images_list: image_name
