require 'rails_helper'

feature 'View a prisoner profile page' do
  let!(:alloc) {
    a = build(
      :allocation_version,
      nomis_offender_id: 'G7998GJ',
      primary_pom_nomis_id: '485637'
    )
    a.save(validate: false)
    a
  }

  it 'shows the prisoner information', :raven_intercept_exception, vcr: { cassette_name: :show_offender_spec } do
    signin_user
    visit prison_prisoner_show_path('LEI', 'G7998GJ')

    expect(page).to have_css('h2', text: 'Ahmonis, Okadonah')
    expect(page).to have_content('07/07/1968')
    cat_code = find('h3#category-code').text
    expect(cat_code).to eq('C')
  end

  it 'shows the prisoner image', :raven_intercept_exception, vcr: { cassette_name: :show_offender_spec_image } do
    signin_user

    visit prison_prisoner_image_path('LEI', 'G7998GJ')
    expect(page.response_headers['Content-Type']).to eq('image/jpg')
  end

  it "has a link to the allocation history",
     :raven_intercept_exception, vcr: { cassette_name: :link_to_allocation_history } do
    signin_user
    visit prison_prisoner_show_path('LEI', 'G7998GJ')
    click_link "View"
    expect(page).to have_content('Prisoner allocation')
  end
end
