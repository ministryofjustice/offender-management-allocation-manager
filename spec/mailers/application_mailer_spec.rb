RSpec.describe ApplicationMailer do
  describe 'when setting tags' do
    it 'uses default tags based on mailer name' do
      TestOnlyMailer.set_mailer_tag nil
      mail = TestOnlyMailer.with(template: 'x', personalisation: {}).test_mail
      expect(mail.govuk_notify_reference).to eq ['email', 'test_only', 'test_mail']
    end

    it 'allows mailer name tag to be configured' do
      TestOnlyMailer.set_mailer_tag 'only_for_testing'
      mail = TestOnlyMailer.with(template: 'x', personalisation: {}).test_mail
      expect(mail.govuk_notify_reference).to eq ['email', 'only_for_testing', 'test_mail']
    end
  end
end
