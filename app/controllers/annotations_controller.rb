# All modifications to the annotations are meant to be asynchronous and 
# thus this contorller only exposes javascript interfaces.
#
# Only people acting as instructors or CA's should be able to do anything
# but view the annotations and since all of these mutate them, they are
# all restricted to those types.
class AnnotationsController < ApplicationController
  
  before_action :set_assessment
  before_action :set_submission
  before_action :set_annotation, except: [:create]
  
  respond_to :json

  # POST /:course/annotations.json
  action_auth_level :create, :course_assistant
  def create
    annotation = @submission.annotations.new(annotation_params)
    annotation.save
    respond_with(@course, @assessment, @submission, annotation)
  end

  # PUT /:course/annotations/1.json
  action_auth_level :update, :course_assistant
  def update
    @annotation.update(annotation_params)
    respond_with(@course, @assessment, @submission, @annotation) do |format|
      format.json{render json: @annotation}
    end
  end

  # DELETE /:course/annotations/1.json
  action_auth_level :destroy, :course_assistant
  def destroy
    @annotation.destroy
    respond_with(@course, @assessment, @submission, @annotation)
  end

  private

    def annotation_params
      params[:annotation].delete(:id)
      params[:annotation].delete(:submission_id)
      params[:annotation].delete(:created_at)
      params[:annotation].delete(:updated_at)
      params.require(:annotation).permit(:filename, :position, :line, :text, :submitted_by, :comment, :value, :problem_id)
    end

    def set_submission
      @submission = @assessment.submissions.find(params[:submission_id])
    
      unless (@cud.instructor or @cud.course_assistant or @submission.course_user_datum_id == @cud.id) then
        flash[:error] = "You do not have permission to access this submission."
        redirect_to controller: :home, action: :error and return false
      end

      if (@assessment.exam? or @course.exam_in_progress?) and not (@cud.instructor or @cud.course_assistant) then
        flash[:error] = "You cannot view this submission.
                Either an exam is in progress or this is an exam submission."
        redirect_to controller: :home, action: :error and return false
      end
      return true
    end

    def set_annotation
      @annotation = @submission.annotations.find(params[:id])
    end
end
