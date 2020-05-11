require 'rails_helper'

RSpec.describe CaseInformationHelper do
  describe 'delius_email_message' do
    email_messages = [
      [DeliusImportError::DUPLICATE_NOMIS_ID, 'There’s more than one nDelius record with this NOMIS number.'],
      [DeliusImportError::INVALID_TIER, 'There’s no tier recorded in nDelius. You may need to contact the sentencing court.'],
      [DeliusImportError::INVALID_CASE_ALLOCATION, 'There’s no service provider in nDelius. You may need to contact the sentencing court.'],
      [DeliusImportError::MISMATCHED_DOB, 'There’s an nDelius record with this NOMIS number but a different date of birth.']
    ]

    it 'returns the correct message correlating to the DeliusImportError' do
      email_messages.each do |msg|
        expect(delius_email_message(msg.first)).to eq(msg.last)
      end
    end
  end

  describe 'delius_error_display' do
    error_messages = [
      [DeliusImportError::DUPLICATE_NOMIS_ID,
       'More than one nDelius record found with this prisoner number. You need to update nDelius so there is only '\
       'one record before you can allocate.'
      ],
      [DeliusImportError::INVALID_TIER,
       'nDelius record with matching prisoner number but no tiering calculation found. You need to update nDelius '\
       'with the tiering calculation before you can allocate.'
      ],
      [DeliusImportError::INVALID_CASE_ALLOCATION,
       'nDelius record with matching prisoner number but no service provider information found. You need to update '\
       'nDelius with the service provider before you can allocate.'
      ],
      [DeliusImportError::MISSING_DELIUS_RECORD,
       'No nDelius record found with this prisoner number. This may be because the case information has not yet '\
       'been updated. This prisoner needs to be matched with an nDelius record before you can allocate.'
      ],
      [DeliusImportError::MISSING_LDU,
       'nDelius record with matching prisoner number but no local divisional unit (LDU) information found. You need '\
       'to update nDelius with the LDU before you can allocate.'
      ],
      [DeliusImportError::MISSING_TEAM,
       'nDelius record found with matching prisoner number but no community team information found. You need to '\
       'update nDelius with the team information before you can allocate.'
      ],
      [DeliusImportError::MISMATCHED_DOB,
       'nDelius record found with matching prisoner number but a different date of birth. You need to check the '\
       'data in nDelius and correct before you can allocate.'
      ]
    ]

    it 'returns the error message based on DeliusImportError type' do
      error_messages.each do |msg|
        expect(delius_error_display(msg.first)).to eq(msg.last)
      end
    end
  end

  describe 'flash_notice_text' do
    let(:prisoner) { OpenStruct.new(offender_no: "Z0000AA", full_name: 'PrisonerA') }

    it 'returns the flash notification based on DeliusImportError type' do
      notice_msgs = [
        [DeliusImportError::DUPLICATE_NOMIS_ID,
         "There’s more than one nDelius record with this NOMIS number #{prisoner.offender_no} for "\
                "#{prisoner.full_name}. The community probation team need to update nDelius."
        ],
        [DeliusImportError::MISSING_DELIUS_RECORD,
         "There’s no nDelius match for #{prisoner.full_name}, NOMIS number #{prisoner.offender_no}. The community "\
                'probation team need to update nDelius.'
        ],
        [DeliusImportError::INVALID_TIER,
         "There’s no tier recorded in nDelius for #{prisoner.full_name}, NOMIS number #{prisoner.offender_no}. "\
                'The community probation team need to update nDelius.'
        ],
        [DeliusImportError::INVALID_CASE_ALLOCATION,
         "There’s no service provider in nDelius for #{prisoner.full_name}, NOMIS number #{prisoner.offender_no}. "\
                'The community probation team need to update nDelius.'
        ],
        [DeliusImportError::MISMATCHED_DOB,
         "There’s an nDelius record with NOMIS number #{prisoner.offender_no} - #{prisoner.full_name} but a "\
                'different date of birth. The community probation team need to update nDelius.'
        ],
        [DeliusImportError::MISSING_TEAM,
         "#{prisoner.full_name}, NOMIS number #{prisoner.offender_no} must be linked to an nDelius record for "\
                'handover to the community. The community probation team need to update nDelius.'
        ]
      ]

      notice_msgs.each do |msg|
        email_range = [1, 2]
        size = email_range.sample(1)
        expect(flash_notice_text(error_type: msg.first, prisoner: prisoner, email_count: size.first)).to eq(msg.last + " Automatic email sent.")
      end

      notice_msgs.each do |msg|
        size = 0
        expect(flash_notice_text(error_type: msg.first, prisoner: prisoner, email_count: size)).to eq(msg.last)
      end
    end
  end

  describe 'flash_alert_text' do
    let(:spo) { 'spo' }
    let(:team_name) { 'Portway Team' }
    let(:ldu) {
      create(:local_divisional_unit, name: 'Manchester LDU', email_address: 'manchester-ldu@justice.gov.uk')
    }

    it 'returns flash alert when SPO does not have an email address' do
      spo = nil

      expect(flash_alert_text(spo: spo, ldu: ldu, team_name: team_name)).
      to eq('We could not send you an email because there is no valid email address saved to your account. '\
             'You need to contact the local system administrator in your prison to update your email address.')
    end

    it 'returns flash alert when LDU does not have an email address' do
      ldu.email_address = nil

      expect(flash_alert_text(spo: spo, ldu: ldu, team_name: team_name)).
      to eq("An email could not be sent to the community probation team - #{ldu.name} because there is no "\
             'email address saved. You need to find an alternative way to contact them. ')
    end

    it 'returns flash alert when there is no LDU' do
      ldu = nil

      expect(flash_alert_text(spo: spo, ldu: ldu, team_name: team_name)).
      to eq("An email could not be sent to the LDU for #{team_name} because there is no LDU assigned to the team. ")
    end
  end

  describe 'spo_message' do
    let(:ldu) {
      create(:local_divisional_unit, name: 'Manchester LDU', email_address: 'manchester-ldu@justice.gov.uk')
    }

    it 'return message to be sent to SPO when there is no LDU email address' do
      ldu.email_address = ''

      expect(spo_message(ldu)).to eq("We were unable to send an email to #{ldu.name} as we do not have their "\
      'email address. You need to find another way to provide them with this information.')
    end

    it 'returns message to be sent to SPO  when there is a LDU email address' do
      expect(spo_message(ldu)).to eq('This is a copy of the email sent to the LDU for your records')
    end
  end
end
