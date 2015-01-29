 # Copyright (c) 2013 EVO Payments International - All Rights Reserved.
 #
 # This software and documentation is subject to and made
 # available only pursuant to the terms of an executed license
 # agreement, and may be used only in accordance with the terms
 # of said agreement. This software may not, in whole or in part,
 # be copied, photocopied, reproduced, translated, or reduced to
 # any electronic medium or machine-readable form without
 # prior consent, in writing, from EVO Payments International
 #
 # Use, duplication or disclosure by the U.S. Government is subject
 # to restrictions set forth in an executed license agreement
 # and in subparagraph (c)(1) of the Commercial Computer
 # Software-Restricted Rights Clause at FAR 52.227-19 subparagraph
 # (c)(1)(ii) of the Rights in Technical Data and Computer Software
 # clause at DFARS 252.227-7013, subparagraph (d) of the Commercial
 # Computer Software--Licensing clause at NASA FAR supplement
 # 16-52.227-86 or their equivalent.
 #
 # Information in this software is subject to change without notice
 # and does not represent a commitment on the part of EVO Payments International.
 #
 # Sample Code is for reference Only and is intended to be used for educational purposes. It"s the responsibility of
 # the software company to properly integrate into thier solution code that best meets thier production needs.

require 'json'

module Workflows
  def self.HostCapture(client)
    client.do_log = true

    # Get service information to see the avilable functions.
    service_response = EvoCWS_endpoint_svcinfo.get_service_info(client)
    p service_response.data
    test_assert(service_response.data['Success'], client)

    pindebit_auth_template = {
      'Transaction' => {
        'TenderData' => {
          'CardData' => {
            'CardType' => Evo::TypeCardType::MasterCard,
            'CardholderName' => nil,
            'PAN' => '5454545454545454',
            'Expire' => '1215',
            'Track2Data' => '5454545454545454=15121010134988000010',
          },
          'CardSecurityData' => {
            'KeySerialNumber' => '12345678',
            'PIN' => '1234'
          },
        },
        'TransactionData' => {
          'AccountType'=> Evo::AccountType::CheckingAccount,
          'EntryMode' => Evo::EntryMode::Keyed,
        }
      }
    }

    if service_response.data['BankcardServices'].length != 0
      serviceId_found = false
      workflowId_found = false

      service_response.data['BankcardServices'].each do |service|
        if service['ServiceId'] == client.service_id
					serviceId_found = true
        end
			end

      service_response.data['Workflows'].each do |workflow|
        if (workflow['WorkflowId'] == client.workflow_id)
					workflowId_found = true
        end
			end

      if serviceId_found || workflowId_found
        profiles_response = EvoCWS_endpoint_merchinfo.get_merchant_profiles(client, client.service_id)
        p profiles_response.data
        test_assert(profiles_response.data['Success'], client)
        merchId = ''
        parsed_response = JSON.parse(profiles_response.body)
        merchId = parsed_response[0]['id']

        profile = EvoCWS_endpoint_merchinfo.is_merchant_profile_initialized(client, client.merchant_profile_id, client.service_id)
        p profile.data
        test_assert(profile.data['Success'] == true, client)

        if RbConfig::UseWorkflow
          authorized_response = EvoCWS_endpoint_txn.authorize_encrypted(client, {})
        else
          authorized_response = EvoCWS_endpoint_txn.authorize(client, {})
        end

        p authorized_response.data
        test_assert(authorized_response.data['Success'] == true, client)
        test_assert(authorized_response.data['Status'] != 'Failure', client)

        captured_response = EvoCWS_endpoint_txn.capture(client, {
            'DifferenceData' => {
              '\type' => 'BankcardCapture,http://schemas.evosnap.com/CWS/v2.0/Transactions/Bankcard',
              'Amount' => '10.00',
              'TransactionId' => authorized_response.data['TransactionId'],
              'TipAmount' => '0.00'
            }
          })

        p captured_response.data

        if RbConfig::UseWorkflow
          captured_response = EvoCWS_endpoint_txn.authorize_and_capture_encrypted(client, {})
        else
          captured_response = EvoCWS_endpoint_txn.authorize_and_capture(client, {})
        end
          captured_response = EvoCWS_endpoint_txn.authorize_and_capture(client, {})
        p authorized_response.data

        test_assert(captured_response.data['Success'] == true, client)
        test_assert(captured_response.data['Status'] != 'Failure', client)

        response = EvoCWS_endpoint_txn.return_by_id(client, {
          'DifferenceData' => {
            'TransactionId' => captured_response.data['TransactionId']}})
        p response.data

        if RbConfig::UseWorkflow
          authorized_response = EvoCWS_endpoint_txn.authorize_encrypted(client, {})
        else
          authorized_response = EvoCWS_endpoint_txn.authorize(client, {})
        end

        p authorized_response.data
        test_assert(authorized_response.data['Success'] == true, client)
        test_assert(authorized_response.data['Status'] != 'Failure', client)

        response = EvoCWS_endpoint_txn.undo(client, {
          'DifferenceData' => {
            'TransactionId' => authorized_response.data['TransactionId']}})

        if RbConfig::UseWorkflow
          response = EvoCWS_endpoint_txn.return_unlinked_encrypted(client, {})
        else
          response = EvoCWS_endpoint_txn.return_unlinked(client, {})
        end
        response = EvoCWS_endpoint_txn.return_unlinked(client, {})
        p response.data

      end
    end
  end
end

