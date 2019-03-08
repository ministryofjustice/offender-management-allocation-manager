class UserService
  def self.get_user_details(username)
    user = Nomis::Custody::UserApi.user_details(username)
    user.emails = Nomis::Elite2::UserApi.fetch_email_addresses(user.staff_id)
    user
  end
end
