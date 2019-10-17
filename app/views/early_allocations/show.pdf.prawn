# frozen_string_literal: true

def document_header(pdf, outcome)
  pdf.move_down 20
  pdf.text 'Early allocation assessment', size: 30, style: :bold

  pdf.move_down 30
  pdf.table([['Assessment outcome',  outcome]], column_widths: column_widths, cell_style: { padding: 15, border_width: 2}) do
    column(0).style(borders: [:left, :top, :bottom], font_style: :bold)
    column(1).style(borders: [:right, :top, :bottom])
  end
end

def column_widths
  { 0 => 260, 1 => 260 }.freeze
end

def pdf_table(pdf, title, data)
  pdf.move_down 20
  pdf.text title, size: 20, style: :bold
  pdf.move_down 10
  pdf.table data, column_widths: column_widths, cell_style: { borders: [:bottom], padding: [10, 0, 10, 0] } do
    column(0).style(font_style: :bold)
  end
end

prawn_document do |pdf|
  pdf.font_families.update('GDSTransport' => {
    normal: Rails.root.join('app', 'assets', 'fonts', 'GDSTransportWebsite.ttf'),
    bold: Rails.root.join('app', 'assets', 'fonts', 'GDSTransportWebsite-Bold.ttf')
  } )
  pdf.font 'GDSTransport'

  outcome = if @offender.eligible?
              'Eligible'
            elsif @offender.ineligible?
              'Not eligible'
            else
              'Community decision required'
            end

  document_header(pdf, outcome)

  prisoner_info = [
    ['Prisoner name', @prisoner.full_name],
    ['Prisoner number', @prisoner.offender_no],
    ['CRN number', @prisoner.crn],
    ['Handover start date', format_date(@prisoner.handover_start_date.first)],
    ['Responsibility handover', format_date(@prisoner.responsibility_handover_date.first)]
  ]

  pdf_table pdf, 'Prisoner information', prisoner_info

  offence_info = [
    ['Main offence', @prisoner.main_offence],
    ['Sentence type', sentence_type_label(@prisoner)],
    ['Release date', format_date(@prisoner.release_date)]
  ]

  pdf_table pdf, 'Offence', offence_info

  prison_info = [
    ['Prison', PrisonService.name_for(@prisoner.prison_id)],
    ['POM Name', @allocation.primary_pom_name],
    ['POM email', @pom.emails.first]
  ]

  pdf_table pdf, 'Prison Information', prison_info

  pdf.start_new_page

  document_header(pdf, outcome)

  assessment_info = [
    ['Assessment date', format_date(@offender.updated_at)],
    ['Date of last OASys risk assessment', format_date(@offender.oasys_risk_assessment_date)],
    ['Convicted under Terrorism Act 2000', humanized_bool(@offender.convicted_under_terrorisom_act_2000)],
    ['Identified as \'High Profile\'', humanized_bool(@offender.high_profile)],
    ['Has Serious Crime Prevention Order', humanized_bool(@offender.serious_crime_prevention_order)],
    ['Requires management as a Multi-Agency Public Protection (MAPPA) level 3', humanized_bool(@offender.mappa_level_3)],
    ['Likely to be a Critical Public Protection Case', humanized_bool(@offender.cppc_case)]
  ]

  # With booleans, #nil? is not the opposite of #present?
  unless @offender.extremism_separation.nil?
    yesno_text = humanized_bool(@offender.extremism_separation)
    has_been_held_text = 'Has been held in an extremism seperation centre'
    if @offender.extremism_separation?
      if @offender.due_for_release_in_less_than_24months?
        assessment_info.append [has_been_held_text, "#{yesno_text} - due for release in less than 24 months"]
      else
        assessment_info.append [has_been_held_text, "#{yesno_text} - not due for release until more than 24 months"]
      end
    else
      assessment_info.append [has_been_held_text, yesno_text]
    end
  end
  unless @offender.high_risk_of_serious_harm.nil?
    assessment_info.append ['Presents a very high risk of serious harm', humanized_bool(@offender.high_risk_of_serious_harm)]
  end
  unless @offender.mappa_level_2.nil?
    assessment_info.append ['Requires management as a Multi-Agency Public Protection (MAPPA) level 2',humanized_bool(@offender.mappa_level_2)]
  end
  unless @offender.pathfinder_process.nil?
    assessment_info.append ['Identified through the \'pathfinder\' process', humanized_bool(@offender.pathfinder_process)]
  end
  unless @offender.other_reason.nil?
    assessment_info.append ['Other reason for consideration for early allocation to the probation team', humanized_bool(@offender.other_reason)]
  end

  pdf_table pdf, 'Early Allocation Assessment', assessment_info

  # 3rd page - only used for discretionary cases
  if @offender.discretionary?
    pdf.start_new_page

    document_header(pdf, outcome)

    extra_detail = [
      ['Detail about why this case needs to be referred early', @offender.reason],
      ['Approval from the Head of Offender Management Delivery', humanized_bool(@offender.approved)]
    ]

    pdf_table pdf, 'Early Allocation Assessment (cont)', extra_detail
  end
end
