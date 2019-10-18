# rubocop:disable Metrics/ModuleLength
module EarlyAssignmentPdfHelper
  def render_early_alloc_pdf(early_assignment:, offender:, allocation:, pom:)
    # prawn_document can only be called in an actual view context.
    Prawn::Document.new do |pdf|
      setup_font(pdf)

      add_document_header(pdf, early_assignment)
      add_prisoner_info(pdf, offender)
      add_offence_info(pdf, offender)
      add_prison_info(pdf, offender, allocation, pom)

      pdf.start_new_page
      add_document_header(pdf, early_assignment)
      add_assessment_info(pdf, early_assignment)

      # 3rd page - only used for discretionary cases
      if early_assignment.discretionary?
        pdf.start_new_page
        add_document_header(pdf, early_assignment)

        extra_detail = [
          ['Detail about why this case needs to be referred early', early_assignment.reason],
          ['Approval from the Head of Offender Management Delivery', humanized_bool(early_assignment.approved)]
        ]

        pdf_table pdf, 'Early Allocation Assessment (cont)', extra_detail
      end
    end
  end

private

  DESCRIPTIONS = {
    updated_at: 'Assessment date',
    oasys_risk_assessment_date: 'Date of last OASys risk assessment',
    convicted_under_terrorisom_act_2000: 'Convicted under Terrorism Act 2000',
    high_profile: 'Identified as \'High Profile\'',
    serious_crime_prevention_order: 'Has Serious Crime Prevention Order',
    mappa_level_3: 'Requires management as a Multi-Agency Public Protection (MAPPA) level 3',
    cppc_case: 'Likely to be a Critical Public Protection Case',
    extremism_separation: 'Has been held in an extremism separation centre',
    high_risk_of_serious_harm: 'Presents a very high risk of serious harm',
    mappa_level_2: 'Requires management as a Multi-Agency Public Protection (MAPPA) level 2',
    pathfinder_process: 'Identified through the \'pathfinder\' process',
    other_reason: 'Other reason for consideration for early allocation to the probation team'
  }

  def add_assessment_info(pdf, early_assignment)
    info_hash = {}
    [:updated_at, :oasys_risk_assessment_date].each do |field|
      info_hash[field] = format_date(early_assignment.public_send(field))
    end
    [:convicted_under_terrorisom_act_2000, :high_profile, :serious_crime_prevention_order,
     :mappa_level_3, :cppc_case].each do |field|
      info_hash[field] = humanized_bool(early_assignment.public_send(field))
    end

    # With booleans, #nil? is not the opposite of #present?
    unless early_assignment.extremism_separation.nil?
      info_hash[:extremism_separation] = extremism_text_for(early_assignment)
    end

    [:high_risk_of_serious_harm, :mappa_level_2, :pathfinder_process, :other_reason].each do |field|
      value = early_assignment.public_send(field)
      unless value.nil?
        info_hash[field] = humanized_bool(field)
      end
    end

    assessment_info = info_hash.map { |k, v| [DESCRIPTIONS[k], v] }

    pdf_table pdf, 'Early Allocation Assessment', assessment_info
  end

  def extremism_text_for(early_assignment)
    yesno_text = humanized_bool(early_assignment.extremism_separation)
    if early_assignment.extremism_separation?
      if early_assignment.due_for_release_in_less_than_24months?
        "#{yesno_text} - due for release in less than 24 months"
      else
        "#{yesno_text} - not due for release until more than 24 months"
      end
    else
      yesno_text
    end
  end

  def add_prison_info(pdf, offender, allocation, pom)
    prison_info = [
      ['Prison', PrisonService.name_for(offender.prison_id)],
      ['POM Name', allocation.primary_pom_name],
      ['POM email', pom.emails.first]
    ]

    pdf_table pdf, 'Prison Information', prison_info
  end

  def add_offence_info(pdf, offender)
    offence_info = [
      ['Main offence', offender.main_offence],
      ['Sentence type', sentence_type_label(offender)],
      ['Release date', format_date(offender.release_date)]
    ]

    pdf_table pdf, 'Offence', offence_info
  end

  def add_prisoner_info(pdf, offender)
    prisoner_info = [
      ['Prisoner name', offender.full_name],
      ['Prisoner number', offender.offender_no],
      ['CRN number', offender.crn],
      ['Handover start date', format_date(offender.handover_start_date.first)],
      ['Responsibility handover', format_date(offender.responsibility_handover_date.first)]
    ]

    pdf_table pdf, 'Prisoner information', prisoner_info
  end

  def setup_font(pdf)
    pdf.font_families.update('GDSTransport' => {
                               normal: Rails.root.join('app', 'assets', 'fonts', 'GDSTransportWebsite.ttf'),
                               bold: Rails.root.join('app', 'assets', 'fonts', 'GDSTransportWebsite-Bold.ttf')
                             })
    pdf.font 'GDSTransport'
  end

  def add_document_header(pdf, early_allocation)
    pdf.move_down 20
    pdf.text 'Early allocation assessment', size: 30, style: :bold

    pdf.move_down 30
    pdf.table([['Assessment outcome',  early_allocation_status(early_allocation)]],
              column_widths: column_widths,
              cell_style: { padding: 15, border_width: 2 }) do
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
end
# rubocop:enable Metrics/ModuleLength
