# frozen_string_literal: true

class VictimLiaisonOfficersController < PrisonsApplicationController
  before_action :load_offender
  before_action :find_vlo, only: [:edit, :update, :destroy, :delete]
  before_action :store_referrer_in_session, only: [:new, :edit, :delete]

  def new
    @vlo = @offender.victim_liaison_officers.new
  end

  def create
    @vlo = @offender.victim_liaison_officers.new vlo_parameters

    if @vlo.save
      audit(success: true)
      redirect_to referrer, notice: 'VLO contact added'
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @vlo.update vlo_parameters
      audit(success: true)
      redirect_to referrer, notice: 'VLO contact updated'
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def delete; end

  def destroy
    if params[:delete_confirm] == 'yes'
      @vlo.destroy!
      audit(success: true)
      flash[:notice] = 'VLO contact removed'
    else
      audit(failure: HmppsAuditing::USER_CANCELLED)
    end

    redirect_to referrer
  end

private

  def entity_for_audit = @vlo

  def find_vlo
    @vlo = VictimLiaisonOfficer.find params[:id]
  end

  def vlo_parameters
    params.require(:victim_liaison_officer).permit(:first_name, :last_name, :email)
  end

  def load_offender
    @offender = get_offender_or_404(params[:prisoner_id])
  end
end
