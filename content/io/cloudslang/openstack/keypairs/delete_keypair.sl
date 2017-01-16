#   (c) Copyright 2014-2016 Hewlett-Packard Enterprise Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
########################################################################################################################
#!!
#! @description: Deletes an OpenStack keypair.
#!
#! @input host: OpenStack machine host
#! @input identity_port: optional - port used for OpenStack authentication
#!                       Default: '5000'
#! @input compute_port: optional - port used for OpenStack computations
#!                      Default: '8774'
#! @input tenant_name: name of OpenStack project where keypair to be deleted is
#! @input keypair_name: name of keypair to be deleted
#! @input username: optional - username used for URL authentication; for NTLM authentication
#!                 Format: 'domain\user'
#! @input password: optional - password used for URL authentication
#! @input proxy_host: optional - proxy server used to access OpenStack services
#! @input proxy_port: optional - proxy server port used to access OpenStack services
#!                    Default: '8080'
#! @input proxy_username: optional - user name used when connecting to proxy
#! @input proxy_password: optional - proxy server password associated with <proxy_username> input value
#! @input trust_keystore: optional - the pathname of the Java TrustStore file.
#!                        This contains certificates from other parties
#!                        that you expect to communicate with, or from Certificate Authorities that you trust to
#!                        identify other parties.  If the protocol (specified by the 'url') is not 'https' or if
#!                        trustAllRoots is 'true' this input is ignored.
#!                        Default value: ..JAVA_HOME/java/lib/security/cacerts
#!                        Format: Java KeyStore (JKS)
#! @input trust_password: optional - the password associated with the TrustStore file.
#!                        If trust_all_roots is false and trustKeystore is empty,
#!                        trustPassword default will be supplied.
#!                        Default value: changeit
#! @input keystore: optional - the pathname of the Java KeyStore file.
#!                  You only need this if the server requires client authentication.
#!                  If the protocol (specified by the 'url') is not 'https' or if
#!                  trust_all_roots is 'true' this input is ignored.
#!                  Default value: ..JAVA_HOME/java/lib/security/cacerts
#!                  Format: Java KeyStore (JKS)
#! @input keystore_password: optional - the password associated with the KeyStore file.
#!                           If trustAllRoots is false and keystore
#!                           is empty, keystorePassword default will be supplied.
#!                           Default value: ''
#!
#! @output return_result: response of operation in case of success, error message otherwise
#! @output error_message: return_result if status_code is not '202'
#! @output return_code: '0' if success, '-1' otherwise
#! @output status_code: code returned by operation
#!
#! @result SUCCESS: keypair was successfully deleted
#! @result GET_AUTHENTICATION_TOKEN_FAILURE: authentication token cannot be obtained from authentication call response
#! @result GET_TENANT_ID_FAILURE: tenant_id corresponding to tenant_name cannot be obtained from authentication call response
#! @result GET_AUTHENTICATION_FAILURE: authentication call fails
#! @result DELETE_KEYPAIR_FAILURE: keypair could not be deleted
#!!#
########################################################################################################################

namespace: io.cloudslang.openstack.keypairs

imports:
  openstack: io.cloudslang.openstack
  rest: io.cloudslang.base.http

flow:
  name: delete_keypair

  inputs:
    - host
    - identity_port: '5000'
    - compute_port: '8774'
    - tenant_name
    - keypair_name
    - username:
        required: false
    - password:
        required: false
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true
    - trust_keystore:
        default: ${get_sp('io.cloudslang.openstack.trust_keystore')}
        required: false
    - trust_password:
        default: ${get_sp('io.cloudslang.openstack.trust_password')}
        required: false
        sensitive: true
    - keystore:
        default: ${get_sp('io.cloudslang.openstack.keystore')}
        required: false
    - keystore_password:
        default: ${get_sp('io.cloudslang.openstack.keystore_password')}
        required: false
        sensitive: true

  workflow:
    - authentication:
        do:
          openstack.get_authentication_flow:
            - host
            - identity_port
            - tenant_name
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
        publish:
          - token
          - tenant_id
          - return_result
          - error_message
        navigate:
          - SUCCESS: delete_keypair
          - GET_AUTHENTICATION_TOKEN_FAILURE: GET_AUTHENTICATION_TOKEN_FAILURE
          - GET_TENANT_ID_FAILURE: GET_TENANT_ID_FAILURE
          - GET_AUTHENTICATION_FAILURE: GET_AUTHENTICATION_FAILURE

    - delete_keypair:
        do:
          rest.http_client_delete:
            - url: ${'http://'+ host + ':' + compute_port + '/v2/' + tenant_id + '/os-keypairs/' + keypair_name}
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - trust_all_roots: "false"
            - x_509_hostname_verifier: "strict"
            - trust_keystore
            - trust_password
            - keystore
            - keystore_password
            - headers: ${'X-AUTH-TOKEN:' + token}
            - content_type: 'application/json'
        publish:
          - return_result
          - error_message
          - return_code
          - status_code
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: DELETE_KEYPAIR_FAILURE

  outputs:
    - return_result
    - error_message
    - return_code
    - status_code

  results:
    - SUCCESS
    - GET_AUTHENTICATION_TOKEN_FAILURE
    - GET_TENANT_ID_FAILURE
    - GET_AUTHENTICATION_FAILURE
    - DELETE_KEYPAIR_FAILURE
