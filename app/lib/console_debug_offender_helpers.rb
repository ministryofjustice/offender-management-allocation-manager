module ConsoleDebugOffenderHelpers
  def debug_offender(nomis_offender_id)
    offender = OffenderService.get_offender(nomis_offender_id)

    CalculatedHandoverDate.find_by(nomis_offender_id:)
    OffenderHandover.new(offender).as_calculated_handover_date
    sentences = Sentences.for(booking_id: offender.booking_id)
    parole_reviews = ParoleReview.where(nomis_offender_id:).order('updated_at DESC')

    $stdout.puts <<~TXT

      #{display_title 'General'}
      ISP / SD:                       #{offender.indeterminate_sentence? ? 'ISP' : 'SD'}
      Sentence start date:            #{display_date(offender.sentence_start_date)}
      Recall?                         #{display_tick_cross(offender.recalled?)}
      Early allocation?               #{display_tick_cross(offender.early_allocation?)}
      Determinate parole?             #{display_tick_cross(offender.determinate_parole?)}
      Open rules apply?               #{display_tick_cross(offender.open_prison_rules_apply?)}
      Womens?                         #{display_tick_cross(offender.in_womens_prison?)}
      Mappa level                     #{offender.mappa_level}

      #{display_title 'General / Dates'}
      ERD Earliest release date (FH): #{
        if offender.earliest_release_for_handover
          "#{display_date(offender.earliest_release_for_handover.date)} (#{offender.earliest_release_for_handover.name})"
        else
          ''
        end
      }
      TED Tariff end date:            #{display_date(offender.tariff_date)}
      THD Target hearing date:        #{display_date(offender.target_hearing_date)}
      PED Parole eligibility date:    #{display_date(offender.parole_eligibility_date)}
      CRD Conditional release date:   #{display_date(offender.conditional_release_date)}
      ARD Automatic release date:     #{display_date(offender.automatic_release_date)}

      #{display_title 'Responsibility/Handover'}
      #{debug_handover_history offender}

      #{display_title "Parole Reviews (#{parole_reviews.count})"}
      #{
        display_table(
          headings: ['Id', 'Updated', 'Status', 'Outcome', 'THD', 'Current?', 'Most Recent?', 'MR Completed?'],
          rows: parole_reviews.map do |parole_review|
            [
              parole_review.id,
              display_date_time(parole_review.updated_at),
              parole_review.review_status,
              parole_review.hearing_outcome,
              display_date(parole_review.target_hearing_date),
              display_tick_cross(parole_review.id == offender.current_parole_review&.id),
              display_tick_cross(parole_review.id == offender.most_recent_parole_review&.id),
              display_tick_cross(parole_review.id == offender.most_recent_completed_parole_review_for_sentence&.id),
            ]
          end
        )
      }

      #{display_title "Sentences (#{sentences.count})"}
      Single sentence?               #{display_tick_cross(offender.sentences.single_sentence?)}
      Conc. sentences <=12 months?   #{display_tick_cross(offender.sentences.concurrent_sentence_of_12_months_or_under?)}
      Conc. sentences >=20 months?   #{display_tick_cross(offender.sentences.concurrent_sentence_of_20_months_or_over?)}

      #{
        display_table(
          headings: ['ISP/SD', 'Sentence Start Date', 'Duration'],
          rows: sentences.map do |sentence|
            [
              sentence.indeterminate? ? 'ISP' : 'SD',
              display_date(sentence.sentence_start_date),
              sentence.duration > 0.days ? sentence.duration.inspect : ''
            ]
          end
        )
      }

    TXT
  end

  def debug_handover_history(offender)
    handover_row = lambda do |handover, version|
      [
        display_date_time(handover.updated_at),
        handover.responsibility,
        handover.reason,
        display_date(handover.start_date),
        display_date(handover.handover_date),

        if (erd = version.offender_attributes_to_archive['earliest_release_for_handover'])
          "(#{erd['name']}) #{display_date(erd['date'])}"
        elsif (erd = version.offender_attributes_to_archive['earliest_release'])
          "(#{erd['type']}) #{display_date(erd['date'])} *"
        elsif (erd = version.offender_attributes_to_archive['earliest_release_date'])
          "#{display_date(erd)} **"
        end,

        version.offender_attributes_to_archive['mappa_level'],
        display_tick_cross(version.offender_attributes_to_archive['recalled?']),
        display_tick_cross(version.offender_attributes_to_archive['indeterminate_sentence?'])
      ]
    end

    persisted_handover = CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)

    display_table(
      headings: ['Updated', 'Responsibility', 'Reason', 'Start', 'Handover', 'ERD', 'Mappa', 'Recall', 'ISP'],
      rows: persisted_handover.versions.reverse.map do |version|
        handover = CalculatedHandoverDate.new(
          YAML.load(version.object, permitted_classes: [Date, Time], aliases: true)
        )
        handover_row[handover, version]
      end
    )
  end
end
