class TestOnlyMailer < ApplicationMailer
  def test_mail
    set_personalisation(params[:personalisation])
    set_template(params[:template])
    mail(to: params[:to])
  end
end
