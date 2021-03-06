class InterviewDaysController < ApplicationController

  def index
    @interview_day = InterviewDay.all.includes(:interviews).order('interviews.start_time ASC')
  end

  def show
    @interview_day = InterviewDay.where(id: params[:id]).includes(:interviews).order('interviews.start_time ASC').first
  end

  def update
    return respond_access_denied unless admin? || apprentice?
    @interview = Interview.find(params[:interview_id])
    @applicant = Applicant.find(params[:applicant_id])
    Applicant.transaction do
      Interview.transaction do
        InterviewDay.transaction do
          if admin? || apprentice?
            if params[:mark_as_arrived]
              @applicant.arrived = true
              @applicant.arrival_time = Time.now
              if params[:applicant][:arrival_time]
                begin
                  time = params[:applicant][:arrival_time]
                  @applicant.arrival_time = DateTime.parse(time)
                rescue
                end
              end
            elsif params[:mark_as_not_arrived]
              @applicant.arrived = false
              @applicant.arrival_time = nil
            end
            @applicant.desk = params[:applicant][:desk]
            @applicant.save! if @applicant
            @interview.save! if @interview
          end
        end
      end
    end
    respond_to do |format|
      format.html do
        redirect_to @interview_day
      end
      format.js do
        render :partial => 'interview_days/applicant_details', :locals => { :applicant => @applicant, interview: @interview }
      end
    end
  end
end
